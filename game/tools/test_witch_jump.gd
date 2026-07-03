extends SceneTree
## Regresión: la Venom Witch (sin phase/aerial) JAMÁS atraviesa figuras.
## Su salto legal es por ENCIMA del rival y la ruta lo dice (empieza en el nodo
## del enemigo -> la animación hace el arco). Los caminos normales nunca pisan
## nodos ocupados.

func _initialize() -> void:
	var ok := true
	var vw := -1
	for i in Roster.FIGURES.size():
		if String(Roster.FIGURES[i].get("id", "")) == "venom_witch":
			vw = i
	ok = _expect("venom_witch en roster", vw >= 0, true) and ok

	var gs := GameState.new(MapData.new())
	var w := gs.add_to_bench("player", vw)
	var e := gs.add_to_bench("enemy", 0)

	# bruja en un nodo con enemigo adyacente y aterrizaje libre detrás
	var spot := _find_spot(gs)
	ok = _expect("escenario armado", spot.size(), 3) and ok
	gs.units[w]["node"] = spot[0]
	gs.board[spot[0]] = w
	gs.units[e]["node"] = spot[1]
	gs.board[spot[1]] = e
	gs.bench["player"].erase(w)
	gs.bench["enemy"].erase(e)

	# 1) la bruja NO tiene phase
	ok = _expect("bruja sin phase", gs._can_phase(w), false) and ok

	# 2) el nodo del enemigo NUNCA es destino
	var reach := gs.move_targets(w, gs.effective_stamina(w))
	ok = _expect("nodo enemigo no es destino", reach.has(spot[1]), false) and ok

	# 3) el aterrizaje del salto existe y cuesta 2
	ok = _expect("aterrizaje de salto (coste 2)", int(reach.get(spot[2], -1)), 2) and ok

	# 4) la ruta del salto EMPIEZA en el enemigo (la vista hace el ARCO, no atraviesa)
	var jp := gs.move_path(w, spot[2])
	ok = _expect("ruta = [enemigo, aterrizaje]", jp, [spot[1], spot[2]]) and ok

	# 5) ninguna ruta normal pisa nodos ocupados
	var clean := true
	for rid in reach.keys():
		var p := gs.move_path(w, rid)
		for i in p.size() - 1:      # todos menos el destino final
			if gs.board.has(int(p[i])) and int(reach.get(rid, 0)) != 2:
				clean = false
	ok = _expect("rutas normales sin nodos ocupados", clean, true) and ok

	# 6) TODAS las casillas libres adyacentes al enemigo son aterrizajes válidos
	var all_land := true
	for f in gs.map.adj[spot[1]]:
		if f == spot[0] or gs.board.has(f) or f in gs.map.obstacles:
			continue
		if not reach.has(f):
			all_land = false
	ok = _expect("todo vecino libre del rival aterriza", all_land, true) and ok

	# 7) con TODO alrededor del enemigo ocupado, el salto es IMPOSIBLE
	var blockers: Array = []
	for f in gs.map.adj[spot[1]]:
		if f == spot[0] or gs.board.has(f):
			continue
		var blk := gs.add_to_bench("player", 1)
		gs.bench["player"].erase(blk)
		gs.units[blk]["node"] = f
		gs.board[f] = blk
		blockers.append(f)
	var reach2 := gs.move_targets(w, gs.effective_stamina(w))
	var none := true
	for f in gs.map.adj[spot[1]]:
		if f != spot[0] and reach2.has(f):
			none = false
	ok = _expect("rival tapado: nadie lo salta", none, true) and ok

	print("WITCH_JUMP_OK" if ok else "WITCH_JUMP_FAIL")
	quit()

## [nodo_bruja, nodo_enemigo, aterrizaje]: tres en línea de grafo, extremos libres.
func _find_spot(gs: GameState) -> Array:
	for n in gs.map.nodes:
		var a := int(n["id"])
		if a in gs.map.obstacles or gs.map.role_of(a) != "normal":
			continue
		for b in gs.map.adj[a]:
			if b in gs.map.obstacles:
				continue
			for c in gs.map.adj[b]:
				if c != a and not (c in gs.map.obstacles):
					return [a, int(b), int(c)]
	return []

func _expect(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print(("  %-36s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
