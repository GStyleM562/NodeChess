extends SceneTree
## Validate every map against the shared rules.

func _initialize() -> void:
	var all_ok := true
	for layout in range(MapData.count()):
		var m := MapData.new(layout)
		var maxdeg := 0
		for id in m.adj.keys():
			maxdeg = maxi(maxdeg, (m.adj[id] as Array).size())
		var goals_ok := (m.adj[m.goal_player] as Array).size() >= 1 and (m.adj[m.goal_enemy] as Array).size() >= 1
		var reach := m.reachable(m.entrances_player[0], 50)
		var path_ok: bool = reach.has(m.goal_enemy)
		var buff_ok: bool = m.buffs.size() >= 1
		var sym_ok := _symmetric(m)
		var okmap: bool = maxdeg <= 3 and goals_ok and path_ok and buff_ok and sym_ok
		var tag := "OK" if okmap else "FAIL"
		print("MAP[%d] '%s' nodes=%d maxdeg=%d goals=%s path=%s buff=%s sym=%s -> %s" % [
			layout, m.map_name, m.nodes.size(), maxdeg, goals_ok, path_ok, buff_ok, sym_ok, tag])
		if not okmap:
			all_ok = false
	print("MAPS_ALL_OK=", all_ok)
	quit()

func _symmetric(m: MapData) -> bool:
	for n in m.nodes:
		var p: Vector3 = n["pos"]
		var found := false
		for o in m.nodes:
			if abs(o["pos"].x + p.x) < 0.02 and abs(o["pos"].z - p.z) < 0.02:
				found = true
				break
		if not found:
			return false
	return true
