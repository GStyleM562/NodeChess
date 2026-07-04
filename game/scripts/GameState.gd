extends RefCounted
class_name GameState
## Pure rules engine (no nodes). Layer 1 + combat effects:
## bench + deploy from entrances, alternating 1-action turns, move, wheel combat,
## STATUS EFFECTS (fear/weakened/immobilized/paralysis) applied on a Purple win,
## DISPLACEMENT (push/pull/swap) on a displacing win, KO -> KO bench, goal victory,
## secondary victory (no board figures AND cannot deploy), and a simple bot.
## Surround KO + KO-bench return come next.

# Purple effect label (segment "fx") -> status id. Designers set "fx" on a segment;
# winning Purple applies the mapped status. The full status library (GDD §29):
const FX_STATUS := {
	"Miedo": "fear", "Debilitado": "weakened", "Paralizado": "paralysis", "Inmovilizado": "immobilized",
	"Quemadura": "burn", "Veneno": "poison", "Congelado": "freeze", "Silencio": "silence",
	"Confusión": "confusion", "Sueño": "sleep", "Maldición": "curse", "Marcado": "marked",
	"Escudo Roto": "shield_break",
}
const STATUS_DUR := 4   # default status length, in game-turns (~2 rounds)
const KO_COOLDOWN := 6  # game-turns before a KO'd figure returns to the bench
# Damage-over-time statuses KO the figure when their timer elapses (unless cleansed
# by Rank Up / the Cleanse modifier). There is no HP, so the timer IS the lethality.
const BURN_TURNS := 6     # Quemadura: faster, also weakens the burning unit's damage
const POISON_TURNS := 8   # Veneno: slower, stealthier
const BURN_DMG_PEN := 10  # Burn shaves this much power off the burning unit's rolls

# --- Plan B: energy + modifiers + buff nodes -------------------------------
const ENERGY_MAX := 10
const ENERGY_PER_TURN := 1
const BUFF_ENERGY := 1     # extra energy/turn for controlling a buff node
const BUFF_DMG := 20       # combat bonus for a unit standing on a buff node
const BUFF_STARS := 1
## Modifier cards: spend energy to activate. Equipped per player (see Loadout).
const MODIFIERS := {
	"power_surge": {"name": "Power Surge", "cost": 3, "desc": "Tu próximo ataque: +20 daño / +1★"},
	"fury": {"name": "Fury", "cost": 5, "desc": "Tu próximo ataque: +40 daño / +2★"},
	"cleanse": {"name": "Cleanse", "cost": 2, "desc": "Quita los debuffs de tus figuras"},
	"adrenaline": {"name": "Adrenaline", "cost": 2, "desc": "Tu próximo ataque repite un Fallo"},
}

var map: MapData
var units := {}
var board := {}
var bench := {"player": [], "enemy": []}
var ko_bench := {"player": [], "enemy": []}
var turn_team := "player"
var turn_no := 0
var winner := ""
var energy := {"player": 0, "enemy": 0}
var pending_buff := {"player": {}, "enemy": {}}   # one-shot combat buffs from modifiers
var mod_used := {"player": false, "enemy": false} # one modifier per turn
var _att_moved_ctx := 0                           # nodes the attacker moved this turn (for Lunge/Dive)
var _next_uid := 0

func _init(_map: MapData) -> void:
	map = _map

func add_to_bench(team: String, rindex: int) -> int:
	var uid := _next_uid
	_next_uid += 1
	units[uid] = {
		"uid": uid, "rindex": rindex, "team": team, "node": -1,
		"stamina": int(Roster.FIGURES[rindex].get("stamina", 2)), "alive": true,
		"statuses": {}, "rank": 0,
	}
	bench[team].append(uid)
	return uid

# --- statuses --------------------------------------------------------------
## dur < 0 → use the status' own default length (DOTs last longer than debuffs).
func apply_status(uid: int, s: String, dur: int = -1) -> void:
	units[uid]["statuses"][s] = turn_no + (dur if dur >= 0 else _status_dur(s))

func _status_dur(s: String) -> int:
	match s:
		"burn": return BURN_TURNS
		"poison": return POISON_TURNS
		_: return STATUS_DUR

func has_status(uid: int, s: String) -> bool:
	var st: Dictionary = units[uid]["statuses"]
	return st.has(s) and turn_no <= int(st[s])

func status_list(uid: int) -> Array:
	var out := []
	for s in units[uid]["statuses"].keys():
		if turn_no <= int(units[uid]["statuses"][s]):
			out.append(s)
	return out

## Frozen, Asleep and Paralyzed root the figure; Immobilized too.
func can_move(uid: int) -> bool:
	for s in ["immobilized", "paralysis", "freeze", "sleep"]:
		if has_status(uid, s):
			return false
	return true

## Feared, Frozen, Asleep and Paralyzed figures cannot attack.
func can_attack(uid: int) -> bool:
	for s in ["fear", "paralysis", "freeze", "sleep"]:
		if has_status(uid, s):
			return false
	return true

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
	return move_targets(uid, effective_stamina(uid))

