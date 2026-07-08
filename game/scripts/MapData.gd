extends RefCounted
class_name MapData
## Hand-authored, Pokémon-Duel-style node graph (sparse, with diagonals/crossings).
## Fewer nodes than a grid + low node-degree => surrounding is easy and the board
## reads cleanly. Symmetric top/bottom: player at the BOTTOM (-z), enemy at the TOP.

## The three playable maps (same rules: goals top/bottom + connected, two entrances
## per side, a buff node, every node <= 3 connections, symmetric left/right).
const NAMES := ["Rieles", "Reloj de Arena", "Plaza", "Túneles", "Cruce"]

var nodes := []          # [{id, pos:Vector3, role:String}]
var adj := {}            # id -> Array[int]
var entrances_player := []
var entrances_enemy := []
var goal_player := -1
var goal_enemy := -1
var buffs := []
var obstacles := []      # impassable node ids (cannot move onto/through)
var teleporters := []    # portal pairs [[a, b], ...] (already linked as graph edges)
## Candados temporales: id -> turn_no en que el nodo se ABRE. Los caminos más
## cortos arrancan cerrados (variedad de aperturas) y se habilitan después.
var locked_until := {}
var map_name := ""

## turn_no cuenta MEDIO-turnos (cada end_turn). 6 ≈ 3 rondas de cada bando.
const LOCK_OPEN_AT := 6

func _init(layout := 0) -> void:
	match layout:
		1:
			_build_hourglass()
		2:
			_build_plaza()
		3:
			_build_duel(true)
		4:
			_build_cross()
		_:
			_build_duel()

static func count() -> int:
	return NAMES.size()

static func display_name(i: int) -> String:
	return NAMES[i] if i >= 0 and i < NAMES.size() else "Mapa %d" % i

func pos_of(id: int) -> Vector3:
	return nodes[id]["pos"]

## The node at the 180°-rotated position (x,z)->(-x,-z). The maps are symmetric under
## this rotation, so this is a bijection swapping the two sides. Online uses it so each
## player can see itself at the bottom (no board flip): an action on my node N is
## applied to the opponent's mirror_node(N).
func mirror_node(id: int) -> int:
	var p: Vector3 = nodes[id]["pos"]
	var best := id
	var bd := 1e9
	for n in nodes:
		var q: Vector3 = n["pos"]
		var d := Vector2(q.x - (-p.x), q.z - (-p.z)).length()
		if d < bd:
			bd = d
			best = int(n["id"])
	return best

func role_of(id: int) -> String:
	return nodes[id]["role"]

## Distancia en nodos entre a y b (BFS por el grafo, saltando obstáculos).
## 99 si no hay ruta. La usa la música de peligro/ventaja ("a N nodos de la meta").
func graph_dist(a: int, b: int) -> int:
	if a == b:
		return 0
	var seen := {a: true}
	var frontier := [a]
	var d := 0
	while not frontier.is_empty():
		d += 1
		var nxt := []
		for id in frontier:
			for nb in adj[id]:
				if seen.has(nb):
					continue
				if nb == b:
					return d
				if nb in obstacles:
					continue
				seen[nb] = true
				nxt.append(nb)
		frontier = nxt
	return 99

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
	# v4 — UNA FILA MÁS: rieles con nodo medio + centro en columna (evita ganar
	# en 2 turnos: mínimo entrada->meta rival = 7 por riel, 8 por el centro).
	var nL := _add(Vector3(-2.85, 0, 0.0))    # rail L mid (candado inicial)
	var nR := _add(Vector3(2.85, 0, 0.0))     # rail R mid (candado inicial)
	var cA := _add(Vector3(0.0, 0, -0.5))     # centro bajo
	var cB := _add(Vector3(0.0, 0, 0.5))      # centro alto

	var edges := [
		# goals (each degree 3)
		[n0, n1], [n0, n2], [n0, n3], [n19, n16], [n19, n17], [n19, n18],
		# bottom / top centre branch to the inner nodes
		[n3, n8], [n3, n9], [n16, n10], [n16, n11],
		# LONG left rail (ahora con nodo medio): PeL-L1-L2-Lmid-L3-L4-EeL
		[n1, n4], [n4, n6], [n6, nL], [nL, n12], [n12, n14], [n14, n17],
		# LONG right rail: PeR-R1-R2-Rmid-R3-R4-EeR
		[n2, n5], [n5, n7], [n7, nR], [nR, n13], [n13, n15], [n15, n18],
		# inner nodes hook into the rails
		[n8, n4], [n9, n5], [n10, n14], [n11, n15],
		# columna central (automórfica al espejo 180°: mirror(cA)=cB,
		# mirror(n8)=n11, mirror(n9)=n10 -> cada arista tiene su gemela)
		[n8, cA], [n9, cA], [cA, cB], [cB, n10], [cB, n11],
	]
	for e in edges:
		_edge(e[0], e[1])

	# candado inicial: los nodos medios del riel (el camino más corto) abren
	# en el turno LOCK_OPEN_AT — al inicio se pelea por el centro.
	locked_until = {nL: LOCK_OPEN_AT, nR: LOCK_OPEN_AT}

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

