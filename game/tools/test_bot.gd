extends SceneTree
## Verify the Hard bot: win-probability math + a full bot-vs-bot game runs cleanly.

func _initialize() -> void:
	var gs0 := GameState.new(MapData.new())
	var night: Array = Roster.FIGURES[2]["attack"]      # Nightblade (strong coin)
	var allred: Array = [{"col": "red", "w": 1.0}]
	print("wp_night_vs_red=", snapped(gs0._win_prob(night, allred), 0.01))   # expect ~1
	print("wp_red_vs_night=", snapped(gs0._win_prob(allred, night), 0.01))   # expect ~0
	print("ko_night_vs_red=", snapped(gs0._ko_prob(night, allred), 0.01))    # ~0.5 (half is white)

	var gs := GameState.new(MapData.new())
	for ri in [0, 1, 2, 3, 4]:
		gs.add_to_bench("player", ri)
	for ri in [0, 1, 2, 3, 4]:
		gs.add_to_bench("enemy", ri)
	var guard := 0
	while gs.winner == "" and guard < 400:
		guard += 1
		gs.bot_action(gs.turn_team)
		gs.check_surround()
		gs.turn_team = "enemy" if gs.turn_team == "player" else "player"
		gs.turn_no += 1
		gs._process_ko_returns()
	print("BOT_GAME winner='", gs.winner, "' actions=", guard)
	print("BOT_OK")
	quit()