## All nodes this unit can reach with `budget` stamina (node -> cost). Includes
## JUMPS: with >= 2 stamina, a unit standing next to an enemy may hop OVER it,
## landing on a free node just beyond the enemy (passing through the enemy's node).
## A jump costs 2 stamina. Any figure with enough stamina can do this.
## Phase / Aerial: this figure walks THROUGH other figures (but still can't land on
## an occupied node, and terrain still blocks).
func _can_phase(uid: int) -> bool:
	return has_passive(uid, "phase") or has_passive(uid, "aerial")

## Nodo con CANDADO temporal (camino corto cerrado los primeros turnos).
func node_locked(nid: int) -> bool:
	return turn_no < int(map.locked_until.get(nid, 0))

## Suma al dict `d` los nodos aún candadeados (intransitables por ahora).
func _add_locked(d: Dictionary) -> Dictionary:
	for nid in map.locked_until.keys():
		if node_locked(int(nid)):
			d[int(nid)] = true
	return d

func move_targets(uid: int, budget: int) -> Dictionary:
	if not can_move(uid) or budget <= 0:
		return {}
	var u: Dictionary = units[uid]
	var phasing := _can_phase(uid)
	var blocked := _add_locked({})
	if not phasing:
		for nid in board.keys():
			if nid != u["node"]:
				blocked[nid] = true
	var reach := map.reachable(u["node"], budget, blocked)
	reach.erase(u["node"])
	if phasing:
		# Pass-through: cannot END on an occupied node, but keeps moving / may attack.
		for nid in board.keys():
			reach.erase(nid)
		return reach
	# JUMP over ONE adjacent enemy (cost 2; ends the turn, no attack). A basic jump is
	# allowed only as a FIRST action; jumping AFTER moving needs the PARKOUR passive.
	var can_jump := budget >= 2 and (budget >= effective_stamina(uid) or has_passive(uid, "parkour"))
	if can_jump:
		for e in map.adj[u["node"]]:
			var occ := int(board.get(e, -1))
			if occ == -1 or units[occ]["team"] == u["team"] or not units[occ]["alive"]:
				continue                                  # only hop over a live enemy
			for f in map.adj[e]:
				if f == u["node"] or board.has(f) or f in map.obstacles or node_locked(f):
					continue                              # land on a free, walkable node beyond it
				if not reach.has(f) or int(reach[f]) > 2:
					reach[f] = 2                          # a jump costs 2 stamina (one enemy only)
	return reach

## Walking path (excluding start) to a target — the shorter of the normal route and
## a jump (hop over an adjacent enemy: [enemy_node, target]).
func move_path(uid: int, target: int) -> Array:
	var u: Dictionary = units[uid]
	var phasing := _can_phase(uid)
	var blocked := _add_locked({})
	if not phasing:
		for nid in board.keys():
			if nid != u["node"]:
				blocked[nid] = true
	var normal := map.path_to(u["node"], target, blocked)
	if phasing:
		return normal                                     # walks straight through figures
	var jump: Array = []
	for e in map.adj[u["node"]]:
		var occ := int(board.get(e, -1))
		if occ != -1 and units[occ]["team"] != u["team"] and units[occ]["alive"] and target in map.adj[e]:
			jump = [e, target]                            # hop over the enemy
			break
	if normal.is_empty():
		return jump
	if jump.is_empty():
		return normal
	return jump if jump.size() < normal.size() else normal

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
## SOLO se despliega desde la BANCA y hacia un nodo libre. Sin este candado, un
## redespliegue de una figura ya en el tablero dejaba su casilla vieja ocupada
## para siempre (ocupación fantasma que bloqueaba movimientos "sin razón").
func deploy(uid: int, node: int) -> void:
	var u: Dictionary = units[uid]
	if not (uid in bench[u["team"]]) or board.has(node):
		return
	bench[u["team"]].erase(uid)
	u["node"] = node
	board[node] = uid
	_check_goal(u)

## Mueve una figura. JAMÁS apila: si el destino está ocupado por otra figura
## (p.ej. una acción remota desincronizada), se rechaza y devuelve false.
func move_unit(uid: int, node: int) -> bool:
	if board.has(node) and int(board[node]) != uid:
		return false
	var u: Dictionary = units[uid]
	board.erase(u["node"])
	u["node"] = node
	board[node] = uid
	_check_goal(u)
	return true

## Auditoría: el tablero es consistente si board <-> units es un mapeo 1:1
## (cada entrada apunta a una unidad viva parada exactamente ahí, sin fantasmas).
func board_consistent() -> bool:
	for nid in board.keys():
		var uid := int(board[nid])
		if not units.has(uid) or not units[uid]["alive"] or int(units[uid]["node"]) != int(nid):
			return false
	for uid in units.keys():
		var n := int(units[uid]["node"])
		if units[uid]["alive"] and n >= 0 and int(board.get(n, -1)) != int(uid):
			return false
	return true

