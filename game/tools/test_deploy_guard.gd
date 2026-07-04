extends SceneTree
## Regresión del bug reportado: re-desplegar una figura ya en el tablero la
## "duplicaba" (dejaba una ocupación fantasma en su nodo viejo que después
## bloqueaba movimientos sin razón). Ahora deploy() SOLO acepta banca + nodo libre.

func _initialize() -> void:
	var ok := true
	var gs := GameState.new(MapData.new())
	var a := gs.add_to_bench("player", 0)
	var b := gs.add_to_bench("player", 1)
	var ents: Array = gs.free_entrances("player")
	ok = _expect("2+ entradas libres", ents.size() >= 2, true) and ok
	var e1: int = ents[0]
	var e2: int = ents[1]

	# despliegue normal
	gs.deploy(a, e1)
	ok = _expect("A desplegada en e1", int(gs.board.get(e1, -1)), a) and ok
	ok = _expect("A fuera de la banca", a in gs.bench["player"], false) and ok

	# EL BUG: re-desplegar A (ya en tablero) hacia e2 -> debe RECHAZARSE
	gs.deploy(a, e2)
	ok = _expect("re-deploy rechazado (e2 libre)", gs.board.has(e2), false) and ok
	ok = _expect("A sigue en e1", int(gs.units[a]["node"]), e1) and ok
	var refs := 0
	for nid in gs.board.keys():
		if int(gs.board[nid]) == a:
			refs += 1
	ok = _expect("sin ocupación fantasma (1 ref)", refs, 1) and ok

	# desplegar B sobre nodo OCUPADO -> rechazado; sobre libre -> ok
	gs.deploy(b, e1)
	ok = _expect("deploy a nodo ocupado rechazado", b in gs.bench["player"], true) and ok
	gs.deploy(b, e2)
	ok = _expect("B desplegada en e2", int(gs.board.get(e2, -1)), b) and ok

	# y las figuras en entradas SÍ pueden moverse (sin debuffs no hay bloqueo)
	ok = _expect("A puede moverse desde la entrada", gs.move_targets(a, gs.effective_stamina(a)).size() > 0, true) and ok
	ok = _expect("B puede moverse desde la entrada", gs.move_targets(b, gs.effective_stamina(b)).size() > 0, true) and ok

	# ANTI-STACK: mover sobre un nodo ocupado se RECHAZA (jamás dos en un nodo)
	ok = _expect("move a nodo ocupado rechazado", gs.move_unit(a, e2), false) and ok
	ok = _expect("A no se movió", int(gs.units[a]["node"]), e1) and ok
	ok = _expect("B sigue dueño de e2", int(gs.board.get(e2, -1)), b) and ok
	ok = _expect("tablero consistente", gs.board_consistent(), true) and ok

	print("DEPLOY_GUARD_OK" if ok else "DEPLOY_GUARD_FAIL")
	quit()

func _expect(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print(("  %-36s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
