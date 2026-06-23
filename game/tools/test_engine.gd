extends SceneTree
## Headless engine test: combat resolver unit checks + a full bot-vs-bot game.
## Run: Godot --headless --path game --script res://tools/test_engine.gd

func _initialize() -> void:
	_test_resolver()
	_test_outcome()
	_test_effects()
	_test_surround()
	_test_game()
	quit()

func _test_surround() -> void:
	print("== surround KO + KO-bench return ==")
	var gs := GameState.new(MapData.new())
	# Pick a node and fill ALL its neighbours with enemies of the occupant.
	var center := 7   # centre-left lower node (degree 3) in the duel map
	var nbs: Array = gs.map.adj[center]
	var e := gs.add_to_bench("enemy", 0)
	gs.deploy(e, center)
	for nb in nbs:
		var pu := gs.add_to_bench("player", 0)
		gs.deploy(pu, nb)
	_expect_b("center is surrounded", gs.is_surrounded(e), true)
	var koed := gs.check_surround()
	_expect("surround KO'd exactly 1", koed.size(), 1)
	_expect_b("KO'd unit in enemy KO bench", gs.ko_bench["enemy"].has(e), true)
	gs.turn_no = GameState.KO_COOLDOWN + 5
	gs._process_ko_returns()
	_expect_b("returned to bench after cooldown", gs.bench["enemy"].has(e), true)

func _test_effects() -> void:
	print("== status effects ==")
	var gs := GameState.new(MapData.new())
	var u := gs.add_to_bench("player", 4)  # venom witch
	gs.apply_status(u, "fear")
	_expect_b("fear blocks attack", gs.can_attack(u), false)
	_expect_b("fear still allows move", gs.can_move(u), true)
	gs.apply_status(u, "immobilized")
	_expect_b("immobilized blocks move", gs.can_move(u), false)
	gs.turn_no = 9999
	_expect_b("status expires over time", gs.has_status(u, "fear"), false)

func _expect(name: String, got: int, want: int) -> void:
	print(("  OK   " if got == want else "  FAIL ") + name + "  got=%d want=%d" % [got, want])

func _expect_b(name: String, got: bool, want: bool) -> void:
	print(("  OK   " if got == want else "  FAIL ") + name + "  got=%s want=%s" % [got, want])

func _test_outcome() -> void:
	print("== outcome (a win is not always a KO) ==")
	var white := {"col": "white", "pow": 60}
	var gold := {"col": "gold", "pow": 40}
	var purple := {"col": "purple", "stars": 2, "fx": "Miedo"}
	var blue := {"col": "blue"}
	var red := {"col": "red"}
	_expect_b("white beats gold -> KO", bool(Combat.outcome(white, gold)["ko"]), true)
	_expect_b("purple beats white -> NO KO", bool(Combat.outcome(purple, white)["ko"]), false)
	_expect_b("blue beats white -> NO KO", bool(Combat.outcome(blue, white)["ko"]), false)
	_expect_b("white beats red -> KO", bool(Combat.outcome(white, red)["ko"]), true)
	_expect_b("blue vs blue tie -> no KO", bool(Combat.outcome(blue, blue)["ko"]), false)

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
	var gs := GameState.new(MapData.new())
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
