extends SceneTree
## Smoke: the match board boots in ONLINE mode (roster swap + teams + seat turn) with
## the NetSession autoload live — also confirms Board3D compiles with `NetSession`.

func _initialize() -> void:
	var ok := true
	# Formato NUEVO del mazo: {"team": jugables, "lib": cierre de evoluciones}.
	# Las libs son ASIMÉTRICAS a propósito (2 vs 0): antes de la separación esto
	# desalineaba _half/uids/modelos entre clientes (el caos online reportado).
	var t0: Array = []
	var t1: Array = []
	for i in 5:
		t0.append(Roster.FIGURES[i])
		t1.append(Roster.FIGURES[i])
	var lib0: Array = [Roster.FIGURES[5], Roster.FIGURES[6]]
	var ns = get_root().get_node("NetSession")   # autoload global isn't visible in a --script MainLoop
	ns.online = true
	ns.seat = 1
	ns.map = 0
	ns.decks_by_seat = {0: {"team": t0, "lib": lib0}, 1: {"team": t1, "lib": []}}

	var b = load("res://scenes/board.tscn").instantiate()
	get_root().add_child(b)
	await process_frame
	await process_frame

	ok = _e("online flag", b._online, true) and ok
	ok = _e("seat = 1", b._seat, 1) and ok
	ok = _e("10 units built (libs NO son unidades)", b._gs.units.size(), 10) and ok
	ok = _e("_half = tamaño del EQUIPO (5)", b._half, 5) and ok
	ok = _e("seat1 waits (enemy turn)", b._gs.turn_team, "enemy") and ok
	ok = _e("wait banner exists", b._wait_banner != null, true) and ok
	ok = _e("roster = equipos + libs (12)", Roster.FIGURES.size(), 12) and ok
	# los uids de equipo apuntan a los EQUIPOS del roster (mirror alineado)
	ok = _e("uid 0 -> rindex 0", int(b._gs.units[0]["rindex"]), 0) and ok
	ok = _e("uid 5 -> rindex 5 (rival)", int(b._gs.units[5]["rindex"]), 5) and ok

	# restore global roster so we don't affect anything else
	Roster.FIGURES = b._saved_roster
	ns.online = false
	print("BOARD_ONLINE_OK" if ok else "BOARD_ONLINE_FAIL")
	quit()

func _e(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print("  %-26s got=%s want=%s  %s" % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
