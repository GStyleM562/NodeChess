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
	# v2.0 — modelled on the Pokémon Duel standard board:
	# 4 corner entrances, goals at top/bottom centre (beyond the corners), left/right
	# rails, and a central X of diagonals. Player at the bottom (-z), enemy at the top.
	var n0 := _add(Vector3(0.0, 0, -4.5))     # player goal
	var n1 := _add(Vector3(-2.6, 0, -3.0))    # player entrance L (corner)
	var n2 := _add(Vector3(2.6, 0, -3.0))     # player entrance R (corner)
	var n3 := _add(Vector3(-1.3, 0, -3.0))    # bottom inner L
	var n4 := _add(Vector3(1.3, 0, -3.0))     # bottom inner R
	var n5 := _add(Vector3(-2.6, 0, -1.5))    # rail L lower
	var n6 := _add(Vector3(2.6, 0, -1.5))     # rail R lower
	var n7 := _add(Vector3(-1.3, 0, -1.5))    # centre-left lower
	var n8 := _add(Vector3(1.3, 0, -1.5))     # centre-right lower
	var n9 := _add(Vector3(0.0, 0, 0.0))      # CENTER (buff)
	var n10 := _add(Vector3(-1.3, 0, 1.5))    # centre-left upper
	var n11 := _add(Vector3(1.3, 0, 1.5))     # centre-right upper
	var n12 := _add(Vector3(-2.6, 0, 1.5))    # rail L upper
	var n13 := _add(Vector3(2.6, 0, 1.5))     # rail R upper
	var n14 := _add(Vector3(-1.3, 0, 3.0))    # top inner L
	var n15 := _add(Vector3(1.3, 0, 3.0))     # top inner R
	var n16 := _add(Vector3(-2.6, 0, 3.0))    # enemy entrance L (corner)
	var n17 := _add(Vector3(2.6, 0, 3.0))     # enemy entrance R (corner)
	var n18 := _add(Vector3(0.0, 0, 4.5))     # enemy goal

	var edges := [
		# player goal + bottom edge
		[n0, n1], [n0, n2], [n0, n3], [n0, n4], [n1, n3], [n3, n4], [n4, n2],
		# rails down->mid, inner down->mid
		[n1, n5], [n2, n6], [n3, n7], [n4, n8],
		[n5, n7], [n6, n8],
		# rails through to the upper half (flanking routes)
		[n5, n12], [n6, n13],
		# central X (two crossing diagonals through the centre)
		[n7, n9], [n8, n9], [n9, n10], [n9, n11],
		# enemy half (mirror)
		[n10, n12], [n11, n13], [n10, n14], [n11, n15],
		[n12, n16], [n13, n17],
		[n14, n16], [n14, n15], [n15, n17],
		[n18, n16], [n18, n17], [n18, n14], [n18, n15],
	]
	for e in edges:
		_edge(e[0], e[1])

	goal_player = n0
	goal_enemy = n18
	nodes[n0]["role"] = "goal_player"
	nodes[n18]["role"] = "goal_enemy"
	entrances_player = [n1, n2]
	entrances_enemy = [n16, n17]
	nodes[n1]["role"] = "entrance_player"
	nodes[n2]["role"] = "entrance_player"
	nodes[n16]["role"] = "entrance_enemy"
	nodes[n17]["role"] = "entrance_enemy"
	nodes[n9]["role"] = "buff"
	buffs = [n9]

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
