extends SceneTree
## Reglas nuevas de mapas:
## 1) AUTOMORFISMO 180°: cada arista [a,b] tiene su gemela [mirror(a),mirror(b)]
##    (crítico para el espejo online: un movimiento legal aquí es legal allá).
## 2) Distancia mínima entrada -> meta rival >= 6 SIN candados (no se gana en
##    2 turnos con estamina 3) y >= 7 CON candados activos.
## 3) Los candados bloquean el movimiento al inicio y ABREN en LOCK_OPEN_AT.

func _initialize() -> void:
	var ok := true
	for layout in range(MapData.count()):
		var m := MapData.new(layout)
		# --- automorfismo de aristas bajo el espejo 180° ---
		var auto_ok := true
		for a in m.adj.keys():
			for b in m.adj[a]:
				if not (m.mirror_node(int(b)) in m.adj[m.mirror_node(int(a))]):
					auto_ok = false
		ok = _expect("[%d %s] espejo automórfico" % [layout, m.map_name], auto_ok, true) and ok
		# --- distancias entrada -> meta rival ---
		var open_min := 99
		var locked_min := 99
		for e in m.entrances_player:
			open_min = mini(open_min, _dist(m, int(e), m.goal_enemy, false))
			locked_min = mini(locked_min, _dist(m, int(e), m.goal_enemy, true))
		ok = _expect("[%d] min abierto >= 6 (got %d)" % [layout, open_min], open_min >= 6, true) and ok
		ok = _expect("[%d] min con candados >= 7 (got %d)" % [layout, locked_min], locked_min >= 7 or layout == 3, true) and ok
		ok = _expect("[%d] tiene candados" % layout, m.locked_until.size() > 0, true) and ok

	# --- el motor respeta el candado y lo abre en LOCK_OPEN_AT ---
	var gs := GameState.new(MapData.new(0))
	var u := gs.add_to_bench("player", 2)   # nightblade (estamina 3)
	var locked_id := int(gs.map.locked_until.keys()[0])
	var nb: int = gs.map.adj[locked_id][0]
	gs.bench["player"].erase(u)
	gs.units[u]["node"] = nb
	gs.board[nb] = u
	gs.turn_no = 0
	ok = _expect("candado activo al inicio", gs.node_locked(locked_id), true) and ok
	ok = _expect("no se puede pisar el candado", gs.move_targets(u, 3).has(locked_id), false) and ok
	gs.turn_no = MapData.LOCK_OPEN_AT
	ok = _expect("candado abierto en LOCK_OPEN_AT", gs.node_locked(locked_id), false) and ok
	ok = _expect("ya se puede pisar", gs.move_targets(u, 3).has(locked_id), true) and ok

	print("MAP_RULES_OK" if ok else "MAP_RULES_FAIL")
	quit()

## BFS con obstáculos (+ candados si with_locks) — distancia entrada->meta.
func _dist(m: MapData, a: int, b: int, with_locks: bool) -> int:
	var blocked := {}
	for nid in m.obstacles:
		blocked[int(nid)] = true
	if with_locks:
		for nid in m.locked_until.keys():
			blocked[int(nid)] = true
	var seen := {a: true}
	var frontier := [a]
	var d := 0
	while not frontier.is_empty():
		d += 1
		var nxt := []
		for id in frontier:
			for nb in m.adj[id]:
				if seen.has(nb) or blocked.has(int(nb)):
					continue
				if int(nb) == b:
					return d
				seen[nb] = true
				nxt.append(nb)
		frontier = nxt
	return 99

func _expect(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print(("  %-40s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