## Shared layout (antes 16 nodos, hoy 16+6): columna central en vez del cruce en
## X (mínimo entrada->meta = 7) y rieles laterales completos con nodos medios
## CANDADEADOS al inicio (abren en LOCK_OPEN_AT; luego el riel cuesta 6).
## `P` = 16 posiciones base, `bf` = buff node ids. Topología fija por mapa.
func _build_x16(mname: String, P: Array, bf: Array) -> void:
	map_name = mname
	for p in P:
		_add(p)
	# UNA FILA MÁS: centro (cA/cB) + rieles medios por lado (rl1/rl2, rr1/rr2).
	var zc: float = absf((P[6] as Vector3).z) * 0.45
	var zr: float = absf((P[4] as Vector3).z) * 0.35
	var xl: float = (P[4] as Vector3).x
	var xr: float = (P[5] as Vector3).x
	var cA := _add(Vector3(0, 0, -zc))         # 16 centro bajo
	var cB := _add(Vector3(0, 0, zc))          # 17 centro alto
	var rl1 := _add(Vector3(xl, 0, -zr))       # 18 riel L bajo (candado)
	var rl2 := _add(Vector3(xl, 0, zr))        # 19 riel L alto (candado)
	var rr1 := _add(Vector3(xr, 0, -zr))       # 20 riel R bajo (candado)
	var rr2 := _add(Vector3(xr, 0, zr))        # 21 riel R alto (candado)
	var edges := [
		[0, 1], [0, 2], [0, 3], [15, 13], [15, 14], [15, 12],
		[1, 4], [2, 5], [3, 6], [3, 7], [12, 8], [12, 9],
		[4, 6], [5, 7], [8, 10], [9, 11],
		[10, 13], [11, 14], [13, 15], [14, 15],
		# columna central automórfica (mirror: 6<->9, 7<->8, cA<->cB)
		[6, cA], [7, cA], [cA, cB], [cB, 8], [cB, 9],
		# rieles laterales (mirror: 4<->11, 5<->10, rl1<->rr2, rl2<->rr1)
		[4, rl1], [rl1, rl2], [rl2, 10], [5, rr1], [rr1, rr2], [rr2, 11],
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
	# los rieles (el camino más corto una vez abiertos) arrancan con candado
	locked_until = {rl1: LOCK_OPEN_AT, rl2: LOCK_OPEN_AT, rr1: LOCK_OPEN_AT, rr2: LOCK_OPEN_AT}

func _build_hourglass() -> void:
	# Tall, pinched in the middle — short side lanes, tight centre (easy surrounds).
	_build_x16(NAMES[1], [
		Vector3(0, 0, -5.7), Vector3(-2.9, 0, -4.2), Vector3(2.9, 0, -4.2), Vector3(0, 0, -4.2),
		Vector3(-2.9, 0, -2.3), Vector3(2.9, 0, -2.3), Vector3(-1.2, 0, -1.1), Vector3(1.2, 0, -1.1),
		Vector3(-1.2, 0, 1.1), Vector3(1.2, 0, 1.1), Vector3(-2.9, 0, 2.3), Vector3(2.9, 0, 2.3),
		Vector3(0, 0, 4.2), Vector3(-2.9, 0, 4.2), Vector3(2.9, 0, 4.2), Vector3(0, 0, 5.7),
	], [6, 9])

func _build_cross() -> void:
	# Cruce — ancho y alto: rieles muy abiertos (±3.1) e interior amplio (±1.8).
	# Misma topología x16+6 (columna central + rieles con candado), otra geometría.
	_build_x16(NAMES[4], [
		Vector3(0, 0, -5.4), Vector3(-2.9, 0, -4.0), Vector3(2.9, 0, -4.0), Vector3(0, 0, -4.0),
		Vector3(-3.1, 0, -2.2), Vector3(3.1, 0, -2.2), Vector3(-1.8, 0, -1.0), Vector3(1.8, 0, -1.0),
		Vector3(-1.8, 0, 1.0), Vector3(1.8, 0, 1.0), Vector3(-3.1, 0, 2.2), Vector3(3.1, 0, 2.2),
		Vector3(0, 0, 4.0), Vector3(-2.9, 0, 4.0), Vector3(2.9, 0, 4.0), Vector3(0, 0, 5.4),
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
## impassable (cannot move through or onto them). `pass_terrain` (Hover) ignora
## los obstáculos del mapa al ATRAVESAR (quien llama filtra los destinos finales).
func reachable(start: int, steps: int, blocked: Dictionary = {}, pass_terrain := false) -> Dictionary:
	var dist := {start: 0}
	var q := [start]
	while not q.is_empty():
		var cur: int = q.pop_front()
		if dist[cur] >= steps:
			continue
		for nb in adj[cur]:
			if dist.has(nb) or blocked.has(nb) or (not pass_terrain and obstacles.has(nb)):
				continue
			dist[nb] = dist[cur] + 1
			q.append(nb)
	dist.erase(start)
	return dist

## Shortest node path from `start` to `target` (BFS), as the list of nodes to walk
## THROUGH (excludes start, includes target). `blocked` = impassable node ids.
func path_to(start: int, target: int, blocked: Dictionary = {}, pass_terrain := false) -> Array:
	if start == target:
		return []
	var prev := {start: -1}
	var q := [start]
	while not q.is_empty():
		var cur: int = q.pop_front()
		for nb in adj[cur]:
			if prev.has(nb) or blocked.has(nb) or (not pass_terrain and obstacles.has(nb)):
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
