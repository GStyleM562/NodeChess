extends SceneTree
## SALTO: hop sobre UN rival adyacente (>= 2 estamina, cuesta 2, termina el turno).
## Duel map adj: 3=[0,8,9]  8=[3,4,22]. Salto: player@3 sobre enemigo@8 aterriza
## en 4 (vecino de 8, libre); rodear 4 son 3 pasos, así que el salto (2) gana.
## AHORA con aserciones reales (antes solo imprimía y nunca fallaba).

func _initialize() -> void:
	var ok := true
	var gs := GameState.new(MapData.new(0))
	var u := gs.add_to_bench("player", 2)   # Nightblade, stamina 3
	var e := gs.add_to_bench("enemy", 0)    # Golem (sobre el que saltamos)
	gs.units[u]["node"] = 3; gs.board[3] = u
	gs.units[e]["node"] = 8; gs.board[8] = e

	# adyacencia asumida por el caso (si el mapa cambia, esto AVISA)
	ok = _expect("8 es vecino de 3", 8 in gs.map.adj[3], true) and ok
	ok = _expect("4 es vecino de 8 (aterrizaje)", 4 in gs.map.adj[8], true) and ok

	# --- salto válido: aterrizar en 4 cuesta 2 y la ruta pasa SOBRE el rival ---
	var mt := gs.move_targets(u, 3)
	ok = _expect("salto a 4 cuesta 2", int(mt.get(4, -1)), 2) and ok
	var path := gs.move_path(u, 4)
	ok = _expect("ruta = [8, 4] (sobre el enemigo)", path, [8, 4]) and ok
	# is_jump del tablero: el primer nodo de la ruta está OCUPADO (rival)
	ok = _expect("primer nodo de la ruta ocupado (=salto)", gs.board.has(int(path[0])) if not path.is_empty() else false, true) and ok

	# --- con 1 de estamina NO se puede saltar (necesita >= 2) ---
	var mt1 := gs.move_targets(u, 1)
	ok = _expect("estamina 1: sin salto a 4", mt1.has(4), false) and ok

	# --- una figura de estamina 1 (Golem) no salta ni en su turno ---
	var gs2 := GameState.new(MapData.new(0))
	var g := gs2.add_to_bench("player", 0)          # Golem, stamina 1
	var e2 := gs2.add_to_bench("enemy", 2)
	gs2.units[g]["node"] = 3; gs2.board[3] = g
	gs2.units[e2]["node"] = 8; gs2.board[8] = e2
	var gmt := gs2.move_targets(g, int(gs2.units[g]["stamina"]))
	ok = _expect("Golem (estamina 1) no salta", gmt.has(4), false) and ok

	# --- NO se camina a través de una figura: sin salto disponible, la ruta a un
	# nodo tras el rival RODEA (no incluye el nodo ocupado) ---
	var gs3 := GameState.new(MapData.new(0))
	var u3 := gs3.add_to_bench("player", 0)         # Golem estamina 1 (no puede saltar)
	var e3 := gs3.add_to_bench("enemy", 2)
	gs3.units[u3]["node"] = 3; gs3.board[3] = u3
	gs3.units[e3]["node"] = 8; gs3.board[8] = e3
	var p3 := gs3.move_path(u3, 4)
	ok = _expect("sin salto: la ruta NO atraviesa al rival (8)", 8 in p3, false) and ok

	# --- un salto SÍ puede aterrizar en la meta (bloquear delante no la defiende) ---
	# Rieles adj: 14=[12,17,10], 17=[19,14], meta_enemy=19
	var g4 := GameState.new(MapData.new(0))
	var u4 := g4.add_to_bench("player", 5)
	var e4 := g4.add_to_bench("enemy", 2)
	g4.units[u4]["node"] = 14; g4.board[14] = u4
	g4.units[e4]["node"] = 17; g4.board[17] = e4
	ok = _expect("salto a la meta permitido", g4.move_targets(u4, 2).has(19), true) and ok

	print("JUMP_OK" if ok else "JUMP_FAIL")
	quit()

func _expect(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print(("  %-42s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