## Rolls an attack: returns { "seg": buffed segment (what the figure WILL do, with
## buff-node/modifier bonuses already baked in), "idx": the pool face that came up
## (so the die/reel lands on the right face) }.
## `forced` >= 0 replays a specific rolled face (online lockstep: the acting client
## rolled it; the other client re-applies the SAME index for an identical result).
func _roll_full(uid: int, is_attacker := false, forced := -1) -> Dictionary:
	var pool: Array = pool_for(uid)
	var bidx := forced if (forced >= 0 and forced < pool.size()) else _weighted_index(pool)
	# MODIFIER — Adrenaline: reroll a Miss once (attacker), before other buffs.
	if forced < 0 and is_attacker and pending_buff[units[uid]["team"]].get("adrenaline", false) and String(pool[bidx].get("col", "")) == "red":
		bidx = _weighted_index(pool)
	var s: Dictionary = pool[bidx].duplicate(true)
	if has_status(uid, "weakened"):
		if s.has("pow"):
			s["pow"] = maxi(0, int(s["pow"]) - 20)
		if s.has("stars"):
			s["stars"] = maxi(1, int(s["stars"]) - 1)
	# BURN — the flames sap the burning figure's damage.
	if has_status(uid, "burn") and s.has("pow"):
		s["pow"] = maxi(0, int(s["pow"]) - BURN_DMG_PEN)
	# FROZEN / SHIELD BREAK — the figure cannot raise a Blue defence (it collapses to a Miss).
	if String(s.get("col", "")) == "blue" and (has_status(uid, "freeze") or has_status(uid, "shield_break")):
		s = {"col": "red", "name": String(s.get("name", "Bloqueo"))}
	# SILENCE — the figure cannot cast Purple specials (they fizzle to a Miss).
	elif String(s.get("col", "")) == "purple" and has_status(uid, "silence"):
		s = {"col": "red", "name": String(s.get("name", "Silenciado"))}
	# CONFUSION — an attacking, confused figure fumbles half the time.
	if is_attacker and has_status(uid, "confusion") and randf() < 0.5:
		s = {"col": "red", "name": "Confusión"}
	# BUFF NODE — a unit standing on a buff node rolls stronger.
	if int(units[uid]["node"]) in map.buffs:
		_boost_seg(s, BUFF_DMG, BUFF_STARS)
	# MODIFIERS — one-shot attacker buffs (baked into the shown number).
	if is_attacker:
		var pb: Dictionary = pending_buff[units[uid]["team"]]
		if pb.get("surge", false):
			_boost_seg(s, BUFF_DMG, BUFF_STARS)
		if pb.get("surge_big", false):
			_boost_seg(s, 40, 2)
		pending_buff[units[uid]["team"]] = {}
	return {"seg": s, "idx": bidx}

func _weighted_index(pool: Array) -> int:
	var total := 0.0
	for s in pool:
		total += float(s.get("w", 1.0))
	var pick := randf() * total
	for i in pool.size():
		pick -= float(pool[i].get("w", 1.0))
		if pick <= 0.0:
			return i
	return pool.size() - 1

func _boost_seg(s: Dictionary, dmg: int, stars: int) -> void:
	if s.has("pow"):
		s["pow"] = int(s["pow"]) + dmg
	if String(s.get("col", "")) == "purple":
		s["stars"] = int(s.get("stars", 1)) + stars

