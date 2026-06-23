extends RefCounted
class_name GameState
## Pure rules engine (no nodes). Layer 1 + combat effects:
## bench + deploy from entrances, alternating 1-action turns, move, wheel combat,
## STATUS EFFECTS (fear/weakened/immobilized/paralysis) applied on a Purple win,
## DISPLACEMENT (push/pull/swap) on a displacing win, KO -> KO bench, goal victory,
## secondary victory (no board figures AND cannot deploy), and a simple bot.
## Surround KO + KO-bench return come next.

# Purple effect label (segment "fx") -> status id.
const FX_STATUS := {"Miedo": "fear", "Debilitado": "weakened", "Paralizado": "paralysis", "Inmovilizado": "immobilized"}
const STATUS_DUR := 4   # in game-turns (~2 rounds)
const KO_COOLDOWN := 6  # game-turns before a KO'd figure returns to the bench

var map: MapData
var units := {}
var board := {}
var bench := {"player": [], "enemy": []}
var ko_bench := {"player": [], "enemy": []}
var turn_team := "player"
var turn_no := 0
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
		"statuses": {},
	}
	bench[team].append(uid)
	return uid

# --- statuses --------------------------------------------------------------
func apply_status(uid: int, s: String, dur: int = STATUS_DUR) -> void:
	units[uid]["statuses"][s] = turn_no + dur

func has_status(uid: int, s: String) -> bool:
	var st: Dictionary = units[uid]["statuses"]
	return st.has(s) and turn_no <= int(st[s])

func status_list(uid: int) -> Array:
	var out := []
	for s in units[uid]["statuses"].keys():
		if turn_no <= int(units[uid]["statuses"][s]):
			out.append(s)
	return out

func can_move(uid: int) -> bool:
	return not has_status(uid, "immobilized") and not has_status(uid, "paralysis")

func can_attack(uid: int) -> bool:
	return not has_status(uid, "fear") and not has_status(uid, "paralysis")

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

## Secondary defeat: a side that has no figures on the board AND cannot deploy
## (entrances blocked or nothing to deploy) cannot act.
func can_act(team: String) -> bool:
	return units_on_board(team).size() > 0 or can_deploy(team)

func reachable_for(uid: int) -> Dictionary:
	if not can_move(uid):
		return {}
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

# --- surround KO -----------------------------------------------------------
## KO by surround when EVERY adjacent node is occupied by an ENEMY figure (no
## empty escape, no friendly neighbour). Edges count: a corner figure needs only
## its (fewer) neighbours filled by enemies.
func is_surrounded(uid: int) -> bool:
	var u: Dictionary = units[uid]
	if u["node"] < 0:
		return false
	var nbs: Array = map.adj[u["node"]]
	if nbs.is_empty():
		return false
	for nb in nbs:
		if not board.has(nb):
			return false
		if units[board[nb]]["team"] == u["team"]:
			return false
	return true

## KO every surrounded figure (evaluated simultaneously). Returns the KO'd uids.
func check_surround() -> Array:
	var koed := []
	for uid in board.values():
		if units[uid]["alive"] and is_surrounded(uid):
			koed.append(uid)
	for uid in koed:
		_ko(uid)
	return koed

## KO'd figures return to their bench after a cooldown (redeployable from a free
## entrance — so blocking entrances matters for a secondary victory).
func _process_ko_returns() -> void:
	for team in ["player", "enemy"]:
		for uid in ko_bench[team].duplicate():
			if turn_no >= int(units[uid].get("ko_until", 0)):
				ko_bench[team].erase(uid)
				units[uid]["alive"] = true
				units[uid]["statuses"] = {}
				units[uid]["node"] = -1
				bench[team].append(uid)

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

func _roll_for(uid: int) -> Dictionary:
	var s: Dictionary = Combat.roll(Roster.FIGURES[units[uid]["rindex"]]["attack"]).duplicate(true)
	if has_status(uid, "weakened"):
		if s.has("pow"):
			s["pow"] = maxi(0, int(s["pow"]) - 20)
		if s.has("stars"):
			s["stars"] = maxi(1, int(s["stars"]) - 1)
	return s

