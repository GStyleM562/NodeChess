extends SceneTree
## Headless engine test: combat resolver unit checks + a full bot-vs-bot game.
## Run: Godot --headless --path game --script res://tools/test_engine.gd

func _initialize() -> void:
	_test_resolver()
	_test_game()
	quit()

func _expect(name: String, got: int, want: int) -> void:
	print(("  OK   " if got == want else "  FAIL ") + name + "  got=%d want=%d" % [got, want])

func _test_resolver() -> void:
	print("== resolver ==")
	var white60 := {"col": "white", "pow": 60}
	var white80 := {"col": "white", "pow": 80}
	var gold40 := {"col": "gold", "pow": 40}
	var purple1 := {"col": "purple", "stars": 1}
	var purple2 := {"col": "purple", "stars": 2}
	var blue := {"col": "blue"}
	var red := {"col": "red"}
	_expect("blue beats white", Combat.resolve(blue, white80), 1)
	_expect("white beats gold", Combat.resolve(white60, gold40), 1)
	_expect("gold beats purple", Combat.resolve(gold40, purple1), 1)
	_expect("purple beats white", Combat.resolve(purple1, white80), 1)
	_expect("red loses to white", Combat.resolve(red, white60), -1)
	_expect("red vs red tie", Combat.resolve(red, red), 0)
	_expect("white higher pow wins", Combat.resolve(white80, white60), 1)
	_expect("white equal pow tie", Combat.resolve(white60, white60), 0)
	_expect("purple more stars wins", Combat.resolve(purple2, purple1), 1)
	_expect("blue vs blue tie", Combat.resolve(blue, blue), 0)

func _test_game() -> void:
	print("== bot vs bot game ==")
	var gs := GameState.new(MapData.new(5, 7, 1.35))
	for ri in [0, 1, 2]:
		gs.add_to_bench("player", ri)
	for ri in [3, 4, 1]:
		gs.add_to_bench("enemy", ri)
	var actions := 0
	var kos := 0
	while gs.winner == "" and actions < 400:
		if not gs.can_act(gs.turn_team):
			break
		var rec := gs.bot_action(gs.turn_team)
		actions += 1
		if rec.get("type") == "attack" and int(rec.get("ko", -1)) != -1:
			kos += 1
		gs.end_turn()
	print("  actions=%d  kos=%d  winner=%s" % [actions, kos, gs.winner])
	print("  player on board=%d bench=%d ko=%d" % [
		gs.units_on_board("player").size(), gs.bench["player"].size(), gs.ko_bench["player"].size()])
	print("  enemy  on board=%d bench=%d ko=%d" % [
		gs.units_on_board("enemy").size(), gs.bench["enemy"].size(), gs.ko_bench["enemy"].size()])