## Resolve an attack. KO only on a damage (White/Gold) win. Purple win applies a
## status (and/or displacement); Blue win blocks. Returns the combat record.
## `fidx_a`/`fidx_b` >= 0 force the rolled faces (online: the acting client sends the
## indices it rolled so the other client reproduces the SAME combat, no re-rolling).
func attack(att_uid: int, def_uid: int, att_moved: int = 0, fidx_a: int = -1, fidx_b: int = -1) -> Dictionary:
	var ra := _roll_full(att_uid, true, fidx_a)
	var seg_a: Dictionary = ra["seg"]
	var idx_a := int(ra["idx"])
	# PASSIVE — Lunge: after moving 2+ nodes this turn, reroll a Miss once.
	if fidx_a < 0 and String(seg_a.get("col", "")) == "red" and att_moved >= 2 and has_passive(att_uid, "lunge"):
		ra = _roll_full(att_uid, true)
		seg_a = ra["seg"]
		idx_a = int(ra["idx"])
	_att_moved_ctx = att_moved
	var rb := _roll_full(def_uid, false, fidx_b)
	var seg_b: Dictionary = rb["seg"]
	var idx_b := int(rb["idx"])
	# MARKED — attacking a Marked figure hits harder (+20 dmg / +1★, baked in).
	if has_status(def_uid, "marked"):
		_boost_seg(seg_a, 20, 1)
	var oc := Combat.outcome(seg_a, seg_b)
	# CURSE — the cursed figure loses ties (the opponent wins, unless both rolled a Miss).
	if int(oc["result"]) == 0:
		var a_curse := has_status(att_uid, "curse")
		var d_curse := has_status(def_uid, "curse")
		if a_curse != d_curse:
			var win_seg: Dictionary = seg_b if a_curse else seg_a
			if String(win_seg.get("col", "")) != "red":
				oc = _outcome_from_winner(win_seg, -1 if a_curse else 1)
	var ko_uid := -1
	var applied := {}
	var disp := {}
	var ranked := -1
	if oc["ko"]:
		ko_uid = def_uid if int(oc["result"]) > 0 else att_uid
		_ko(ko_uid)
		var winner_k: int = att_uid if int(oc["result"]) > 0 else def_uid
		if _try_rank_up(winner_k):      # RANK UP: scoring a KO evolves the figure
			ranked = winner_k
	elif int(oc["result"]) != 0:
		var winner_uid: int = att_uid if int(oc["result"]) > 0 else def_uid
		var loser_uid: int = def_uid if int(oc["result"]) > 0 else att_uid
		var ws: Dictionary = oc["win_seg"]
		var wcol := String(ws.get("col", ""))
		var fx := String(ws.get("fx", ""))
		if FX_STATUS.has(fx):
			apply_status(loser_uid, FX_STATUS[fx])   # DOTs use their own longer timer
			applied = {"status": FX_STATUS[fx], "target": loser_uid, "fx": fx}
		# PASSIVE — Venom Hex: a Purple win also Weakens the loser.
		if wcol == "purple" and has_passive(winner_uid, "venom_hex"):
			apply_status(loser_uid, "weakened", STATUS_DUR)
			if applied.is_empty():
				applied = {"status": "weakened", "target": loser_uid, "fx": "Venom Hex"}
		if ws.has("disp"):
			disp = _apply_displacement(winner_uid, loser_uid, ws)
		# PASSIVE — Counter-Stone: a defending Blue win Pushes the attacker 1.
		if wcol == "blue" and winner_uid == def_uid and has_passive(def_uid, "counter_stone"):
			disp = _apply_displacement(def_uid, att_uid, {"disp": "push", "n": 1})
	else:
		# PASSIVE — Hold the Line: a tie while defending Immobilizes the attacker.
		if has_passive(def_uid, "hold_the_line"):
			apply_status(att_uid, "immobilized", STATUS_DUR)
			applied = {"status": "immobilized", "target": att_uid, "fx": "Hold the Line"}
		# PASSIVE — Hexstep: the Witch retreats 1 node (away from the attacker) on a tie.
		if has_passive(def_uid, "hexstep"):
			disp = _apply_displacement(att_uid, def_uid, {"disp": "push", "n": 1})
	# SLEEP — entering combat wakes a sleeping figure (the status is consumed).
	for u in [att_uid, def_uid]:
		if units[u]["alive"]:
			units[u]["statuses"].erase("sleep")
	return {
		"att": att_uid, "def": def_uid, "seg_a": seg_a, "seg_b": seg_b,
		"result": int(oc["result"]), "win_col": oc["win_col"], "effect": oc["effect"],
		"ko": ko_uid, "status": applied, "disp": disp, "rankup": ranked,
		"idx_a": idx_a, "idx_b": idx_b,
	}

## Build a combat outcome from a forced winning segment (mirrors Combat.outcome's
## winner branch). Used when Curse overturns a tie.
func _outcome_from_winner(win_seg: Dictionary, result: int) -> Dictionary:
	var wc := String(win_seg.get("col", ""))
	var ko := false
	var eff := ""
	if wc == "white" or wc == "gold":
		ko = bool(win_seg.get("ko", true)); eff = "KO"
	elif wc == "purple":
		ko = bool(win_seg.get("ko", false)); eff = String(win_seg.get("fx", "Estado"))
	elif wc == "blue":
		eff = "Bloqueo"
	return {"result": result, "ko": ko, "win_col": wc, "effect": eff, "win_seg": win_seg}

# --- rank up / evolution ---------------------------------------------------
## Effective figure data at the unit's current rank (base, or a "ranks" override).
func rank_data(uid: int) -> Dictionary:
	var base: Dictionary = Roster.FIGURES[units[uid]["rindex"]]
	var r := int(units[uid].get("rank", 0))
	var ranks: Array = base.get("ranks", [])
	if r >= 1 and r - 1 < ranks.size():
		var st: Dictionary = ranks[r - 1]
		# If this stage evolves INTO an existing figure, use that figure's LIVE data
		# (not a copy frozen at creation) so editing the target — or the evolution — is
		# reflected in new matches. Inline stages (no evolves_id) use the stored data.
		var eff: Dictionary = st
		if st.has("evolves_id"):
			var src := _figure_by_id(String(st["evolves_id"]))
			if not src.is_empty():
				eff = src
		var m := _stage_model(st, base)
		return {
			"id": base.get("id", ""),
			"name": eff.get("name", st.get("name", base["name"])),
			"attack": eff.get("attack", st.get("attack", base["attack"])),
			"type": eff.get("type", st.get("type", base.get("type", "Ruleta"))),
			"stamina": eff.get("stamina", st.get("stamina", base.get("stamina", 2))),
			"passives": eff.get("passives", st.get("passives", base.get("passives", []))),
			"coin_a": eff.get("coin_a", base.get("coin_a", [])),
			"coin_b": eff.get("coin_b", base.get("coin_b", [])),
			"glb": m["glb"], "clips": m["clips"], "size": m["size"],
		}
	return {
		"id": base.get("id", ""),
		"name": base["name"], "attack": base["attack"], "type": base.get("type", "Ruleta"),
		"stamina": base.get("stamina", 2), "passives": base.get("passives", []),
		"coin_a": base.get("coin_a", []), "coin_b": base.get("coin_b", []),
		"glb": base.get("glb", ""), "clips": base.get("clips", {}), "size": base.get("size", 1.0),
	}

