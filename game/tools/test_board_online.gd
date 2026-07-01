extends SceneTree
## Smoke: the match board boots in ONLINE mode (roster swap + teams + seat turn) with
## the NetSession autoload live — also confirms Board3D compiles with `NetSession`.

func _initialize() -> void:
	var ok := true
	var d0: Array = []
	var d1: Array = []
	for i in 5:
		d0.append(Roster.FIGURES[i])
		d1.append(Roster.FIGURES[i])
	var ns = get_root().get_node("NetSession")   # autoload global isn't visible in a --script MainLoop
	ns.online = true
	ns.seat = 1
	ns.map = 0
	ns.decks_by_seat = {0: d0, 1: d1}

	var b = load("res://scenes/board.tscn").instantiate()
	get_root().add_child(b)
	await process_frame
	await process_frame

	ok = _e("online flag", b._online, true) and ok
	ok = _e("seat = 1", b._seat, 1) and ok
	ok = _e("10 units built", b._gs.units.size(), 10) and ok
	ok = _e("seat1 waits (enemy turn)", b._gs.turn_team, "enemy") and ok
	ok = _e("wait banner exists", b._wait_banner != null, true) and ok
	ok = _e("roster swapped (10)", Roster.FIGURES.size(), 10) and ok

	# restore global roster so we don't affect anything else
	Roster.FIGURES = b._saved_roster
	ns.online = false
	print("BOARD_ONLINE_OK" if ok else "BOARD_ONLINE_FAIL")
	quit()

func _e(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print("  %-26s got=%s want=%s  %s" % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
