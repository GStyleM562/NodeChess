extends SceneTree
## Verify Plan B: energy gain, buff-node bonus, and modifier activation.

func _initialize() -> void:
	var gs := GameState.new(MapData.new())
	var bnode: int = gs.map.buffs[0]

	# energy: +1 to whichever team starts its turn
	gs.end_turn()
	gs.end_turn()
	print("energy_p/e=", gs.energy["player"], "/", gs.energy["enemy"])      # 1/1

	# buff-node control -> +1 extra energy
	var u := gs.add_to_bench("player", 0)
	gs.units[u]["node"] = bnode
	gs.board[bnode] = u
	print("controls_buff=", gs.controls_buff("player"))                     # true
	gs.energy["player"] = 0
	gs._grant_energy("player")
	print("buff_grant=", gs.energy["player"])                              # 2

	# combat boost helper
	var w := {"col": "white", "pow": 80}
	gs._boost_seg(w, 20, 1)
	var p := {"col": "purple", "stars": 1}
	gs._boost_seg(p, 20, 1)
	var b := {"col": "blue"}
	gs._boost_seg(b, 20, 1)
	print("boost_white=", w["pow"], " purple_stars=", p["stars"], " blue_pow=", b.has("pow"))  # 100 2 false

	# modifiers
	gs.energy["player"] = 5
	print("can_surge=", gs.can_use_modifier("player", "power_surge"))       # true
	var ok := gs.activate_modifier("player", "power_surge")
	print("act_surge=", ok, " energy=", gs.energy["player"], " surge=", gs.pending_buff["player"].get("surge", false))  # true 2 true
	gs.energy["player"] = 1
	print("cant_surge_lowE=", gs.can_use_modifier("player", "power_surge")) # false

	# cleanse removes debuffs
	var u2 := gs.add_to_bench("player", 1)
	gs.units[u2]["node"] = 3
	gs.board[3] = u2
	gs.apply_status(u2, "fear")
	gs.energy["player"] = 3
	gs.activate_modifier("player", "cleanse")
	print("cleansed=", not gs.has_status(u2, "fear"))                       # true

	# surge consumed by the next attack
	var d := gs.add_to_bench("enemy", 2)
	gs.units[d]["node"] = 5
	gs.board[5] = d
	gs.energy["player"] = 5
	gs.activate_modifier("player", "power_surge")
	gs.attack(u, d)
	print("surge_consumed=", not bool(gs.pending_buff["player"].get("surge", false)))  # true
	print("PLANB_OK")
	quit()