## The 3D model (glb/clips/size) to render for this unit AT ITS CURRENT RANK.
func model_data(uid: int) -> Dictionary:
	var rd := rank_data(uid)
	return {"glb": rd.get("glb", ""), "clips": rd.get("clips", {}), "size": rd.get("size", 1.0)}

## Resolve an evolution stage's 3D model: its own glb, else the figure it evolves
## INTO (evolves_id — works even for figures saved before stages carried a glb),
## else the base figure's model.
func _stage_model(st: Dictionary, base: Dictionary) -> Dictionary:
	# Prefer the LIVE target figure's model (so editing the target propagates), then
	# the stored stage copy, then the base figure.
	if st.has("evolves_id"):
		var src := _figure_by_id(String(st["evolves_id"]))
		if not src.is_empty() and String(src.get("glb", "")) != "":
			return {"glb": String(src["glb"]), "clips": src.get("clips", {}), "size": float(src.get("size", 1.0))}
	var glb := String(st.get("glb", ""))
	var clips: Dictionary = st.get("clips", {})
	var size := float(st.get("size", 0.0))
	if glb == "":
		glb = String(base.get("glb", ""))
		if clips.is_empty():
			clips = base.get("clips", {})
	if size <= 0.0:
		size = float(base.get("size", 1.0))
	return {"glb": glb, "clips": clips, "size": size}

func _figure_by_id(id: String) -> Dictionary:
	for f in Roster.FIGURES:
		if String(f.get("id", "")) == id:
			return f
	return {}

func pool_for(uid: int) -> Array:
	return rank_data(uid)["attack"]

func type_for(uid: int) -> String:
	return String(rank_data(uid)["type"])

func name_for(uid: int) -> String:
	var r := int(units[uid].get("rank", 0))
	return String(rank_data(uid)["name"]) + ("  +%d" % r if r > 0 else "")

## On a KO, the figure that scored it gains a rank (if it has a next stage). Rank
## Up swaps its attack pool/type/stamina/passives and removes status effects.
func _try_rank_up(uid: int) -> bool:
	if not units[uid]["alive"]:
		return false
	var ranks: Array = Roster.FIGURES[units[uid]["rindex"]].get("ranks", [])
	var r := int(units[uid].get("rank", 0))
	if r >= ranks.size():
		return false
	units[uid]["rank"] = r + 1
	units[uid]["statuses"] = {}
	units[uid]["stamina"] = int(rank_data(uid)["stamina"])
	return true

## Movement budget after auras (Venom Aura: adjacent enemy -> -1 stamina).
func effective_stamina(uid: int) -> int:
	var s := int(units[uid]["stamina"])
	for nb in map.adj[units[uid]["node"]]:
		var occ := int(board.get(nb, -1))
		if occ != -1 and units[occ]["alive"] and units[occ]["team"] != units[uid]["team"] and has_passive(occ, "venom_aura"):
			s -= 1
			break
	return maxi(0, s)

# --- passives --------------------------------------------------------------
func has_passive(uid: int, pid: String) -> bool:
	return pid in (rank_data(uid)["passives"] as Array)

## Bedrock (self) or a neighbouring ally's Bulwark aura -> immune to push/pull/swap.
func _displacement_immune(uid: int) -> bool:
	if has_passive(uid, "bedrock"):
		return true
	for nb in map.adj[units[uid]["node"]]:
		var occ := int(board.get(nb, -1))
		if occ != -1 and units[occ]["alive"] and units[occ]["team"] == units[uid]["team"] and has_passive(occ, "bulwark"):
			return true
	return false

func _apply_displacement(winner_uid: int, loser_uid: int, seg: Dictionary) -> Dictionary:
	if _displacement_immune(loser_uid):
		return {"type": "immune", "uid": loser_uid}
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
	# push / pull along the graph, guided by node positions
	var win_pos := map.pos_of(w["node"])
	var steps := int(seg.get("n", 1))
	if has_passive(winner_uid, "arcane_pull"):   # PASSIVE — Arcane Pull: +1 distance
		steps += 1
	if typ == "push" and _att_moved_ctx >= 3 and has_passive(winner_uid, "dive"):  # PASSIVE — Dive
		steps += 1
	var cur: int = l["node"]
	for i in steps:
		var cur_pos := map.pos_of(cur)
		var want := (cur_pos - win_pos) if typ == "push" else (win_pos - cur_pos)
		want = want.normalized()
		var best := -1
		var best_score := 0.15   # require a clear directional match
		for nb in map.adj[cur]:
			if board.has(nb) or nb in map.obstacles or node_locked(nb):
				continue
			var score := (map.pos_of(nb) - cur_pos).normalized().dot(want)
			if score > best_score:
				best_score = score
				best = nb
		if best == -1:
			break
		board.erase(cur)
		cur = best
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
	_grant_energy(turn_team)
	mod_used[turn_team] = false                  # refresh the per-turn modifier
	_apply_turn_start_auras(turn_team)
	_tick_dots(turn_team)                         # Burn/Poison may KO at turn start
	if winner == "" and not can_act(turn_team):
		winner = "enemy" if turn_team == "player" else "player"

