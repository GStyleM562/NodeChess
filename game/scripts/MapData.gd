extends RefCounted
class_name MapData
## Hand-authored, Pokémon-Duel-style node graph (sparse, with diagonals/crossings).
## Fewer nodes than a grid + low node-degree => surrounding is easy and the board
## reads cleanly. Symmetric top/bottom: player at the BOTTOM (-z), enemy at the TOP.

var nodes := []          # [{id, pos:Vector3, role:String}]
var adj := {}            # id -> Array[int]
var entrances_player := []
var entrances_enemy := []
var goal_player := -1
var goal_enemy := -1
var buffs := []

func _init() -> void:
	_build_duel()

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

func _build_duel() -> void:
	# Player half (bottom, -z) ... CENTER ... Enemy half (top, +z)
	var n0 := _add(Vector3(0.0, 0, -4.0))     # player goal
	var n1 := _add(Vector3(-2.2, 0, -2.8))    # player entrance L
	var n2 := _add(Vector3(2.2, 0, -2.8))     # player entrance R
	var n3 := _add(Vector3(0.0, 0, -2.8))     # player front
	var n4 := _add(Vector3(-1.5, 0, -1.3))    # player mid L
	var n5 := _add(Vector3(1.5, 0, -1.3))     # player mid R
	var n6 := _add(Vector3(0.0, 0, -1.3))     # player center
	var n7 := _add(Vector3(0.0, 0, 0.0))      # CENTER (buff)
	var n8 := _add(Vector3(-1.5, 0, 1.3))     # enemy mid L
	var n9 := _add(Vector3(1.5, 0, 1.3))      # enemy mid R
	var n10 := _add(Vector3(0.0, 0, 1.3))     # enemy center
	var n11 := _add(Vector3(-2.2, 0, 2.8))    # enemy entrance L
	var n12 := _add(Vector3(2.2, 0, 2.8))     # enemy entrance R
	var n13 := _add(Vector3(0.0, 0, 2.8))     # enemy front
	var n14 := _add(Vector3(0.0, 0, 4.0))     # enemy goal

	var edges := [
		[n0, n1], [n0, n2], [n0, n3], [n1, n4], [n2, n5], [n3, n4], [n3, n5],
		[n4, n6], [n5, n6], [n4, n7], [n5, n7], [n6, n7],
		[n14, n11], [n14, n12], [n14, n13], [n11, n8], [n12, n9], [n13, n8], [n13, n9],
		[n8, n10], [n9, n10], [n8, n7], [n9, n7], [n10, n7],
	]
	for e in edges:
		_edge(e[0], e[1])

	goal_player = n0
	goal_enemy = n14
	nodes[n0]["role"] = "goal_player"
	nodes[n14]["role"] = "goal_enemy"
	entrances_player = [n1, n2]
	entrances_enemy = [n11, n12]
	nodes[n1]["role"] = "entrance_player"
	nodes[n2]["role"] = "entrance_player"
	nodes[n11]["role"] = "entrance_enemy"
	nodes[n12]["role"] = "entrance_enemy"
	nodes[n7]["role"] = "buff"
	buffs = [n7]

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
			if dist.has(nb) or blocked.has(nb):
				continue
			dist[nb] = dist[cur] + 1
			q.append(nb)
	dist.erase(start)
	return dist
