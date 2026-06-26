extends SceneTree
## Verify per-figure passives actually fire.
##   rindex: 0 Stone Golem, 1 Ironclad, 2 Nightblade, 3 Rift Mage, 4 Venom Witch

var gs: GameState
var n0 := 0
var n1 := 0

func _initialize() -> void:
	gs = GameState.new(MapData.new())
	n0 = 0
	n1 = gs.map.adj[0][0]

	# --- declarations
	var g := gs.add_to_bench("player", 0)   # golem
	var k := gs.add_to_bench("enemy", 1)    # ironclad
	print("golem_has_bedrock=", gs.has_passive(g, "bedrock"))
	print("ironclad_has_holdline=", gs.has_passive(k, "hold_the_line"))
	print("nightblade_has_bedrock=", gs.has_passive(gs.add_to_bench("player", 2), "bedrock"))

	# --- displacement immunity (Bedrock + Bulwark aura)
	_place(g, n0)
	_place(k, n1)
	var moved := gs._apply_displacement(k, g, {"disp": "push", "n": 1})   # try to push the golem
	print("bedrock_immune_type=", moved.get("type", ""))                  # expect 'immune'
	print("bedrock_stayed=", gs.units[g]["node"] == n0)                   # expect true

	# Bulwark: a non-bedrock unit beside an Ironclad ally becomes immune.
	var gs2 := GameState.new(MapData.new())
	var ally := gs2.add_to_bench("player", 1)   # ironclad (bulwark)
	var prot := gs2.add_to_bench("player", 2)   # nightblade (no bedrock)
	var enemy := gs2.add_to_bench("enemy", 0)
	gs2.units[ally]["node"] = gs2.map.adj[0][0]; gs2.board[gs2.map.adj[0][0]] = ally
	gs2.units[prot]["node"] = 0; gs2.board[0] = prot
	gs2.units[enemy]["node"] = -1
	print("bulwark_protects=", gs2._displacement_immune(prot))           # expect true

	# --- statistical: Hold the Line, Venom Hex, Counter-Stone
	print("holdline_ok=", _stat_holdline())
	print("venomhex_ok=", _stat_venomhex())
	print("counterstone_ok=", _stat_counterstone())
	print("PASS_OK")
	quit()

func _place(uid: int, node: int) -> void:
	gs.units[uid]["alive"] = true
	gs.units[uid]["statuses"] = {}
	gs.units[uid]["node"] = node
	gs.board[node] = uid

func _reset_pair(g: GameState, a: int, d: int) -> void:
	g.ko_bench["player"].clear()
	g.ko_bench["enemy"].clear()
	g.units[a]["alive"] = true
	g.units[d]["alive"] = true
	g.units[a]["statuses"] = {}
	g.units[d]["statuses"] = {}
	g.units[a]["node"] = n0
	g.units[d]["node"] = n1
	g.board.clear()
	g.board[n0] = a
	g.board[n1] = d

## Ironclad defends; every tie must Immobilize the attacker.
func _stat_holdline() -> bool:
	var g := GameState.new(MapData.new())
	var a := g.add_to_bench("player", 0)   # golem attacker
	var d := g.add_to_bench("enemy", 1)    # ironclad defender (hold_the_line)
	var ties := 0
	for i in 600:
		_reset_pair(g, a, d)
		var rec := g.attack(a, d)
		if int(rec["result"]) == 0:
			ties += 1
			if not g.has_status(a, "immobilized"):
				return false
	return ties > 0

## Venom Witch attacks; every Purple win must also Weaken the loser.
func _stat_venomhex() -> bool:
	var g := GameState.new(MapData.new())
	var a := g.add_to_bench("player", 4)   # venom witch (venom_hex)
	var d := g.add_to_bench("enemy", 2)    # nightblade
	var purples := 0
	for i in 600:
		_reset_pair(g, a, d)
		var rec := g.attack(a, d)
		if int(rec["result"]) > 0 and String(rec["win_col"]) == "purple":
			purples += 1
			if not g.has_status(d, "weakened"):
				return false
	return purples > 0

## Stone Golem defends; a Blue win must Push the attacker (Counter-Stone).
func _stat_counterstone() -> bool:
	var g := GameState.new(MapData.new())
	var a := g.add_to_bench("player", 2)   # nightblade attacker
	var d := g.add_to_bench("enemy", 0)    # golem defender (counter_stone)
	var blues := 0
	for i in 600:
		_reset_pair(g, a, d)
		var rec := g.attack(a, d)
		if int(rec["result"]) < 0 and String(rec["win_col"]) == "blue":
			blues += 1
			var dt := String((rec["disp"] as Dictionary).get("type", ""))
			if dt != "push" and dt != "immune":
				return false
	return blues > 0