## Burning Aura: at the start of the team's turn, its aura-bearers Weaken adjacent enemies.
func _apply_turn_start_auras(team: String) -> void:
	for uid in units_on_board(team):
		if has_passive(uid, "burning_aura"):
			for foe in adjacent_enemies(uid):
				apply_status(foe, "weakened", STATUS_DUR)

## Burn/Poison are lethal timers: when the timer elapses (and was not cleansed by
## Rank Up or the Cleanse modifier) the figure is KO'd at the start of its turn.
func _tick_dots(team: String) -> void:
	for uid in units_on_board(team).duplicate():
		if not units[uid]["alive"]:
			continue
		var st: Dictionary = units[uid]["statuses"]
		for s in ["burn", "poison"]:
			if st.has(s) and turn_no >= int(st[s]):
				_ko(uid)
				break

# --- energy / modifiers / buff nodes ---------------------------------------
func _grant_energy(team: String) -> void:
	var gain := ENERGY_PER_TURN
	if controls_buff(team):
		gain += BUFF_ENERGY
	energy[team] = mini(ENERGY_MAX, int(energy[team]) + gain)

func controls_buff(team: String) -> bool:
	for b in map.buffs:
		var occ := int(board.get(b, -1))
		if occ != -1 and units[occ]["alive"] and units[occ]["team"] == team:
			return true
	return false

func can_use_modifier(team: String, mod_id: String) -> bool:
	return MODIFIERS.has(mod_id) and not bool(mod_used[team]) and int(energy[team]) >= int(MODIFIERS[mod_id]["cost"])

func activate_modifier(team: String, mod_id: String) -> bool:
	if not can_use_modifier(team, mod_id):
		return false
	mod_used[team] = true                        # only one modifier per turn
	energy[team] = int(energy[team]) - int(MODIFIERS[mod_id]["cost"])
	match mod_id:
		"power_surge":
			pending_buff[team]["surge"] = true
		"fury":
			pending_buff[team]["surge_big"] = true
		"adrenaline":
			pending_buff[team]["adrenaline"] = true
		"cleanse":
			for uid in units_on_board(team):
				units[uid]["statuses"] = {}
	return true

# --- simple bot ------------------------------------------------------------
# --- bot ------------------------------------------------------------------
## 0 = random/easy, 1 = medium (no surround setups), 2 = hard (default).
var bot_difficulty := 2

## CPU por lista de prioridades (ver docs/AI_CPU.md). 0 = fácil (legacy);
## 1+ = lista completa; 2 = además gasta modificadores en ataques ganadores.
func bot_action(team: String) -> Dictionary:
	if bot_difficulty <= 0:
		return _bot_easy(team)
	var target_goal: int = map.goal_player if team == "enemy" else map.goal_enemy
	var own_goal: int = map.goal_enemy if team == "enemy" else map.goal_player

	var act := _bot_win_now(team, target_goal)          # 1) ganar YA
	if act.is_empty():
		act = _bot_guard_goal(team, own_goal)           # 2) PORTERO en mi meta
	if act.is_empty():
		act = _bot_surround(team, own_goal)             # 3) cerrar un CERCO (falta 1)
	if act.is_empty():
		act = _bot_attack(team, target_goal, own_goal)  # 4) ataque ÚTIL (gana espacio)
	if act.is_empty():
		act = _bot_deploy(team, target_goal)            # 5) desplegar TODO (banca vacía)
	if act.is_empty():
		act = _bot_buff(team, own_goal)                 # 6) tomar el buff node
	if act.is_empty():
		act = _bot_advance(team, target_goal, own_goal) # 7) avanzar ESQUIVANDO rivales
	return act if not act.is_empty() else {"type": "pass"}

# 1) Pisar la meta rival si está al alcance = victoria inmediata.
func _bot_win_now(team: String, target_goal: int) -> Dictionary:
	for uid in units_on_board(team):
		if can_move(uid) and reachable_for(uid).has(target_goal):
			var p := _bot_path(uid, target_goal)
			move_unit(uid, target_goal)
			return {"type": "move", "uid": uid, "node": target_goal, "path": p}
	return {}

# 2) PORTERO: mantener SIEMPRE una figura sentada en la propia meta (un nodo
# ocupado no puede ser pisado -> el rival no puede ganar por ahí).
func _bot_guard_goal(team: String, own_goal: int) -> Dictionary:
	if _node_occupant(own_goal) != -1:
		return {}                    # ya hay portero (o el rival ya ganó)
	# ¿alguien puede SENTARSE ya mismo? (el de camino más barato)
	var best_uid := -1
	var best_cost := INF
	for uid in units_on_board(team):
		if can_move(uid):
			var reach := reachable_for(uid)
			if reach.has(own_goal) and float(reach[own_goal]) < best_cost:
				best_cost = float(reach[own_goal])
				best_uid = uid
	if best_uid != -1:
		var p := _bot_path(best_uid, own_goal)
		move_unit(best_uid, own_goal)
		return {"type": "move", "uid": best_uid, "node": own_goal, "path": p}
	# nadie llega: sembrar guardia desde la banca por la entrada más cercana a MI
	# meta y CAMINAR hacia ella con la estamina restante (como el jugador).
	if can_deploy(team):
		var fe := free_entrances(team)
		var node: int = fe[0]
		var bd := INF
		for n in fe:
			var dd := _dist(n, own_goal)
			if dd < bd:
				bd = dd
				node = n
		var uid := _best_bench(team)
		deploy(uid, node)
		var rec := {"type": "deploy", "uid": uid, "node": node}
		_bot_deploy_walk(rec, uid, own_goal, team)
		return rec
	return {}

