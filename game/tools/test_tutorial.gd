extends SceneTree
## Vuelta01 · F6: bot de TUTORIAL (bot_difficulty = -1) — muñeco de práctica:
## despliega, camina 1 nodo hacia la meta, se DETIENE junto a rivales y JAMÁS ataca.

func _initialize() -> void:
	var ok := true
	Roster.FIGURES.append({"id": "tut_dummy", "name": "Dummy", "stamina": 2, "type": "Ruleta",
		"passives": [], "attack": [{"col": "white", "pow": 100, "w": 100}]})
	var i_dummy := Roster.FIGURES.size() - 1

	# --- 1) primera acción: DESPLIEGA (y el tablero queda consistente) ---
	var g := GameState.new(MapData.new(0))
	g.bot_difficulty = -1
	var e := g.add_to_bench("enemy", i_dummy)
	var _p := g.add_to_bench("player", i_dummy)
	g.turn_team = "enemy"
	var rec := g.bot_action("enemy")
	ok = _expect("tutorial: primero despliega", String(rec.get("type", "")), "deploy") and ok
	ok = _expect("tablero consistente tras deploy", g.board_consistent(), true) and ok
	ok = _expect("unidad en tablero", int(g.units[e]["node"]) >= 0, true) and ok

	# --- 2) sin rivales cerca: MUEVE y se acerca a la meta del jugador ---
	g.turn_team = "enemy"
	var before: int = int(g.units[e]["node"])
	var d_before: float = g.map.pos_of(before).distance_to(g.map.pos_of(g.map.goal_player))
	var rec2 := g.bot_action("enemy")
	ok = _expect("tutorial: luego camina", String(rec2.get("type", "")), "move") and ok
	var after: int = int(g.units[e]["node"])
	var d_after: float = g.map.pos_of(after).distance_to(g.map.pos_of(g.map.goal_player))
	ok = _expect("se acerca a la meta", d_after < d_before, true) and ok
	ok = _expect("paso de 1 nodo (adyacente)", after in g.map.adj[before], true) and ok

	# --- 3) junto a un rival: PASA (muñeco de práctica, jamás ataca) ---
	var g2 := GameState.new(MapData.new(0))
	g2.bot_difficulty = -1
	var e2 := g2.add_to_bench("enemy", i_dummy)
	var p2 := g2.add_to_bench("player", i_dummy)
	_place(g2, e2, p2)   # e2 y p2 quedan en nodos ADYACENTES
	g2.turn_team = "enemy"
	var stand: int = int(g2.units[e2]["node"])
	var rec3 := g2.bot_action("enemy")
	ok = _expect("adyacente a rival: pasa", String(rec3.get("type", "")), "pass") and ok
	ok = _expect("no se movió", int(g2.units[e2]["node"]), stand) and ok
	ok = _expect("el rival sigue vivo", bool(g2.units[p2]["alive"]), true) and ok

	# --- 4) muchas rondas: NUNCA ataca, tablero siempre consistente ---
	var never_attacks := true
	var always_consistent := true
	for i in 12:
		g.turn_team = "enemy"
		var r := g.bot_action("enemy")
		if String(r.get("type", "")) == "attack":
			never_attacks = false
		if not g.board_consistent():
			always_consistent = false
		g.end_turn()
	ok = _expect("12 rondas sin atacar", never_attacks, true) and ok
	ok = _expect("12 rondas consistentes", always_consistent, true) and ok

	print("TUTORIAL_OK" if ok else "TUTORIAL_FAIL")
	quit()

## Coloca a y d vivos en dos nodos normales ADYACENTES libres (fuera de banca).
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
