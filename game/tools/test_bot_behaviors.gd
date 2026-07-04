extends SceneTree
## IA CPU (docs/AI_CPU.md): portero en la propia meta, banca siempre vacía
## (despliega todo), el portero no abandona su puesto, y el juego completo
## bot-vs-bot sigue corriendo limpio con las nuevas prioridades.

func _initialize() -> void:
	var ok := true
	var gs := GameState.new(MapData.new())
	gs.bot_difficulty = 2
	for ri in [0, 1, 2, 3, 4]:
		gs.add_to_bench("enemy", ri)
	# un jugador pasivo presente (lejos, en su lado) para que haya partida
	var pl := gs.add_to_bench("player", 0)
	gs.bench["player"].erase(pl)
	gs.units[pl]["node"] = gs.map.entrances_player[0]
	gs.board[gs.map.entrances_player[0]] = pl

	# 1) primera acción: siembra guardia desde la banca (meta propia vacía)
	var a1 := gs.bot_action("enemy")
	ok = _expect("acción 1 = deploy (guardia)", String(a1["type"]), "deploy") and ok

	# 2) en pocas acciones la meta propia queda OCUPADA por su portero
	var guarded_at := -1
	for i in 6:
		gs.turn_no += 1
		gs.bot_action("enemy")
		var occ: int = gs.board.get(gs.map.goal_enemy, -1)
		if occ != -1 and String(gs.units[occ]["team"]) == "enemy":
			guarded_at = i
			break
	ok = _expect("portero sentado en su meta", guarded_at >= 0, true) and ok

	# 3) despliega TODO mientras no gane antes: la banca se vacía (o GANA, que
	# es la prioridad 1 y va primero — también válido).
	for i in 14:
		if not gs.bench["enemy"].is_empty() and gs.winner == "":
			gs.turn_no += 1
			gs.bot_action("enemy")
	ok = _expect("banca vacía o victoria", gs.bench["enemy"].is_empty() or gs.winner == "enemy", true) and ok

	# 4) el portero NO abandonó la meta mientras duró la partida
	var occ2: int = gs.board.get(gs.map.goal_enemy, -1)
	ok = _expect("el portero sigue en su meta", occ2 != -1 and String(gs.units[occ2]["team"]) == "enemy", true) and ok

	# 5) partida completa bot-vs-bot: corre limpia y el tablero queda CONSISTENTE
	# tras CADA acción (sin fichas apiladas ni ocupaciones fantasma).
	var g2 := GameState.new(MapData.new())
	g2.bot_difficulty = 2
	for ri in [0, 1, 2, 3, 4]:
		g2.add_to_bench("player", ri)
		g2.add_to_bench("enemy", ri)
	var guard := 0
	var consistent := true
	while g2.winner == "" and guard < 400:
		guard += 1
		g2.bot_action(g2.turn_team)
		g2.check_surround()
		if not g2.board_consistent():
			consistent = false
			break
		g2.turn_team = "enemy" if g2.turn_team == "player" else "player"
		g2.turn_no += 1
		g2._process_ko_returns()
	ok = _expect("bot-vs-bot corre sin colgarse", guard <= 400, true) and ok
	ok = _expect("tablero consistente SIEMPRE (sin stacks)", consistent, true) and ok
	print("  (bot-vs-bot: winner='%s' acciones=%d)" % [g2.winner, guard])

	print("BOT_AI_OK" if ok else "BOT_AI_FAIL")
	quit()

func _expect(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print(("  %-36s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
