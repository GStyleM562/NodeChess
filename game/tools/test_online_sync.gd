extends SceneTree
## Online sync: two mirrored GameStates (A=seat0, B=seat1) applying the SAME actions
## with the uid+node mirror stay board-isomorphic. Same deck both sides so one global
## roster suffices (positions are what matter). Invariant:
##   A.units[u].node == mirror_node(B.units[mirror_uid(u)].node)

var _base: Array

func _initialize() -> void:
	var ok := true
	_base = Roster.FIGURES
	var roster: Array = []
	for i in 5:
		roster.append(_base[i])         # deck0
	for i in 5:
		roster.append(_base[i])         # deck1 (same)
	Roster.FIGURES = roster
	var A := GameState.new(MapData.new(0))
	var B := GameState.new(MapData.new(0))
	for gs in [A, B]:
		for i in 5:
			gs.add_to_bench("player", i)
		for i in 5:
			gs.add_to_bench("enemy", 5 + i)
	B.turn_team = "enemy"
	var m := A.map

	# seat0 deploys uid 0 at a player entrance; B applies the mirror
	var e0 := int(A.free_entrances("player")[0])
	A.deploy(0, e0)
	B.deploy(_mu(0), m.mirror_node(e0))
	ok = _inv(A, B, m, "deploy0") and ok

	# seat0 moves uid 0
	var tg := A.move_targets(0, 2).keys()
	if not tg.is_empty():
		var n := int(tg[0])
		A.move_unit(0, n)
		B.move_unit(_mu(0), m.mirror_node(n))
		ok = _inv(A, B, m, "move0") and ok

	# seat1 deploys ITS uid 0 (on A that is enemy uid 5); A applies the mirror
	var e1 := int(B.free_entrances("player")[0])
	B.deploy(0, e1)
	A.deploy(_mu(0), m.mirror_node(e1))
	ok = _inv(A, B, m, "deploy1") and ok

	Roster.FIGURES = _base
	print("ONLINE_SYNC_OK" if ok else "ONLINE_SYNC_FAIL")
	quit()

func _mu(u: int) -> int:
	return (u + 5) if u < 5 else (u - 5)

func _inv(A: GameState, B: GameState, m: MapData, tag: String) -> bool:
	for u in A.units.keys():
		var an := int(A.units[u]["node"])
		var bn := int(B.units[_mu(u)]["node"])
		if an < 0 and bn < 0:
			continue
		if an < 0 or bn < 0 or m.mirror_node(bn) != an:
			print("  [%s] desync u=%d  A=%d  mirror(B)=%d" % [tag, u, an, (m.mirror_node(bn) if bn >= 0 else -1)])
			return false
	print("  %s OK" % tag)
	return true
