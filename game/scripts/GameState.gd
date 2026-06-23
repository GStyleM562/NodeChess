extends RefCounted
class_name GameState
## Pure rules engine (no nodes / no rendering) for Layer 1:
## bench + deploy from entrances, alternating 1-action turns (deploy/move/attack),
## wheel combat (Combat.gd), KO -> KO bench, goal victory, and a simple bot.
## Surround KO, rank up, energy/modifiers come in later layers.

var map: MapData
var units := {}                                   # uid -> {uid,rindex,team,node,stamina,alive}
var board := {}                                    # node_id -> uid
var bench := {"player": [], "enemy": []}           # uid arrays (not yet deployed)
var ko_bench := {"player": [], "enemy": []}        # uid arrays (defeated)
var turn_team := "player"
var winner := ""
var _next_uid := 0

func _init(_map: MapData) -> void:
	map = _map

func add_to_bench(team: String, rindex: int) -> int:
	var uid := _next_uid
	_next_uid += 1
	units[uid] = {
		"uid": uid, "rindex": rindex, "team": team, "node": -1,
		"stamina": int(Roster.FIGURES[rindex].get("stamina", 2)), "alive": true,
	}
	bench[team].append(uid)
	return uid

# --- queries ---------------------------------------------------------------
func entrances(team: String) -> Array:
	return map.entrances_player if team == "player" else map.entrances_enemy

func free_entrances(team: String) -> Array:
	var out := []
	for e in entrances(team):
		if not board.has(e):
			out.append(e)
	return out

func can_deploy(team: String) -> bool:
	return bench[team].size() > 0 and free_entrances(team).size() > 0

func units_on_board(team: String) -> Array:
	var out := []
	for nid in board.keys():
		if units[board[nid]]["team"] == team:
			out.append(board[nid])
	return out

func can_act(team: String) -> bool:
	return units_on_board(team).size() > 0 or can_deploy(team)

func reachable_for(uid: int) -> Dictionary:
	var u: Dictionary = units[uid]
	var blocked := {}
	for nid in board.keys():
		if nid != u["node"]:
			blocked[nid] = true
	return map.reachable(u["node"], u["stamina"], blocked)

func adjacent_enemies(uid: int) -> Array:
	var u: Dictionary = units[uid]
	var out := []
	for nb in map.adj[u["node"]]:
		if board.has(nb) and units[board[nb]]["team"] != u["team"]:
			out.append(board[nb])
	return out

# --- actions ---------------------------------------------------------------
func deploy(uid: int, node: int) -> void:
	var u: Dictionary = units[uid]
	bench[u["team"]].erase(uid)
	u["node"] = node
	board[node] = uid
	_check_goal(u)

func move_unit(uid: int, node: int) -> void:
	var u: Dictionary = units[uid]
	board.erase(u["node"])
	u["node"] = node
	board[node] = uid
	_check_goal(u)

## Resolve an attack. Returns the combat record for the view to animate.
func attack(att_uid: int, def_uid: int) -> Dictionary:
	var a: Dictionary = units[att_uid]
	var d: Dictionary = units[def_uid]
	var seg_a := Combat.roll(Roster.FIGURES[a["rindex"]]["attack"])
	var seg_b := Combat.roll(Roster.FIGURES[d["rindex"]]["attack"])
	var r := Combat.resolve(seg_a, seg_b)
	var ko_uid := -1
	if r > 0:
		ko_uid = def_uid
	elif r < 0:
		ko_uid = att_uid
	if ko_uid != -1:
		_ko(ko_uid)
	return {"att": att_uid, "def": def_uid, "seg_a": seg_a, "seg_b": seg_b, "result": r, "ko": ko_uid}

func _ko(uid: int) -> void:
	var u: Dictionary = units[uid]
	u["alive"] = false
	if u["node"] >= 0 and board.get(u["node"]) == uid:
		board.erase(u["node"])
	u["node"] = -1
	ko_bench[u["team"]].append(uid)

func _check_goal(u: Dictionary) -> void:
	var goal: int = map.goal_enemy if u["team"] == "player" else map.goal_player
	if u["node"] == goal:
		winner = u["team"]

func end_turn() -> void:
	turn_team = "enemy" if turn_team == "player" else "player"
	# Win if the side to move cannot act at all.
	if winner == "" and not can_act(turn_team):
		winner = "enemy" if turn_team == "player" else "player"

# --- simple bot ------------------------------------------------------------
## Takes ONE legal action for `team`. Returns a record the view can animate.
func bot_action(team: String) -> Dictionary:
	# 1) Deploy until a few are out.
	if can_deploy(team) and units_on_board(team).size() < 3:
		var uid: int = bench[team][0]
		var node: int = free_entrances(team)[0]
		deploy(uid, node)
		return {"type": "deploy", "uid": uid, "node": node}
	# 2) Attack if adjacent to an enemy.
	for uid in units_on_board(team):
		var foes := adjacent_enemies(uid)
		if foes.size() > 0:
			var rec := attack(uid, foes[0])
			rec["type"] = "attack"
			return rec
	# 3) Move toward the enemy goal (creates pressure -> combat).
	var goal_node: int = map.goal_enemy if team == "player" else map.goal_player
	var gp := map.pos_of(goal_node)
	for uid in units_on_board(team):
		var reach := reachable_for(uid)
		if reach.is_empty():
			continue
		var best := -1
		var best_d := INF
		for nid in reach.keys():
			var dd := map.pos_of(nid).distance_to(gp)
			if dd < best_d:
				best_d = dd
				best = nid
		if best != -1:
			move_unit(uid, best)
			return {"type": "move", "uid": uid, "node": best}
	return {"type": "pass"}
