extends SceneTree
## Verify Rank Up + evolution data + the two new figures + Venom Aura.

func _idx(id: String) -> int:
	for i in Roster.FIGURES.size():
		if Roster.FIGURES[i]["id"] == id:
			return i
	return -1

func _initialize() -> void:
	var gs := GameState.new(MapData.new())
	var vw := _idx("venom_witch")
	var eb := _idx("emberborn")
	var ct := _idx("coin_trickster")
	print("indices vw=", vw, " eb=", eb, " ct=", ct, " count=", Roster.FIGURES.size())

	# Venom Witch -> Plague Matron
	var w := gs.add_to_bench("player", vw)
	print("vw name0=", gs.name_for(w), " type0=", gs.type_for(w), " venom_bolt0=", gs.pool_for(w)[3].get("pow"))
	print("vw rankup=", gs._try_rank_up(w), " name1=", gs.name_for(w), " venom_aura=", gs.has_passive(w, "venom_aura"), " bolt1=", gs.pool_for(w)[3].get("pow"))
	print("vw rankup_again=", gs._try_rank_up(w))

	# Emberborn 3 stages
	var e := gs.add_to_bench("player", eb)
	print("eb name0=", gs.name_for(e), " stam0=", gs.units[e]["stamina"])
	gs._try_rank_up(e)
	print("eb name1=", gs.name_for(e), " stam1=", gs.units[e]["stamina"])
	gs._try_rank_up(e)
	print("eb name2=", gs.name_for(e), " burning=", gs.has_passive(e, "burning_aura"), " type=", gs.type_for(e))
	print("eb rankup_more=", gs._try_rank_up(e))

	# Coin Trickster (Double Coin)
	var c := gs.add_to_bench("player", ct)
	print("ct type=", gs.type_for(c), " pool=", gs.pool_for(c).size(), " has_ai=", gs.pool_for(c)[0].has("ai"))

	# Venom Aura: adjacent enemy loses 1 stamina
	var g2 := GameState.new(MapData.new())
	var m := g2.add_to_bench("enemy", vw)
	g2._try_rank_up(m)
	var t := g2.add_to_bench("player", _idx("storm_valkyrie"))
	g2.units[m]["node"] = 8; g2.board[8] = m
	g2.units[t]["node"] = g2.map.adj[8][0]; g2.board[g2.map.adj[8][0]] = t
	print("venom_aura base=", g2.units[t]["stamina"], " effective=", g2.effective_stamina(t))

	# Attack KO triggers Rank Up
	var g3 := GameState.new(MapData.new())
	var atk := g3.add_to_bench("player", eb)
	var df := g3.add_to_bench("enemy", _idx("stone_golem"))
	var fired := false
	for i in 1500:
		g3.units[atk]["alive"] = true; g3.units[df]["alive"] = true
		g3.units[atk]["rank"] = 0
		g3.units[atk]["statuses"] = {}; g3.units[df]["statuses"] = {}
		g3.units[atk]["node"] = 0; g3.units[df]["node"] = 5
		g3.board.clear(); g3.board[0] = atk; g3.board[5] = df
		g3.ko_bench["player"].clear(); g3.ko_bench["enemy"].clear()
		var rec := g3.attack(atk, df)
		if int(rec["ko"]) == df and int(rec.get("rankup", -1)) == atk:
			fired = true
			break
	print("attack_ko_triggers_rankup=", fired)
	print("RANKUP_OK")
	quit()
