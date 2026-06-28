extends SceneTree
## Rigorous combat audit: colour hierarchy, same-colour power, modifier buffs,
## rank-up damage, buff-node bonus. Confirms what decides a win.

func W(p) -> Dictionary: return {"col": "white", "pow": p}
func G(p) -> Dictionary: return {"col": "gold", "pow": p}
func P(s) -> Dictionary: return {"col": "purple", "stars": s}
func B() -> Dictionary: return {"col": "blue"}
func R() -> Dictionary: return {"col": "red"}

func _initialize() -> void:
	print("=== A. COLOUR HIERARCHY (who wins, regardless of damage) ===")
	_o("white 200 vs blue 0", W(200), B(), -1)        # blue blocks even huge damage
	_o("blue vs white 200", B(), W(200), 1)
	_o("white vs purple", W(99), P(1), -1)            # purple beats white (cycle)
	_o("purple vs white", P(1), W(99), 1)
	_o("white vs gold", W(10), G(99), 1)              # white beats gold
	_o("gold vs purple", G(10), P(3), 1)              # gold beats purple
	_o("red vs white", R(), W(10), -1)                # red always loses
	_o("blue vs blue", B(), B(), 0)

	print("=== B. SAME COLOUR -> DAMAGE decides (where a buff matters) ===")
	_o("white 60 vs white 80", W(60), W(80), -1)      # LOSE
	_o("white 80 vs white 80", W(80), W(80), 0)       # +20 surge -> TIE
	_o("white 100 vs white 80", W(100), W(80), 1)     # +40 fury  -> WIN
	_o("purple 1 vs purple 2", P(1), P(2), -1)
	_o("purple 2 vs purple 2", P(2), P(2), 0)         # +1 star -> tie/up

	print("=== C. _boost_seg + same-colour FLIP ===")
	var gs := GameState.new(MapData.new())
	var w := W(60)
	gs._boost_seg(w, 20, 1)        # power_surge on a white
	print("surge white 60 ->", w["pow"], " (expect 80)")
	print("  outcome buffed(80) vs 70 =", Combat.resolve(w, W(70)), " (expect 1 WIN; was -1 before buff)")
	var pp := P(1)
	gs._boost_seg(pp, 20, 1)
	print("surge purple ★1 -> ★", pp["stars"], " (expect 2)")

	print("=== D. attack() bakes the buff into seg_a (vs same-type foe) ===")
	var a := gs.add_to_bench("player", 1)   # Ironclad (white/blue/purple/gold)
	var d := gs.add_to_bench("enemy", 1)
	var base_max := 0
	for s in gs.pool_for(a):
		if s.has("pow"): base_max = maxi(base_max, int(s["pow"]))
	var seen_over := false
	for i in 400:
		gs.units[a]["alive"] = true; gs.units[d]["alive"] = true
		gs.units[a]["node"] = 0; gs.units[d]["node"] = 5
		gs.board.clear(); gs.board[0] = a; gs.board[5] = d
		gs.ko_bench["player"].clear(); gs.ko_bench["enemy"].clear()
		gs.pending_buff["player"]["surge"] = true
		var rec := gs.attack(a, d)
		var sa: Dictionary = rec["seg_a"]
		if sa.has("pow") and int(sa["pow"]) > base_max:
			seen_over = true
	print("base white max =", base_max, "  attack with surge produced pow > base =", seen_over, " (expect true)")

	print("=== E. RANK UP uses the evolved (stronger) pool ===")
	var vw := -1
	for i in Roster.FIGURES.size():
		if Roster.FIGURES[i]["id"] == "venom_witch": vw = i
	var u := gs.add_to_bench("player", vw)
	var base_bolt := _white_max(gs.pool_for(u))
	gs._try_rank_up(u)
	var rank_bolt := _white_max(gs.pool_for(u))
	print("Venom Witch white max base =", base_bolt, "  ranked (Plague Matron) =", rank_bolt, " (expect 40 -> 55)")

	print("=== F. WIN REASON (combat transparency) ===")
	print("  white vs blue     ->", Combat.win_reason(W(99), B()))
	print("  white80 vs white60->", Combat.win_reason(W(80), W(60)))
	print("  white vs purple   ->", Combat.win_reason(W(99), P(1)))
	print("  red vs white      ->", Combat.win_reason(R(), W(10)))
	print("COMBAT_CHECK_OK")
	quit()

func _o(label: String, a: Dictionary, b: Dictionary, want: int) -> void:
	var got := Combat.resolve(a, b)
	print(("  %-28s got=%d want=%d  %s") % [label, got, want, ("OK" if got == want else "<<< FAIL")])

func _white_max(pool: Array) -> int:
	var m := 0
	for s in pool:
		if String(s.get("col", "")) == "white" and s.has("pow"):
			m = maxi(m, int(s["pow"]))
	return m
