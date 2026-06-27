extends SceneTree
## Verify attack() returns the rolled face index, and that a buff is baked into seg.

func _initialize() -> void:
	var gs := GameState.new(MapData.new())
	var a := gs.add_to_bench("player", 1)   # Ironclad (Dado, 6 faces)
	var d := gs.add_to_bench("enemy", 0)
	gs.units[a]["node"] = 0; gs.board[0] = a
	gs.units[d]["node"] = 5; gs.board[5] = d

	var rec := gs.attack(a, d)
	var ia := int(rec["idx_a"])
	print("idx_a=", ia, " idx_b=", rec["idx_b"], " in_range=", ia >= 0 and ia < gs.pool_for(a).size())

	var maxpow0 := 0
	for s in gs.pool_for(a):
		if s.has("pow"):
			maxpow0 = maxi(maxpow0, int(s["pow"]))
	var buffed := false
	for i in 300:
		gs.units[a]["alive"] = true; gs.units[d]["alive"] = true
		gs.units[a]["node"] = 0; gs.units[d]["node"] = 5
		gs.board.clear(); gs.board[0] = a; gs.board[5] = d
		gs.ko_bench["player"].clear(); gs.ko_bench["enemy"].clear()
		gs.pending_buff["player"]["surge"] = true
		var r := gs.attack(a, d)
		var sa: Dictionary = r["seg_a"]
		if sa.has("pow") and int(sa["pow"]) > maxpow0:
			buffed = true
			break
	print("surge_buffs_pow=", buffed, " base_max=", maxpow0)
	print("COMBAT2_OK")
	quit()
