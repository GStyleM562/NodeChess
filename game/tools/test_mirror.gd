extends SceneTree
## mirror_node must be an involution (mirror(mirror(n))==n), a bijection, and swap the
## two sides (player goal <-> enemy goal, entrances). Checked on every map.

func _initialize() -> void:
	var ok := true
	for layout in MapData.count():
		var m := MapData.new(layout)
		var seen := {}
		for n in m.nodes:
			var id: int = n["id"]
			var mi := m.mirror_node(id)
			if m.mirror_node(mi) != id:
				print("  map %d: mirror not involutive at %d" % [layout, id])
				ok = false
			seen[mi] = (seen.get(mi, 0)) + 1
		# bijection: every node is the mirror of exactly one node
		for n in m.nodes:
			if int(seen.get(n["id"], 0)) != 1:
				print("  map %d: not a bijection at %d" % [layout, n["id"]])
				ok = false
				break
		if m.mirror_node(m.goal_player) != m.goal_enemy:
			print("  map %d: goals don't mirror" % layout)
			ok = false
		# entrances swap sides
		var em := m.mirror_node(m.entrances_player[0])
		if em not in m.entrances_enemy:
			print("  map %d: player entrance doesn't mirror to an enemy entrance" % layout)
			ok = false
		print("  map %d (%s): mirror OK=%s" % [layout, MapData.display_name(layout), ok])
	print("MIRROR_OK" if ok else "MIRROR_FAIL")
	quit()