# 3) CERCO: si a un rival le falta EXACTAMENTE un nodo para quedar rodeado,
# ocupar ese último hueco (KO por rodeo al final del turno).
func _bot_surround(team: String, own_goal: int) -> Dictionary:
	var opp := _enemy_team(team)
	for uid in units_on_board(team):
		if not can_move(uid) or int(units[uid]["node"]) == own_goal:
			continue                                       # el portero no abandona
		for nid in reachable_for(uid).keys():
			if _all_neighbours_held(nid, opp):
				continue                                   # no meterse a un cerco rival
			for nb in map.adj[nid]:
				var occ := _node_occupant(nb)
				if occ != -1 and units[occ]["team"] == opp and units[occ]["alive"]:
					if _all_neighbours_held(units[occ]["node"], team, nid):
						var p := _bot_path(uid, nid)
						move_unit(uid, nid)
						return {"type": "move", "uid": uid, "node": nid, "path": p}
	return {}

# 4) ATAQUE ÚTIL: probabilidad real de ganar/KO + amenaza a MI meta + GANAR
# ESPACIO (bono si el rival está delante de mí, estorbando el camino a su meta).
func _bot_attack(team: String, target_goal: int, own_goal: int) -> Dictionary:
	var md := maxf(1.0, _dist(map.goal_player, map.goal_enemy))
	var atk_uid := -1
	var atk_foe := -1
	var best := -INF
	for uid in units_on_board(team):
		if not can_attack(uid):
			continue
		var mine := _pool_of(uid)
		for foe in adjacent_enemies(uid):
			var wp := _win_prob(mine, _pool_of(foe))
			var kp := _ko_prob(mine, _pool_of(foe))
			var threat := 1.0 - clampf(_dist(units[foe]["node"], own_goal) / md, 0.0, 1.0)
			var space := 0.35 if _dist(units[foe]["node"], target_goal) < _dist(units[uid]["node"], target_goal) else 0.0
			var score := wp * 0.7 + kp * 0.6 + threat * 0.5 + space
			if (wp >= 0.42 or threat > 0.7) and score > best:
				best = score
				atk_uid = uid
				atk_foe = foe
	if atk_uid == -1:
		return {}
	var used_mod := ""
	if bot_difficulty >= 2 and best >= 0.6 and can_use_modifier(team, "power_surge"):
		if activate_modifier(team, "power_surge"):  # spend energy to press an edge
			used_mod = "power_surge"
	var rec := attack(atk_uid, atk_foe)
	rec["type"] = "attack"
	rec["modifier"] = used_mod
	return rec

# 5) DESPLEGAR TODO: nunca dejar figuras en la banca (la mejor primero, por la
# entrada más cercana a la meta rival) y AVANZAR con la estamina restante.
func _bot_deploy(team: String, target_goal: int) -> Dictionary:
	if not can_deploy(team):
		return {}
	var fe := free_entrances(team)
	var node: int = fe[0]
	var bd := INF
	for n in fe:
		var dd := _dist(n, target_goal)
		if dd < bd:
			bd = dd
			node = n
	var uid := _best_bench(team)
	deploy(uid, node)
	var rec := {"type": "deploy", "uid": uid, "node": node}
	_bot_deploy_walk(rec, uid, target_goal, team)
	return rec

## Tras desplegar, camina con la estamina RESTANTE (desplegar cuesta 1, igual
## que el jugador) hacia donde quiere estar, esquivando rivales y sin apilarse.
## Anota "move_to"/"path" en el record para que la vista anime el paseo.
func _bot_deploy_walk(rec: Dictionary, uid: int, toward: int, team: String) -> void:
	var budget := effective_stamina(uid) - 1
	if budget <= 0 or not can_move(uid):
		return
	var opp := _enemy_team(team)
	var cur := _dist(units[uid]["node"], toward)
	var best_node := -1
	var best_score := 0.01
	for nid in move_targets(uid, budget).keys():
		if _all_neighbours_held(nid, opp):
			continue                                   # no meterse solo a un cerco
		var impr := cur - _dist(nid, toward)
		var risk := 0.0
		for nb in map.adj[nid]:
			var occ := _node_occupant(nb)
			if occ != -1 and units[occ]["team"] == opp and units[occ]["alive"]:
				risk += 1.0
		var score := impr - risk * 0.8
		if score > best_score:
			best_score = score
			best_node = nid
	if best_node == -1:
		return
	var p := _bot_path(uid, best_node)
	if move_unit(uid, best_node):
		rec["move_to"] = best_node
		rec["path"] = p

