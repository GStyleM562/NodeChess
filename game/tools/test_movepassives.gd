extends SceneTree
## Verify movement passives that live in GameState: Lunge, Dive, Hexstep.
## (Blink + Bloodthirst are board-side; declared in roster, checked via has_passive.)

func _initialize() -> void:
	# declarations
	var gd := GameState.new(MapData.new())
	var nb := gd.add_to_bench("player", 2)
	var vk := gd.add_to_bench("player", 5)
	var rm := gd.add_to_bench("player", 3)
	print("nightblade_lunge=", gd.has_passive(nb, "lunge"), " bloodthirst=", gd.has_passive(nb, "bloodthirst"))
	print("valkyrie_dive=", gd.has_passive(vk, "dive"))
	print("mage_blink=", gd.has_passive(rm, "blink"))

	# LUNGE — moving 2+ before attacking rerolls a Miss (Nightblade red ~1%).
	var g := GameState.new(MapData.new())
	var a := g.add_to_bench("player", 2)   # nightblade
	var d := g.add_to_bench("enemy", 0)
	var r0 := 0
	var r2 := 0
	for i in 3000:
		_reset(g, a, d, 0, 5)
		if String(g.attack(a, d, 0)["seg_a"]["col"]) == "red":
			r0 += 1
	for i in 3000:
		_reset(g, a, d, 0, 5)
		if String(g.attack(a, d, 2)["seg_a"]["col"]) == "red":
			r2 += 1
	print("lunge reds moved0=", r0, " moved2=", r2)
	print("lunge_ok=", r2 < r0 and r2 <= 5)

	# DIVE — Valkyrie that flew 3+ nodes pushes 2 instead of 1.
	var g2 := GameState.new(MapData.new())
	var v := g2.add_to_bench("player", 5)  # valkyrie
	var e := g2.add_to_bench("enemy", 2)   # nightblade (not displacement-immune)
	g2.units[v]["node"] = 1; g2.board[1] = v
	g2.units[e]["node"] = 4; g2.board[4] = e
	g2._att_moved_ctx = 0
	g2._apply_displacement(v, e, {"disp": "push", "n": 1})
	var land1: int = g2.units[e]["node"]
	g2.board.erase(land1); g2.units[e]["node"] = 4; g2.board[4] = e
	g2._att_moved_ctx = 3
	g2._apply_displacement(v, e, {"disp": "push", "n": 1})
	var land2: int = g2.units[e]["node"]
	print("dive land1(push1)=", land1, " land2(push2)=", land2)
	print("dive_ok=", land1 != land2)

	# HEXSTEP — Witch defender retreats (push) on a tie.
	var g3 := GameState.new(MapData.new())
	var wa := g3.add_to_bench("player", 0)
	var ww := g3.add_to_bench("enemy", 4)  # witch (hexstep)
	var ties := 0
	var hexok := true
	for i in 3000:
		_reset(g3, wa, ww, 0, 5)
		var r: Dictionary = g3.attack(wa, ww)
		if int(r["result"]) == 0:
			ties += 1
			var dt := String((r["disp"] as Dictionary).get("type", ""))
			if dt != "push" and dt != "immune":
				hexok = false
	print("hexstep ties=", ties, " ok=", hexok and ties > 0)
	print("MOVEPASS_OK")
	quit()

func _reset(g: GameState, a: int, d: int, na: int, nd: int) -> void:
	g.ko_bench["player"].clear()
	g.ko_bench["enemy"].clear()
	g.units[a]["alive"] = true
	g.units[d]["alive"] = true
	g.units[a]["statuses"] = {}
	g.units[d]["statuses"] = {}
	g.units[a]["node"] = na
	g.units[d]["node"] = nd
	g.board.clear()
	g.board[na] = a
	g.board[nd] = d
