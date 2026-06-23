extends RefCounted
class_name MapData
## A symmetric node-graph board (MVP). Procedural, data-driven — the rules
## engine and the renderer both read from this. Visual terrain is a cosmetic
## skin added later (GDD Part 2C §14).

var cols: int
var rows: int
var spacing: float
var nodes: Array = []          # [{id, col, row, pos:Vector3, role:String}]
var adj: Dictionary = {}       # id -> Array[int]
var entrances_player: Array = []
var entrances_enemy: Array = []
var goal_player: int = -1
var goal_enemy: int = -1
var buffs: Array = []

func _init(_cols: int = 5, _rows: int = 7, _spacing: float = 1.35) -> void:
	cols = _cols
	rows = _rows
	spacing = _spacing
	_build()

func id_at(c: int, r: int) -> int:
	return r * cols + c

func pos_of(id: int) -> Vector3:
	return nodes[id]["pos"]

## Neighbour node id one step in grid direction (dcol, drow), or -1 if off-board.
func dir_node(id: int, dcol: int, drow: int) -> int:
	var n: Dictionary = nodes[id]
	var nc: int = n["col"] + dcol
	var nr: int = n["row"] + drow
	if nc < 0 or nc >= cols or nr < 0 or nr >= rows:
		return -1
	return id_at(nc, nr)

func role_of(id: int) -> String:
	return nodes[id]["role"]

func _build() -> void:
	var cx := (cols - 1) * 0.5
	var cz := (rows - 1) * 0.5
	for r in rows:
		for c in cols:
			nodes.append({
				"id": id_at(c, r), "col": c, "row": r,
				"pos": Vector3((c - cx) * spacing, 0.0, (r - cz) * spacing),
				"role": "normal",
			})
	# 4-neighbour adjacency (orthogonal) — clean & readable for the first map.
	for r in rows:
		for c in cols:
			var a: Array = []
			for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
				var nc: int = c + d[0]
				var nr: int = r + d[1]
				if nc >= 0 and nc < cols and nr >= 0 and nr < rows:
					a.append(id_at(nc, nr))
			adj[id_at(c, r)] = a
	# Roles (vertically symmetric)
	var mid := int(cols / 2)
	goal_player = id_at(mid, 0)
	goal_enemy = id_at(mid, rows - 1)
	nodes[goal_player]["role"] = "goal_player"
	nodes[goal_enemy]["role"] = "goal_enemy"
	entrances_player = [id_at(0, 0), id_at(cols - 1, 0)]
	entrances_enemy = [id_at(0, rows - 1), id_at(cols - 1, rows - 1)]
	for e in entrances_player:
		nodes[e]["role"] = "entrance_player"
	for e in entrances_enemy:
		nodes[e]["role"] = "entrance_enemy"
	var b := id_at(mid, int(rows / 2))
	nodes[b]["role"] = "buff"
	buffs.append(b)

## BFS reachable distances from `start` up to `steps`, treating `blocked`
## node ids as impassable (cannot move through or onto them).
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
