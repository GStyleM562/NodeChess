extends SceneTree
## Movement passives: PARKOUR (move-then-jump gating) and PHASE (pass-through).
## Board layout (mapa Rieles): riel 4 — 6 — 20 — 12, con el 20 CANDADO hasta la
## ronda 3 (turn_no 6). Salto: 4 → (sobre el rival en 6) → aterriza en 20.

func _add(id: String, passives: Array, stamina: int) -> int:
	Roster.FIGURES.append({
		"id": id, "name": id, "stamina": stamina, "type": "Ruleta",
		"passives": passives, "attack": [{"col": "red", "w": 1}],
	})
	return Roster.FIGURES.size() - 1

func _initialize() -> void:
	var ok := true
	var norm := _add("t_norm", [], 3)
	var park := _add("t_park", ["parkour"], 3)
	var phase := _add("t_phase", ["phase"], 3)
	var foe := _add("t_foe", [], 2)
	var gs := GameState.new(MapData.new())   # mapa Rieles (riel 4-6-20-12)
	gs.turn_no = 6                           # ronda 3: el candado del 20 ya abrió

	# NORMAL: basic jump allowed as a FIRST action (budget == stamina)...
	var a := gs.add_to_bench("player", norm)
	var en := gs.add_to_bench("enemy", foe)
	_place(gs, a, 4)
	_place(gs, en, 6)
	ok = _expect("norm: basic jump (first action)", gs.move_targets(a, 3).has(20), true) and ok
	# ...but NOT after moving (budget < stamina) without parkour.
	ok = _expect("norm: no move-then-jump", gs.move_targets(a, 2).has(20), false) and ok

	# PARKOUR: may jump AFTER moving (budget 2).
	gs.board.clear()
	var p := gs.add_to_bench("player", park)
	_place(gs, p, 4)
	_place(gs, en, 6)
	ok = _expect("parkour: move-then-jump", gs.move_targets(p, 2).has(20), true) and ok

	# PHASE: walks THROUGH the occupant (6) to node 12; cannot LAND on occupied 6.
	gs.board.clear()
	var ph := gs.add_to_bench("player", phase)
	_place(gs, ph, 4)
	_place(gs, en, 6)
	var rp := gs.move_targets(ph, 3)
	ok = _expect("phase: passes through to 12", rp.has(12), true) and ok
	ok = _expect("phase: cannot land on occupied 6", rp.has(6), false) and ok
	# el candado CERRADO (turno 0) sí bloquea el aterrizaje del salto
	gs.turn_no = 0
	ok = _expect("candado cerrado: sin salto", gs.move_targets(a, 3).has(20), false) and ok

	print("PARKOUR_OK" if ok else "PARKOUR_FAIL")
	quit()

func _place(gs: GameState, uid: int, node: int) -> void:
	gs.bench[gs.units[uid]["team"]].erase(uid)
	gs.units[uid]["node"] = node
	gs.board[node] = uid

func _expect(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print(("  %-34s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
