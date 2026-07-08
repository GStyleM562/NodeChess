extends SceneTree
## Vuelta01 · FASE 2 (motor): modificadores nuevos (Iron Wall, Escudo, Prisa,
## Drenaje, Revivir, Trampa) y pasivas nuevas (Warcry, Goalkeeper, Scavenger).

func _initialize() -> void:
	var ok := true
	Roster.FIGURES.append({"id": "f2_push", "name": "Empujador", "stamina": 2, "type": "Ruleta",
		"passives": [], "attack": [{"col": "purple", "stars": 3, "fx": "Empuje", "disp": "push", "n": 1, "w": 100}]})
	Roster.FIGURES.append({"id": "f2_white", "name": "Blanco60", "stamina": 2, "type": "Ruleta",
		"passives": [], "attack": [{"col": "white", "pow": 60, "w": 100}]})
	Roster.FIGURES.append({"id": "f2_red", "name": "Fallon", "stamina": 2, "type": "Ruleta",
		"passives": [], "attack": [{"col": "red", "w": 100}]})
	Roster.FIGURES.append({"id": "f2_scav", "name": "Carroniero", "stamina": 2, "type": "Ruleta",
		"passives": ["scavenger"], "attack": [{"col": "white", "pow": 100, "w": 100}]})
	Roster.FIGURES.append({"id": "f2_war", "name": "Grito", "stamina": 2, "type": "Ruleta",
		"passives": ["warcry"], "attack": [{"col": "white", "pow": 40, "w": 100}]})
	Roster.FIGURES.append({"id": "f2_goal", "name": "Portero", "stamina": 2, "type": "Ruleta",
		"passives": ["goalkeeper"], "attack": [{"col": "white", "pow": 40, "w": 100}]})
	var i_push := Roster.FIGURES.size() - 6
	var i_white := Roster.FIGURES.size() - 5
	var i_red := Roster.FIGURES.size() - 4
	var i_scav := Roster.FIGURES.size() - 3
	var i_war := Roster.FIGURES.size() - 2
	var i_goal := Roster.FIGURES.size() - 1

	# --- IRON WALL: inmune a desplazamientos este turno; caduca al terminar ---
	var g := GameState.new(MapData.new())
	var a := g.add_to_bench("player", i_push)
	var d := g.add_to_bench("enemy", i_white)
	_place(g, a, d)
	g.energy["enemy"] = 10
	ok = _expect("iron_wall activado", g.activate_modifier("enemy", "iron_wall"), true) and ok
	var rec := g.attack(a, d, 0, 0, 0)
	ok = _expect("empuje bloqueado (immune)", String((rec["disp"] as Dictionary).get("type", "")), "immune") and ok
	g.turn_team = "enemy"
	g.end_turn()   # termina el turno enemy -> caduca
	g.mod_used["enemy"] = false
	var rec2 := g.attack(a, d, 0, 0, 0)
	ok = _expect("caducado: el empuje YA entra", String((rec2["disp"] as Dictionary).get("type", "")), "push") and ok

	# --- ESCUDO: la defensa convierte UN Fallo en Azul ---
	var g2 := GameState.new(MapData.new())
	var a2 := g2.add_to_bench("player", i_white)
	var d2 := g2.add_to_bench("enemy", i_red)
	_place(g2, a2, d2)
	g2.energy["enemy"] = 10
	g2.activate_modifier("enemy", "shield")
	var rec3 := g2.attack(a2, d2, 0, 0, 0)
	ok = _expect("escudo: Fallo->Azul (defensor gana)", int(rec3["result"]), -1) and ok
	ok = _expect("escudo consumido", (g2.pending_buff["enemy"] as Dictionary).has("guard"), false) and ok

	# --- PRISA: +1 estamina del equipo este turno ---
	var g3 := GameState.new(MapData.new())
	var u3 := g3.add_to_bench("player", i_white)
	var ent3: int = g3.free_entrances("player")[0]
	g3.bench["player"].erase(u3)
	g3.units[u3]["node"] = ent3
	g3.board[ent3] = u3
	g3.energy["player"] = 10
	var base_st := g3.effective_stamina(u3)
	g3.activate_modifier("player", "haste")
	ok = _expect("prisa: +1 estamina", g3.effective_stamina(u3), base_st + 1) and ok
	g3.turn_team = "player"
	g3.end_turn()
	ok = _expect("prisa caduca", g3.effective_stamina(u3), base_st) and ok

	# --- DRENAJE: roba 2 de energía ---
	var g4 := GameState.new(MapData.new())
	g4.energy["player"] = 5
	g4.energy["enemy"] = 4
	g4.activate_modifier("player", "energy_drain")
	ok = _expect("drenaje: rival -2", int(g4.energy["enemy"]), 2) and ok
	ok = _expect("drenaje: yo +2 (5-3+2)", int(g4.energy["player"]), 4) and ok

	# --- REVIVIR: la caída más reciente vuelve a la banca ---
	var g5 := GameState.new(MapData.new())
	var r1 := g5.add_to_bench("player", i_white)
	var r2 := g5.add_to_bench("player", i_red)
	g5.bench["player"].erase(r1)
	g5.bench["player"].erase(r2)
	g5._ko(r1)
	g5.turn_no += 2
	g5._ko(r2)   # r2 es la más reciente
	g5.energy["player"] = 10
	ok = _expect("revivir activado", g5.activate_modifier("player", "revive"), true) and ok
	ok = _expect("la más reciente volvió", r2 in g5.bench["player"], true) and ok
	ok = _expect("la otra sigue K.O.", r1 in g5.ko_bench["player"], true) and ok

	# --- TRAMPA: inmoviliza al rival que la pisa; la propia no daña ---
	var g6 := GameState.new(MapData.new())
	var t1 := g6.add_to_bench("player", i_white)
	var v6 := g6.add_to_bench("enemy", i_white)
	_place(g6, t1, v6)
	var free_n := -1
	for nb in g6.map.adj[int(g6.units[v6]["node"])]:
		if not g6.board.has(int(nb)) and not (int(nb) in g6.map.obstacles) and not g6.node_locked(int(nb)):
			free_n = int(nb)
			break
	g6.energy["player"] = 10
	ok = _expect("trampa colocada", g6.activate_modifier("player", "trap", free_n), true) and ok
	ok = _expect("trampa oculta registrada", g6.traps.has(free_n), true) and ok
	g6.move_unit(v6, free_n)
	ok = _expect("rival INMOVILIZADO", g6.has_status(v6, "immobilized"), true) and ok
	ok = _expect("trampa consumida", g6.traps.has(free_n), false) and ok
	ok = _expect("evento para la vista", g6.trap_events.size(), 1) and ok

	# --- WARCRY: al desplegar debilita adyacentes ---
	var g7 := GameState.new(MapData.new())
	var w7 := g7.add_to_bench("player", i_war)
	var e7 := g7.add_to_bench("enemy", i_white)
	var ent: int = g7.free_entrances("player")[0]
	var adjn := -1
	for nb in g7.map.adj[ent]:
		if not g7.board.has(int(nb)):
			adjn = int(nb)
			break
	g7.bench["enemy"].erase(e7)
	g7.units[e7]["node"] = adjn
	g7.board[adjn] = e7
	g7.deploy(w7, ent)
	ok = _expect("warcry debilitó al vecino", g7.has_status(e7, "weakened"), true) and ok

	# --- GOALKEEPER: +20 parado en su meta ---
	var g8 := GameState.new(MapData.new())
	var k8 := g8.add_to_bench("player", i_goal)
	g8.bench["player"].erase(k8)
	g8.units[k8]["node"] = g8.map.goal_player
	g8.board[g8.map.goal_player] = k8
	var roll: Dictionary = g8._roll_full(k8, true, 0)
	ok = _expect("goalkeeper 40+20", int((roll["seg"] as Dictionary).get("pow", 0)), 60) and ok

	# --- SCAVENGER: +2 energía al noquear ---
	var g9 := GameState.new(MapData.new())
	var s9 := g9.add_to_bench("player", i_scav)
	var v9 := g9.add_to_bench("enemy", i_red)
	_place(g9, s9, v9)
	g9.energy["player"] = 0
	g9.attack(s9, v9, 0, 0, 0)
	ok = _expect("scavenger +2 energía", int(g9.energy["player"]), 2) and ok

	for n in 6:
		Roster.FIGURES.pop_back()
	print("V1_FASE2_OK" if ok else "V1_FASE2_FAIL")
	quit()

func _place(g: GameState, a: int, d: int) -> void:
	for u in [a, d]:
		g.units[u]["alive"] = true
		var old := int(g.units[u]["node"])
		if g.board.get(old, -1) == u:
			g.board.erase(old)
		g.bench["player"].erase(u)
		g.bench["enemy"].erase(u)
	for n in g.map.nodes:
		var id := int(n["id"])
		if id in g.map.buffs or id in g.map.obstacles or g.board.has(id) or String(n["role"]) != "normal" or g.node_locked(id):
			continue
		for nb in g.map.adj[id]:
			if nb in g.map.buffs or nb in g.map.obstacles or g.board.has(nb) or g.node_locked(int(nb)):
				continue
			if String(g.map.nodes[nb]["role"]) != "normal":
				continue
			g.units[a]["node"] = id
			g.board[id] = a
			g.units[d]["node"] = int(nb)
			g.board[int(nb)] = d
			return

func _expect(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print(("  %-40s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