## Resolve an attack. KO only on a damage (White/Gold) win. Purple win applies a
## status (and/or displacement); Blue win blocks. Returns the combat record.
func attack(att_uid: int, def_uid: int) -> Dictionary:
	var seg_a := _roll_for(att_uid)
	var seg_b := _roll_for(def_uid)
	var oc := Combat.outcome(seg_a, seg_b)
	var ko_uid := -1
	var applied := {}
	var disp := {}
	if oc["ko"]:
		ko_uid = def_uid if int(oc["result"]) > 0 else att_uid
		_ko(ko_uid)
	elif int(oc["result"]) != 0:
		var winner_uid: int = att_uid if int(oc["result"]) > 0 else def_uid
		var loser_uid: int = def_uid if int(oc["result"]) > 0 else att_uid
		var ws: Dictionary = oc["win_seg"]
		var fx := String(ws.get("fx", ""))
		if FX_STATUS.has(fx):
			apply_status(loser_uid, FX_STATUS[fx], STATUS_DUR)
			applied = {"status": FX_STATUS[fx], "target": loser_uid, "fx": fx}
		if ws.has("disp"):
			disp = _apply_displacement(winner_uid, loser_uid, ws)
	return {
		"att": att_uid, "def": def_uid, "seg_a": seg_a, "seg_b": seg_b,
		"result": int(oc["result"]), "win_col": oc["win_col"], "effect": oc["effect"],
		"ko": ko_uid, "status": applied, "disp": disp,
	}

func _apply_displacement(winner_uid: int, loser_uid: int, seg: Dictionary) -> Dictionary:
	var w: Dictionary = units[winner_uid]
	var l: Dictionary = units[loser_uid]
	var typ := String(seg.get("disp", ""))
	if typ == "swap":
		var wn: int = w["node"]
		var ln: int = l["node"]
		board[ln] = winner_uid
		board[wn] = loser_uid
		w["node"] = ln
		l["node"] = wn
		_check_goal(w)
		_check_goal(l)
		return {"type": "swap", "a": winner_uid, "a_to": ln, "b": loser_uid, "b_to": wn}
	# push / pull
	var wc: int = map.nodes[w["node"]]["col"]
	var wr: int = map.nodes[w["node"]]["row"]
	var lc: int = map.nodes[l["node"]]["col"]
	var lr: int = map.nodes[l["node"]]["row"]
	var dcol: int
	var drow: int
	if typ == "push":
		dcol = signi(lc - wc)
		drow = signi(lr - wr)
	else:
		dcol = signi(wc - lc)
		drow = signi(wr - lr)
	var steps := int(seg.get("n", 1))
	var cur: int = l["node"]
	for i in steps:
		var nxt := map.dir_node(cur, dcol, drow)
		if nxt == -1 or board.has(nxt):
			break
		board.erase(cur)
		cur = nxt
		board[cur] = loser_uid
		l["node"] = cur
	_check_goal(l)
	return {"type": typ, "uid": loser_uid, "to": l["node"]}

func _ko(uid: int) -> void:
	var u: Dictionary = units[uid]
	u["alive"] = false
	u["statuses"] = {}
	u["ko_until"] = turn_no + KO_COOLDOWN
	if u["node"] >= 0 and board.get(u["node"]) == uid:
		board.erase(u["node"])
	u["node"] = -1
	ko_bench[u["team"]].append(uid)

func _check_goal(u: Dictionary) -> void:
	var goal: int = map.goal_enemy if u["team"] == "player" else map.goal_player
	if u["node"] == goal:
		winner = u["team"]

func end_turn() -> void:
	turn_no += 1
	_process_ko_returns()
	turn_team = "enemy" if turn_team == "player" else "player"
	if winner == "" and not can_act(turn_team):
		winner = "enemy" if turn_team == "player" else "player"

# --- simple bot ------------------------------------------------------------
func bot_action(team: String) -> Dictionary:
	if can_deploy(team) and units_on_board(team).size() < 3:
		var uid: int = bench[team][0]
		var node: int = free_entrances(team)[0]
		deploy(uid, node)
		return {"type": "deploy", "uid": uid, "node": node}
	for uid in units_on_board(team):
		if can_attack(uid):
			var foes := adjacent_enemies(uid)
			if foes.size() > 0:
				var rec := attack(uid, foes[0])
				rec["type"] = "attack"
				return rec
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
