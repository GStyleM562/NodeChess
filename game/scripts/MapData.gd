extends RefCounted
class_name MapData
## Hand-authored, Pokémon-Duel-style node graph (sparse, with diagonals/crossings).
## Fewer nodes than a grid + low node-degree => surrounding is easy and the board
## reads cleanly. Symmetric top/bottom: player at the BOTTOM (-z), enemy at the TOP.

## The three playable maps (same rules: goals top/bottom + connected, two entrances
## per side, a buff node, every node <= 3 connections, symmetric left/right).
const NAMES := ["Rieles", "Reloj de Arena", "Plaza", "Túneles"]

var nodes := []          # [{id, pos:Vector3, role:String}]
var adj := {}            # id -> Array[int]
var entrances_player := []
var entrances_enemy := []
var goal_player := -1
var goal_enemy := -1
var buffs := []
var obstacles := []      # impassable node ids (cannot move onto/through)
var teleporters := []    # portal pairs [[a, b], ...] (already linked as graph edges)
var map_name := ""

func _init(layout := 0) -> void:
	match layout:
		1:
			_build_hourglass()
		2:
			_build_plaza()
		3:
			_build_duel(true)
		_:
			_build_duel()

static func count() -> int:
	return NAMES.size()

static func display_name(i: int) -> String:
	return NAMES[i] if i >= 0 and i < NAMES.size() else "Mapa %d" % i

func pos_of(id: int) -> Vector3:
	return nodes[id]["pos"]

func role_of(id: int) -> String:
	return nodes[id]["role"]

func _add(pos: Vector3) -> int:
	var id := nodes.size()
	nodes.append({"id": id, "pos": pos, "role": "normal"})
	adj[id] = []
	return id

func _edge(a: int, b: int) -> void:
	if b not in adj[a]:
		adj[a].append(b)
	if a not in adj[b]:
		adj[b].append(a)

func _build_duel(tunnels := false) -> void:
	map_name = NAMES[3] if tunnels else NAMES[0]
	# v3 — Pokémon-Duel philosophy, tall (~5 cols × 8 rows). Long side RAILS,
	# a central X of diagonals (no 4-way hub), connected goals, and EVERY node has
	# at most 3 connections. Player at the bottom (-z), enemy at the top (+z).
	var n0 := _add(Vector3(0.0, 0, -5.7))     # player goal
	var n1 := _add(Vector3(-2.85, 0, -4.2))   # player entrance L (corner)
	var n2 := _add(Vector3(2.85, 0, -4.2))    # player entrance R (corner)
	var n3 := _add(Vector3(0.0, 0, -4.2))     # bottom centre
	var n4 := _add(Vector3(-2.85, 0, -2.6))   # rail L 1
	var n5 := _add(Vector3(2.85, 0, -2.6))    # rail R 1
	var n6 := _add(Vector3(-2.85, 0, -1.05))  # rail L 2
	var n7 := _add(Vector3(2.85, 0, -1.05))   # rail R 2
	var n8 := _add(Vector3(-1.45, 0, -1.05))  # inner L lower
	var n9 := _add(Vector3(1.45, 0, -1.05))   # inner R lower
	var n10 := _add(Vector3(-1.45, 0, 1.05))  # inner L upper
	var n11 := _add(Vector3(1.45, 0, 1.05))   # inner R upper
	var n12 := _add(Vector3(-2.85, 0, 1.05))  # rail L 3
	var n13 := _add(Vector3(2.85, 0, 1.05))   # rail R 3
	var n14 := _add(Vector3(-2.85, 0, 2.6))   # rail L 4
	var n15 := _add(Vector3(2.85, 0, 2.6))    # rail R 4
	var n16 := _add(Vector3(0.0, 0, 4.2))     # top centre
	var n17 := _add(Vector3(-2.85, 0, 4.2))   # enemy entrance L (corner)
	var n18 := _add(Vector3(2.85, 0, 4.2))    # enemy entrance R (corner)
	var n19 := _add(Vector3(0.0, 0, 5.7))     # enemy goal

	var edges := [
		# goals (each degree 3)
		[n0, n1], [n0, n2], [n0, n3], [n19, n16], [n19, n17], [n19, n18],
		# bottom / top centre branch to the inner nodes
		[n3, n8], [n3, n9], [n16, n10], [n16, n11],
		# LONG left rail: PeL-L1-L2-L3-L4-EeL
		[n1, n4], [n4, n6], [n6, n12], [n12, n14], [n14, n17],
		# LONG right rail: PeR-R1-R2-R3-R4-EeR
		[n2, n5], [n5, n7], [n7, n13], [n13, n15], [n15, n18],
		# inner nodes hook into the rails
		[n8, n4], [n9, n5], [n10, n14], [n11, n15],
		# central X (two crossing diagonals; no node at the crossing -> no degree 4)
		[n8, n11], [n9, n10],
	]
	for e in edges:
		_edge(e[0], e[1])

	goal_player = n0
	goal_enemy = n19
	nodes[n0]["role"] = "goal_player"
	nodes[n19]["role"] = "goal_enemy"
	entrances_player = [n1, n2]
	entrances_enemy = [n17, n18]
	nodes[n1]["role"] = "entrance_player"
	nodes[n2]["role"] = "entrance_player"
	nodes[n17]["role"] = "entrance_enemy"
	nodes[n18]["role"] = "entrance_enemy"
	# buff at an inner node (no central hub node exists now)
	nodes[n8]["role"] = "buff"
	buffs = [n8]

	if tunnels:
		# TELEPORTER portal: a graph edge linking two far nodes (a shortcut/portal).
		_edge(n6, n13)
		nodes[n6]["role"] = "teleporter"
		nodes[n13]["role"] = "teleporter"
		teleporters = [[n6, n13]]
		# OBSTACLE: an impassable node (the bottom-centre branch is sealed off).
		nodes[n3]["role"] = "obstacle"
		obstacles = [n3]

