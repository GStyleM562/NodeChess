extends SceneTree
## Audit of the 9 new status effects (Burn, Poison, Freeze, Silence, Confusion,
## Sleep, Curse, Marked, Shield Break) on top of the existing 4. Uses deterministic
## single-segment test figures appended to the Roster so rolls are predictable.

var W60 := -1
var BLU := -1
var PUR := -1
var RED := -1

func _add_fig(id: String, seg: Dictionary) -> int:
	Roster.FIGURES.append({
		"id": id, "name": id, "stamina": 2, "type": "Ruleta", "passives": [],
		"attack": [seg],
	})
	return Roster.FIGURES.size() - 1

func _initialize() -> void:
	var ok := true
	W60 = _add_fig("t_white", {"col": "white", "name": "Golpe", "pow": 60, "w": 1})
	BLU = _add_fig("t_blue", {"col": "blue", "name": "Muro", "w": 1})
	PUR = _add_fig("t_purple", {"col": "purple", "name": "Hechizo", "stars": 1, "w": 1})
	RED = _add_fig("t_red", {"col": "red", "name": "Fallo", "w": 1})

	var gs := GameState.new(MapData.new())

	print("=== A. GATING (move / attack) ===")
	var u := gs.add_to_bench("player", W60)
	ok = _expect("clean can_move", gs.can_move(u), true) and ok
	ok = _expect("clean can_attack", gs.can_attack(u), true) and ok
	gs.apply_status(u, "freeze")
	ok = _expect("freeze blocks move", gs.can_move(u), false) and ok
	ok = _expect("freeze blocks attack", gs.can_attack(u), false) and ok
	gs.units[u]["statuses"] = {}
	gs.apply_status(u, "sleep")
	ok = _expect("sleep blocks move", gs.can_move(u), false) and ok
	ok = _expect("sleep blocks attack", gs.can_attack(u), false) and ok
	gs.units[u]["statuses"] = {}
	gs.apply_status(u, "silence")
	ok = _expect("silence does NOT block move", gs.can_move(u), true) and ok
	ok = _expect("confusion does NOT block attack (set later)", gs.can_attack(u), true) and ok

	print("=== B. ROLL EFFECTS ===")
	# Burn: white 60 -> 50.
	var bu := gs.add_to_bench("player", W60)
	gs.apply_status(bu, "burn")
	ok = _expect("burn white 60 -> 50", int(gs._roll_full(bu, true)["seg"]["pow"]), 50) and ok
	# Freeze / Shield Break: blue collapses to red.
	var fb := gs.add_to_bench("player", BLU)
	gs.apply_status(fb, "freeze")
	ok = _expect("freeze blue -> red", String(gs._roll_full(fb, false)["seg"]["col"]), "red") and ok
	gs.units[fb]["statuses"] = {}
	gs.apply_status(fb, "shield_break")
	ok = _expect("shield_break blue -> red", String(gs._roll_full(fb, false)["seg"]["col"]), "red") and ok
	# Silence: purple fizzles to red.
	var su := gs.add_to_bench("player", PUR)
	gs.apply_status(su, "silence")
	ok = _expect("silence purple -> red", String(gs._roll_full(su, false)["seg"]["col"]), "red") and ok
	# Confusion: an attacking unit fumbles ~50% of the time.
	var cu := gs.add_to_bench("player", W60)
	gs.apply_status(cu, "confusion")
	var reds := 0
	for i in 600:
		if String(gs._roll_full(cu, true)["seg"]["col"]) == "red":
			reds += 1
	print("  confusion red rate = %.2f (expect ~0.50, range .35-.65)" % (reds / 600.0))
	ok = (reds > 210 and reds < 390) and ok

	print("=== C. MARKED makes a tie into a KO ===")
	var atk := gs.add_to_bench("player", W60)
	var dfn := gs.add_to_bench("enemy", W60)
	# baseline: white60 vs white60 = tie, nobody KO'd
	_place(gs, atk, 0); _place(gs, dfn, 1)
	var r0 := gs.attack(atk, dfn)
	ok = _expect("unmarked white60 vs white60 = tie", int(r0["result"]), 0) and ok
	# marked defender: attacker gets +20 -> 80 vs 60 -> attacker wins + KO
	_reset(gs, atk, 0); _reset(gs, dfn, 1)
	gs.apply_status(dfn, "marked")
	var r1 := gs.attack(atk, dfn)
	ok = _expect("marked def -> attacker wins", int(r1["result"]), 1) and ok
	ok = _expect("marked def -> KO'd", int(r1["ko"]), dfn) and ok

	print("=== D. CURSE loses ties ===")
	_reset(gs, atk, 0); _reset(gs, dfn, 1)
	gs.apply_status(atk, "curse")     # attacker cursed -> attacker loses the tie
	var r2 := gs.attack(atk, dfn)
	ok = _expect("cursed attacker loses tie", int(r2["result"]), -1) and ok
	ok = _expect("cursed attacker KO'd (def rolled white)", int(r2["ko"]), atk) and ok
	# both cursed -> still a tie
	_reset(gs, atk, 0); _reset(gs, dfn, 1)
	gs.apply_status(atk, "curse"); gs.apply_status(dfn, "curse")
	ok = _expect("both cursed -> still tie", int(gs.attack(atk, dfn)["result"]), 0) and ok

	print("=== E. SLEEP wakes on combat ===")
	_reset(gs, atk, 0); _reset(gs, dfn, 1)
	gs.apply_status(dfn, "sleep")
	gs.attack(atk, dfn)
	ok = _expect("defender woke up after combat", gs.has_status(dfn, "sleep"), false) and ok

	print("=== F. BURN/POISON are lethal timers (cleansable) ===")
	# Burn kills after BURN_TURNS unless cleansed.
	var p1 := gs.add_to_bench("player", W60)
	_place(gs, p1, 5)
	gs.apply_status(p1, "burn")
	var died := _run_turns_until_dead(gs, p1, GameState.BURN_TURNS + 4)
	ok = _expect("burn eventually KOs", died, true) and ok
	# Cleanse (Rank Up / Cleanse modifier clears statuses) prevents the KO.
	gs2_test(ok)

func gs2_test(prev_ok: bool) -> void:
	var ok := prev_ok
	var gs := GameState.new(MapData.new())
	var p := gs.add_to_bench("player", W60)
	_place(gs, p, 5)
	gs.apply_status(p, "poison")
	# Cleanse the turn before it would elapse, then keep going past the timer.
	for i in GameState.POISON_TURNS + 4:
		if i == 1:
			gs.units[p]["statuses"] = {}   # simulate Cleanse / Rank Up
		gs.end_turn()
	ok = _expect("poison cleansed -> survives", gs.units[p]["alive"], true) and ok

	print("COMBAT_STATUS_OK" if ok else "STATUS_TESTS_FAILED")
	quit()

# ---- helpers ----
func _place(gs: GameState, uid: int, node: int) -> void:
	gs.bench[gs.units[uid]["team"]].erase(uid)
	gs.units[uid]["node"] = node
	gs.board[node] = uid

func _reset(gs: GameState, uid: int, node: int) -> void:
	gs.units[uid]["alive"] = true
	gs.units[uid]["statuses"] = {}
	gs.units[uid]["node"] = node
	gs.board[node] = uid

func _run_turns_until_dead(gs: GameState, uid: int, max_turns: int) -> bool:
	for i in max_turns:
		gs.end_turn()
		if not gs.units[uid]["alive"]:
			return true
	return false

func _expect(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print(("  %-42s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
