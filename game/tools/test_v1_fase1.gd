extends SceneTree
## Vuelta01 · FASE 1: mazo de 6, resistencias, Hover, Fast Recovery,
## Dash/Retirada/Teletransporte y buff nodes con CARGA.

var gs: GameState

func _initialize() -> void:
	var ok := true

	# --- mazo de 6 (GDD) ---
	ok = _expect("DECK_SIZE = 6", Loadout.DECK_SIZE, 6) and ok
	ok = _expect("equipo default válido", Loadout.valid(Loadout.player_team), true) and ok
	ok = _expect("CPU default válido", Loadout.valid(Loadout.enemy_team), true) and ok

	# figuras de control
	Roster.FIGURES.append({"id": "f1_resist", "name": "Resistente", "stamina": 2, "type": "Ruleta",
		"passives": [], "resists": ["fear", "poison"],
		"attack": [{"col": "white", "pow": 50, "w": 100}]})
	Roster.FIGURES.append({"id": "f1_purple", "name": "Miedoso", "stamina": 2, "type": "Ruleta",
		"passives": [], "attack": [{"col": "purple", "stars": 2, "fx": "Miedo", "w": 100}]})
	Roster.FIGURES.append({"id": "f1_hover", "name": "Flotador", "stamina": 4, "type": "Ruleta",
		"passives": ["hover", "fast_recovery"], "attack": [{"col": "white", "pow": 40, "w": 100}]})
	Roster.FIGURES.append({"id": "f1_dash", "name": "Dasher", "stamina": 2, "type": "Ruleta",
		"passives": [], "attack": [{"col": "purple", "stars": 3, "fx": "Dash", "disp": "dash", "w": 100}]})
	var i_res := Roster.FIGURES.size() - 4
	var i_pur := Roster.FIGURES.size() - 3
	var i_hov := Roster.FIGURES.size() - 2
	var i_dash := Roster.FIGURES.size() - 1

	# --- RESISTENCIAS: el estado NO se aplica ---
	gs = GameState.new(MapData.new())
	var r := gs.add_to_bench("player", i_res)
	ok = _expect("apply_status resistido", gs.apply_status(r, "fear"), false) and ok
	ok = _expect("sin miedo", gs.has_status(r, "fear"), false) and ok
	ok = _expect("otros estados sí entran", gs.apply_status(r, "burn"), true) and ok
	# en combate: púrpura gana pero el rival RESISTE
	var p := gs.add_to_bench("enemy", i_pur)
	_place(p, r)
	var rec := gs.attack(p, r, 0, 0, 0)
	ok = _expect("púrpura ganó", int(rec["result"]), 1) and ok
	ok = _expect("efecto RESISTIDO", bool((rec["status"] as Dictionary).get("resisted", false)), true) and ok
	ok = _expect("sigue sin miedo", gs.has_status(r, "fear"), false) and ok

	# --- HOVER: cruza candados/obstáculos, no TERMINA sobre ellos ---
	var g2 := GameState.new(MapData.new(0))   # Rieles: candados en riel medio
	var h := g2.add_to_bench("player", i_hov)
	var locked_id := int(g2.map.locked_until.keys()[0])
	var nb: int = g2.map.adj[locked_id][0]
	var beyond := -1
	for x in g2.map.adj[locked_id]:
		if int(x) != nb:
			beyond = int(x)
	g2.bench["player"].erase(h)
	g2.units[h]["node"] = nb
	g2.board[nb] = h
	var reach := g2.move_targets(h, 4)
	ok = _expect("hover no termina en candado", reach.has(locked_id), false) and ok
	ok = _expect("hover CRUZA el candado", beyond != -1 and reach.has(beyond), true) and ok
	# una figura normal NO cruza
	var n2 := g2.add_to_bench("player", i_res)
	g2.bench["player"].erase(n2)
	var nb2 := -1
	for x in g2.map.adj[locked_id]:
		if int(x) != nb and g2.map.adj[x].size() > 0:
			nb2 = int(x)
	# (desde el mismo lado que h para comparar) — usa el nodo de h liberándolo
	g2.board.erase(nb)
	g2.units[n2]["node"] = nb
	g2.board[nb] = n2
	var reach_n := g2.move_targets(n2, 4)
	ok = _expect("normal NO cruza candado", beyond != -1 and reach_n.has(beyond), false) and ok

	# --- FAST RECOVERY: vuelve una ronda antes ---
	var g3 := GameState.new(MapData.new())
	var fr := g3.add_to_bench("player", i_hov)
	var no_fr := g3.add_to_bench("player", i_res)
	g3._ko(fr)
	g3._ko(no_fr)
	ok = _expect("fast_recovery -2 medio-turnos",
		int(g3.units[no_fr]["ko_until"]) - int(g3.units[fr]["ko_until"]), 2) and ok

	# --- DASH: el ganador avanza 1 hacia el rival (determinista) ---
	var g4 := GameState.new(MapData.new())
	var d := g4.add_to_bench("player", i_dash)
	var v := g4.add_to_bench("enemy", i_res)
	_place2(g4, d, v)
	var prev_node := int(g4.units[d]["node"])
	var rec4 := g4.attack(d, v, 0, 0, 0)
	ok = _expect("dash movió al ganador", String((rec4["disp"] as Dictionary).get("type", "")), "dash") and ok
	ok = _expect("dash cambió de nodo", int(g4.units[d]["node"]) != prev_node, true) and ok
	ok = _expect("tablero consistente tras dash", g4.board_consistent(), true) and ok

	# --- TELEPORT: manda al perdedor a su entrada libre ---
	Roster.FIGURES.append({"id": "f1_tp", "name": "Portador", "stamina": 2, "type": "Ruleta",
		"passives": [], "attack": [{"col": "purple", "stars": 3, "fx": "Teletransporte", "disp": "teleport", "w": 100}]})
	var i_tp := Roster.FIGURES.size() - 1
	var g5 := GameState.new(MapData.new())
	var t := g5.add_to_bench("player", i_tp)
	var v2 := g5.add_to_bench("enemy", i_res)
	_place2(g5, t, v2)
	var rec5 := g5.attack(t, v2, 0, 0, 0)
	ok = _expect("teleport aplicado", String((rec5["disp"] as Dictionary).get("type", "")), "teleport") and ok
	ok = _expect("perdedor en SU entrada", int(g5.units[v2]["node"]) in g5.map.entrances_enemy, true) and ok
	ok = _expect("consistente tras teleport", g5.board_consistent(), true) and ok

	# --- BUFF con CARGA: 2 turnos propios parado -> potenciada permanente ---
	var g6 := GameState.new(MapData.new())
	var u6 := g6.add_to_bench("player", i_res)
	var b0: int = g6.map.buffs[0]
	g6.bench["player"].erase(u6)
	g6.units[u6]["node"] = b0
	g6.board[b0] = u6
	g6.turn_team = "player"
	g6.end_turn()   # carga 1 (termina turno player)
	ok = _expect("carga 1/2", g6.buff_progress(b0), 1) and ok
	ok = _expect("aún sin buff", bool(g6.units[u6].get("buffed", false)), false) and ok
	g6.end_turn()   # turno enemy termina: no cuenta para player
	g6.end_turn()   # player termina de nuevo -> carga 2 -> ¡BUFF!
	ok = _expect("figura POTENCIADA", bool(g6.units[u6].get("buffed", false)), true) and ok
	ok = _expect("nodo en cooldown", g6.turn_no < int(g6.buff_cd.get(b0, 0)), true) and ok
	# la tirada sale potenciada (+BUFF_DMG) aunque NO esté parada en el buff
	g6.board.erase(b0)
	g6.units[u6]["node"] = int(g6.map.adj[b0][0])
	g6.board[int(g6.map.adj[b0][0])] = u6
	var roll: Dictionary = g6._roll_full(u6, true, 0)
	ok = _expect("tirada potenciada 50+%d" % GameState.BUFF_DMG, int((roll["seg"] as Dictionary).get("pow", 0)), 50 + GameState.BUFF_DMG) and ok
	# irse a MEDIA carga reinicia
	var g7 := GameState.new(MapData.new())
	var u7 := g7.add_to_bench("player", i_res)
	g7.bench["player"].erase(u7)
	g7.units[u7]["node"] = b0
	g7.board[b0] = u7
	g7.turn_team = "player"
	g7.end_turn()
	ok = _expect("g7 carga 1", g7.buff_progress(b0), 1) and ok
	g7.board.erase(b0)   # se va del nodo
	g7.units[u7]["node"] = int(g7.map.adj[b0][0])
	g7.board[int(g7.map.adj[b0][0])] = u7
	g7.end_turn()
	g7.turn_team = "player"
	g7.end_turn()
	ok = _expect("irse REINICIA la carga", g7.buff_progress(b0), 0) and ok

	for n in 5:
		Roster.FIGURES.pop_back()
	print("V1_FASE1_OK" if ok else "V1_FASE1_FAIL")
	quit()

func _place(a: int, d: int) -> void:
	_place2(gs, a, d)

func _place2(g: GameState, a: int, d: int) -> void:
	for u in [a, d]:
		g.units[u]["alive"] = true
		var old := int(g.units[u]["node"])
		if g.board.get(old, -1) == u:
			g.board.erase(old)
		g.bench["player"].erase(u)
		g.bench["enemy"].erase(u)
	var pair := _neutral_pair(g)
	g.units[a]["node"] = pair[0]
	g.board[pair[0]] = a
	g.units[d]["node"] = pair[1]
	g.board[pair[1]] = d

func _neutral_pair(g: GameState) -> Array:
	for n in g.map.nodes:
		var id := int(n["id"])
		if id in g.map.buffs or id in g.map.obstacles or g.board.has(id) or String(n["role"]) != "normal":
			continue
		for nb in g.map.adj[id]:
			if nb in g.map.buffs or nb in g.map.obstacles or g.board.has(nb) or g.node_locked(int(nb)) or g.node_locked(id):
				continue
			if String(g.map.nodes[nb]["role"]) != "normal":
				continue
			return [id, int(nb)]
	return [0, 1]

func _expect(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print(("  %-38s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