# 6) BUFF NODE: tomar el centro si está libre y no es una trampa.
func _bot_buff(team: String, own_goal: int) -> Dictionary:
	if controls_buff(team):
		return {}
	var opp := _enemy_team(team)
	for uid in units_on_board(team):
		if not can_move(uid) or int(units[uid]["node"]) == own_goal:
			continue
		for b in map.buffs:
			if _node_occupant(b) == -1 and not _all_neighbours_held(b, opp) and reachable_for(uid).has(b):
				var p := _bot_path(uid, b)
				move_unit(uid, b)
				return {"type": "move", "uid": uid, "node": b, "path": p}
	return {}

# 7) AVANZAR ESQUIVANDO: máximo progreso hacia la meta rival, penalizando
# terminar junto a rivales (evita peleas gratis) y sin meterse a cercos.
func _bot_advance(team: String, target_goal: int, own_goal: int) -> Dictionary:
	var opp := _enemy_team(team)
	var mv_uid := -1
	var mv_node := -1
	var best_score := 0.01
	for uid in units_on_board(team):
		if not can_move(uid) or int(units[uid]["node"]) == own_goal:
			continue                                       # el portero se queda
		var cur := _dist(units[uid]["node"], target_goal)
		for nid in reachable_for(uid).keys():
			if _all_neighbours_held(nid, opp):
				continue
			var impr := cur - _dist(nid, target_goal)
			var risk := 0.0
			for nb in map.adj[nid]:
				var occ := _node_occupant(nb)
				if occ != -1 and units[occ]["team"] == opp and units[occ]["alive"]:
					risk += 1.0
			var score := impr - risk * 0.8
			if score > best_score:
				best_score = score
				mv_uid = uid
				mv_node = nid
	if mv_uid != -1:
		var p := _bot_path(mv_uid, mv_node)
		move_unit(mv_uid, mv_node)
		return {"type": "move", "uid": mv_uid, "node": mv_node, "path": p}
	return {}

func _bot_easy(team: String) -> Dictionary:
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
	return {"type": "pass"}

func _pool_of(uid: int) -> Array:
	return pool_for(uid)

func _enemy_team(team: String) -> String:
	return "enemy" if team == "player" else "player"

func _dist(n1: int, n2: int) -> float:
	return map.pos_of(n1).distance_to(map.pos_of(n2))

func _node_occupant(node: int) -> int:
	return int(board.get(node, -1))

func _bot_path(uid: int, node: int) -> Array:
	return move_path(uid, node)

## P(attacker's pool beats defender's pool), exact over all weighted segment pairs.
func _win_prob(a: Array, b: Array) -> float:
	var ta := _wsum(a)
	var tb := _wsum(b)
	if ta <= 0.0 or tb <= 0.0:
		return 0.0
	var wins := 0.0
	for sa in a:
		for sb in b:
			if Combat.resolve(sa, sb) > 0:
				wins += float(sa.get("w", 1.0)) * float(sb.get("w", 1.0))
	return wins / (ta * tb)

## P(attacker wins AND it is a KO, i.e. a White/Gold damage win).
func _ko_prob(a: Array, b: Array) -> float:
	var ta := _wsum(a)
	var tb := _wsum(b)
	if ta <= 0.0 or tb <= 0.0:
		return 0.0
	var k := 0.0
	for sa in a:
		var col := String(sa.get("col", ""))
		if col != "white" and col != "gold":
			continue
		for sb in b:
			if Combat.resolve(sa, sb) > 0:
				k += float(sa.get("w", 1.0)) * float(sb.get("w", 1.0))
	return k / (ta * tb)

func _wsum(pool: Array) -> float:
	var t := 0.0
	for s in pool:
		t += float(s.get("w", 1.0))
	return t

## True if every neighbour of `node` is held by a live `by_team` unit (so an enemy
## standing on `node` is surrounded). `extra` counts as also held by `by_team`.
func _all_neighbours_held(node: int, by_team: String, extra: int = -1) -> bool:
	var nbs: Array = map.adj[node]
	if nbs.is_empty():
		return false
	for nb in nbs:
		if nb == extra:
			continue
		var occ := _node_occupant(nb)
		if occ == -1 or units[occ]["team"] != by_team or not units[occ]["alive"]:
			return false
	return true

func _best_bench(team: String) -> int:
	var best: int = bench[team][0]
	var bs := -INF
	for uid in bench[team]:
		var s := _self_strength(units[uid]["rindex"])
		if s > bs:
			bs = s
			best = uid
	return best

## Rough offensive value of a figure's pool (for picking what to deploy).
func _self_strength(rindex: int) -> float:
	var pool: Array = Roster.FIGURES[rindex]["attack"]
	var t := 0.0
	var sc := 0.0
	for s in pool:
		var w := float(s.get("w", 1.0))
		t += w
		var col := String(s.get("col", ""))
		if col == "white" or col == "gold":
			sc += w * float(s.get("pow", 0))
		elif col == "purple":
			sc += w * (25.0 + 15.0 * float(s.get("stars", 1)))
		elif col == "blue":
			sc += w * 20.0
	return sc / t if t > 0.0 else 0.0
