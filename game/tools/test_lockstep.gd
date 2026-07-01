extends SceneTree
## Online lockstep: the acting client rolls; the other re-applies the SAME roll
## indices via attack(..., fidx_a, fidx_b) -> identical resulting state on both.
## (uid 0 = Ironclad at node 4, uid 1 = Stone Golem at node 6; they are adjacent.)

func _initialize() -> void:
	var ok := true
	var A := GameState.new(MapData.new())
	var B := GameState.new(MapData.new())
	for gs in [A, B]:
		gs.add_to_bench("player", 1)   # uid 0 — Ironclad Knight
		gs.add_to_bench("enemy", 0)    # uid 1 — Stone Golem

	for i in 200:
		for gs in [A, B]:
			_reset(gs)
		var recA := A.attack(0, 1)
		var recB := B.attack(0, 1, 0, int(recA["idx_a"]), int(recA["idx_b"]))
		if int(recA["result"]) != int(recB["result"]) or int(recA.get("ko", -1)) != int(recB.get("ko", -1)):
			print("  rec mismatch at i=%d (A=%d B=%d)" % [i, int(recA["result"]), int(recB["result"])])
			ok = false
			break
		if not _same(A, B):
			print("  state desync at i=%d" % i)
			ok = false
			break
	print("LOCKSTEP_OK" if ok else "LOCKSTEP_FAIL")
	quit()

func _reset(gs: GameState) -> void:
	for uid in [0, 1]:
		gs.units[uid]["alive"] = true
		gs.units[uid]["rank"] = 0
		gs.units[uid]["statuses"] = {}
	gs.units[0]["node"] = 4
	gs.units[1]["node"] = 6
	gs.board.clear()
	gs.board[4] = 0
	gs.board[6] = 1
	gs.ko_bench["player"].clear()
	gs.ko_bench["enemy"].clear()

func _same(A: GameState, B: GameState) -> bool:
	for uid in [0, 1]:
		if A.units[uid]["alive"] != B.units[uid]["alive"]:
			return false
		if int(A.units[uid]["node"]) != int(B.units[uid]["node"]):
			return false
		if int(A.units[uid].get("rank", 0)) != int(B.units[uid].get("rank", 0)):
			return false
		if A.units[uid]["statuses"].keys().size() != B.units[uid]["statuses"].keys().size():
			return false
	return A.board == B.board
