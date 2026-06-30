extends SceneTree
## Smoke test: the match board builds its bench as cards without runtime errors.

func _initialize() -> void:
	Loadout.player_team = [0, 1, 2]
	Loadout.enemy_team = [3, 4]
	Loadout.map_index = 0
	var b = load("res://scenes/board.tscn").instantiate()
	get_root().add_child(b)
	await process_frame
	await process_frame
	var n: int = (b._bench_cards as Array).size()
	var hit: int = b._bench_uid_at(Vector2(-999, -999))   # should be -1 (no card there)
	var ok: bool = n == 3 and hit == -1
	print("  bench cards = %d (want 3)" % n)
	print("  _bench_uid_at(off-screen) = %d (want -1)" % hit)
	print("BOARD_BENCH_OK" if ok else "BOARD_BENCH_FAIL")
	b.queue_free()
	quit()
