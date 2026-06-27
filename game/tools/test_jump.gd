extends SceneTree
## Verify the "jump over an adjacent enemy" rule (>= 2 stamina, costs 2).
## Board: n3 neighbours are n0, n8, n9; n8 neighbours include n11 (the landing).

func _initialize() -> void:
	var gs := GameState.new(MapData.new())
	var u := gs.add_to_bench("player", 2)   # Nightblade, stamina 3
	var e := gs.add_to_bench("enemy", 0)    # Golem (the one we hop over)
	gs.units[u]["node"] = 3; gs.board[3] = u
	gs.units[e]["node"] = 8; gs.board[8] = e
	print("n8_adjacent_n3=", 8 in gs.map.adj[3])
	print("n11_adjacent_n8=", 11 in gs.map.adj[8])

	var mt := gs.move_targets(u, 3)
	print("jump_to_11_cost=", mt.get(11, -1))       # expect 2
	print("path_to_11=", gs.move_path(u, 11))       # expect [8, 11]  (over the enemy)

	var mt1 := gs.move_targets(u, 1)
	print("budget1_can_jump=", mt1.has(11))         # expect false (needs >= 2)

	# A stamina-1 figure (Golem) cannot jump even on its own turn.
	var gs2 := GameState.new(MapData.new())
	var g := gs2.add_to_bench("player", 0)          # Golem, stamina 1
	var e2 := gs2.add_to_bench("enemy", 2)
	gs2.units[g]["node"] = 3; gs2.board[3] = g
	gs2.units[e2]["node"] = 8; gs2.board[8] = e2
	var gmt := gs2.move_targets(g, int(gs2.units[g]["stamina"]))
	print("golem_can_jump=", gmt.has(11))           # expect false

	# A jump cannot land ON a goal node (blocker in front of a goal defends it).
	var g4 := GameState.new(MapData.new())          # Rieles: goal_enemy = 19, adj[17] = [19,14]
	var u4 := g4.add_to_bench("player", 5)
	var e4 := g4.add_to_bench("enemy", 2)
	g4.units[u4]["node"] = 14; g4.board[14] = u4
	g4.units[e4]["node"] = 17; g4.board[17] = e4
	print("n17_adj_n14=", 17 in g4.map.adj[14], " goal19_adj_n17=", 19 in g4.map.adj[17])
	print("jump_onto_goal_blocked=", not g4.move_targets(u4, 2).has(19))   # expect true
	print("JUMP_OK")
	quit()