## Shared 16-node layout: an X of crossing diagonals (no node at the crossing, so
## no degree-4 hub), 2 entrances per side, goals top/bottom. `P` = 16 positions,
## `bf` = buff node ids. Topology is fixed; geometry/buffs vary per map.
func _build_x16(mname: String, P: Array, bf: Array) -> void:
	map_name = mname
	for p in P:
		_add(p)
	var edges := [
		[0, 1], [0, 2], [0, 3], [15, 13], [15, 14], [15, 12],
		[1, 4], [2, 5], [3, 6], [3, 7], [12, 8], [12, 9],
		[4, 6], [5, 7], [6, 9], [7, 8], [8, 10], [9, 11],
		[10, 13], [11, 14], [13, 15], [14, 15],
	]
	for e in edges:
		_edge(e[0], e[1])
	goal_player = 0
	goal_enemy = 15
	nodes[0]["role"] = "goal_player"
	nodes[15]["role"] = "goal_enemy"
	entrances_player = [1, 2]
	entrances_enemy = [13, 14]
	nodes[1]["role"] = "entrance_player"
	nodes[2]["role"] = "entrance_player"
	nodes[13]["role"] = "entrance_enemy"
	nodes[14]["role"] = "entrance_enemy"
	for b in bf:
		nodes[b]["role"] = "buff"
	buffs = bf

func _build_hourglass() -> void:
	# Tall, pinched in the middle — short side lanes, tight centre (easy surrounds).
	_build_x16(NAMES[1], [
		Vector3(0, 0, -5.7), Vector3(-2.9, 0, -4.2), Vector3(2.9, 0, -4.2), Vector3(0, 0, -4.2),
		Vector3(-2.9, 0, -2.3), Vector3(2.9, 0, -2.3), Vector3(-1.2, 0, -1.1), Vector3(1.2, 0, -1.1),
		Vector3(-1.2, 0, 1.1), Vector3(1.2, 0, 1.1), Vector3(-2.9, 0, 2.3), Vector3(2.9, 0, 2.3),
		Vector3(0, 0, 4.2), Vector3(-2.9, 0, 4.2), Vector3(2.9, 0, 4.2), Vector3(0, 0, 5.7),
	], [6, 9])

func _build_plaza() -> void:
	# Shorter and rounder — wider inner ring, faster games, more open centre.
	_build_x16(NAMES[2], [
		Vector3(0, 0, -4.9), Vector3(-2.9, 0, -3.6), Vector3(2.9, 0, -3.6), Vector3(0, 0, -3.6),
		Vector3(-2.9, 0, -1.5), Vector3(2.9, 0, -1.5), Vector3(-1.7, 0, -0.8), Vector3(1.7, 0, -0.8),
		Vector3(-1.7, 0, 0.8), Vector3(1.7, 0, 0.8), Vector3(-2.9, 0, 1.5), Vector3(2.9, 0, 1.5),
		Vector3(0, 0, 3.6), Vector3(-2.9, 0, 3.6), Vector3(2.9, 0, 3.6), Vector3(0, 0, 4.9),
	], [7, 8])

## BFS reachable distances from `start` up to `steps`, treating `blocked` ids as
## impassable (cannot move through or onto them).
func reachable(start: int, steps: int, blocked: Dictionary = {}) -> Dictionary:
	var dist := {start: 0}
	var q := [start]
	while not q.is_empty():
		var cur: int = q.pop_front()
		if dist[cur] >= steps:
			continue
		for nb in adj[cur]:
			if dist.has(nb) or blocked.has(nb) or obstacles.has(nb):
				continue
			dist[nb] = dist[cur] + 1
			q.append(nb)
	dist.erase(start)
	return dist

## Shortest node path from `start` to `target` (BFS), as the list of nodes to walk
## THROUGH (excludes start, includes target). `blocked` = impassable node ids.
func path_to(start: int, target: int, blocked: Dictionary = {}) -> Array:
	if start == target:
		return []
	var prev := {start: -1}
	var q := [start]
	while not q.is_empty():
		var cur: int = q.pop_front()
		for nb in adj[cur]:
			if prev.has(nb) or blocked.has(nb) or obstacles.has(nb):
				continue
			prev[nb] = cur
			if nb == target:
				var path := []
				var n := target
				while n != start:
					path.push_front(n)
					n = int(prev[n])
				return path
			q.append(nb)
	return [target]   # fallback (shouldn't happen for a reachable target)
