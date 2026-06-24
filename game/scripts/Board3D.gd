extends Node3D
## Layer 1 playable board (revised). Figures start in a bench and DEPLOY from an
## entrance (deploy costs 1 stamina; the figure may keep moving with what's left).
## One figure activates per turn: move (by remaining stamina) then the player
## DECIDES to attack an adjacent enemy or press "Terminar turno". Attack -> wheel
## (CombatOverlay) -> a close-up "combat shot" of the winner beating the loser ->
## back to the board -> resolve KO. Enemy = simple bot.
## Deferred: surround KO, KO-bench return, rank-up, energy/modifiers, real bot.

const ROLE_COLOR := {
	"normal": Color(0.20, 0.22, 0.30),
	"entrance_player": Color(0.20, 0.45, 0.95),
	"entrance_enemy": Color(0.95, 0.35, 0.30),
	"goal_player": Color(0.30, 0.85, 0.50),
	"goal_enemy": Color(0.98, 0.80, 0.25),
	"buff": Color(1.0, 0.6, 0.2),
}
const HILITE_MOVE := Color(0.35, 1.0, 0.5)
const HILITE_ATK := Color(1.0, 0.3, 0.3)
const HILITE_DEPLOY := Color(0.4, 0.8, 1.0)
const FACE_OFFSET := 0.0
const STATUS_ES := {"fear": "Miedo", "weakened": "Debilitado", "paralysis": "Paralizado", "immobilized": "Inmovilizado"}

var _gs: GameState
var _cam: Camera3D
var _combat_cam: Camera3D
var _overlay: CombatOverlay
var _vis := {}                # uid -> Figure3D
var _status_lbls := {}        # uid -> Label3D (status indicator over the figure)
var _node_mi := {}
var _node_mat := {}
var _highlighted := []
# Turn / activation state
var _active_uid := -1
var _remaining := 0
var _committed := false
var _deploy_uid := -1
var _reach := {}
var _foe_nodes := {}          # node id -> foe uid
var _busy := false
var _over := false
var _status: Label
var _end_btn: Button
var _bench_box: HBoxContainer

func _ready() -> void:
	# Force PORTRAIT at runtime (reliable on Android regardless of the manifest).
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	randomize()
	_build_environment()
	_gs = GameState.new(MapData.new())
	# 5 figures per side (duplicates allowed) so surrounding is feasible.
	for ri in [0, 1, 2, 3, 4]:
		_gs.add_to_bench("player", ri)
	for ri in [0, 1, 2, 3, 4]:
		_gs.add_to_bench("enemy", ri)
	_build_board()
	_overlay = CombatOverlay.new()
	add_child(_overlay)
	_build_ui()
	_refresh_bench_ui()
	_update_status()

# ---------------------------------------------------------------- environment
func _build_environment() -> void:
	_cam = Camera3D.new()
	# Lock the HORIZONTAL fov (KEEP_WIDTH) so the board's width is always fully
	# visible on a tall portrait screen (no cut-off edges); height gets extra room.
	_cam.keep_aspect = Camera3D.KEEP_WIDTH
	_cam.fov = 34.0
	# Camera on the player's side: player sits at the BOTTOM, enemy at the top.
	_cam.look_at_from_position(Vector3(0.0, 11.5, -11.0), Vector3.ZERO, Vector3.UP)
	add_child(_cam)
	_combat_cam = Camera3D.new()
	_combat_cam.keep_aspect = Camera3D.KEEP_WIDTH
	_combat_cam.fov = 45.0
	add_child(_combat_cam)
	_cam.current = true
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.06, 0.10)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.6, 0.8)
	env.ambient_light_energy = 0.6
	we.environment = env
	add_child(we)

# ---------------------------------------------------------------- board build
func _build_board() -> void:
	var seen := {}
	for id in _gs.map.adj:
		for nb in _gs.map.adj[id]:
			var key := mini(id, nb) * 10000 + maxi(id, nb)
			if seen.has(key):
				continue
			seen[key] = true
			_make_line(_gs.map.pos_of(id), _gs.map.pos_of(nb))
	for n in _gs.map.nodes:
		var mi := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.5
		disc.bottom_radius = 0.5
		disc.height = 0.08
		mi.mesh = disc
		mi.position = n["pos"] + Vector3(0, 0.04, 0)
		var mat := StandardMaterial3D.new()
		var col: Color = ROLE_COLOR.get(n["role"], ROLE_COLOR["normal"])
		mat.albedo_color = col
		if n["role"] != "normal":
			mat.emission_enabled = true
			mat.emission = col
			mat.emission_energy_multiplier = 0.5
		mi.material_override = mat
		add_child(mi)
		_node_mi[n["id"]] = mi
		_node_mat[n["id"]] = mat

func _make_line(a: Vector3, b: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.05, 0.02, a.distance_to(b))
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.45, 0.7)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.45, 0.8)
	mat.emission_energy_multiplier = 0.3
	mi.material_override = mat
	var mid := (a + b) * 0.5 + Vector3(0, 0.02, 0)
	mi.look_at_from_position(mid, b + Vector3(0, 0.02, 0), Vector3.UP)
	add_child(mi)

# ---------------------------------------------------------------- figures
func _spawn_vis(uid: int) -> void:
	var u: Dictionary = _gs.units[uid]
	var data: Dictionary = Roster.FIGURES[u["rindex"]]
	var fig := Figure3D.new()
	add_child(fig)
	fig.setup(data["glb"], data["clips"], float(data.get("size", 1.0)))
	fig.position = _gs.map.pos_of(u["node"])
	_face(fig, Vector3(0, 0, 1.0) if u["team"] == "player" else Vector3(0, 0, -1.0))
	_add_team_ring(fig, u["team"])
	fig.play_clip("idle")
	var lbl := Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.pixel_size = 0.004
	lbl.font_size = 64
	lbl.outline_size = 14
	lbl.modulate = Color(1.0, 0.8, 0.3)
	lbl.position = Vector3(0, 2.05, 0)
	lbl.visible = false
	fig.add_child(lbl)
	_status_lbls[uid] = lbl
	_vis[uid] = fig

func _add_team_ring(fig: Figure3D, team: String) -> void:
	var ring := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.55
	disc.bottom_radius = 0.55
	disc.height = 0.03
	ring.mesh = disc
	ring.position = Vector3(0, 0.06, 0)
	var mat := StandardMaterial3D.new()
	var col := Color(0.25, 0.55, 1.0) if team == "player" else Color(1.0, 0.35, 0.3)
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.6
	ring.material_override = mat
	fig.add_child(ring)

func _face(fig: Node3D, dir: Vector3) -> void:
	if dir.length() < 0.001:
		return
	fig.rotation.y = atan2(dir.x, dir.z) + FACE_OFFSET

# ---------------------------------------------------------------- ui
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_status = Label.new()
	_status.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_status.offset_left = 12
	_status.offset_top = 10
	_status.add_theme_font_size_override("font_size", 20)
	layer.add_child(_status)

	_end_btn = Button.new()
	_end_btn.text = "Terminar turno"
	_end_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_end_btn.offset_left = -168
	_end_btn.offset_top = -118
	_end_btn.offset_right = -12
	_end_btn.offset_bottom = -74
	_end_btn.pressed.connect(_on_end_turn_pressed)
	layer.add_child(_end_btn)

	var bench_panel := PanelContainer.new()
	bench_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bench_panel.offset_top = -64
	bench_panel.offset_bottom = -8
	bench_panel.offset_left = 8
	bench_panel.offset_right = -8
	layer.add_child(bench_panel)
	_bench_box = HBoxContainer.new()
	_bench_box.alignment = BoxContainer.ALIGNMENT_CENTER
	bench_panel.add_child(_bench_box)

func _refresh_bench_ui() -> void:
	for c in _bench_box.get_children():
		c.queue_free()
	var bench: Array = _gs.bench["player"]
	if bench.is_empty():
		var l := Label.new()
		l.text = "Banca vacía"
		l.modulate = Color(0.6, 0.6, 0.7)
		_bench_box.add_child(l)
		return
	var disabled := _committed or _gs.turn_team != "player" or _busy or _over
	for uid in bench:
		var b := Button.new()
		b.text = Roster.FIGURES[_gs.units[uid]["rindex"]]["name"]
		b.disabled = disabled
		b.pressed.connect(_begin_deploy.bind(uid))
		_bench_box.add_child(b)

func _update_status() -> void:
	if _over:
		_end_btn.visible = false
		return
	_end_btn.visible = _gs.turn_team == "player"
	# Can't end the turn without acting — unless there is genuinely nothing to do.
	_end_btn.disabled = _busy or (not _committed and _player_has_actions())
	if _gs.turn_team != "player":
		_status.text = "Turno del enemigo…"
	elif _active_uid != -1:
		_status.text = "%s — mov restante: %d.  verde=mover · rojo=atacar · o Terminar turno." % [
			Roster.FIGURES[_gs.units[_active_uid]["rindex"]]["name"], _remaining]
	else:
		_status.text = "Tu turno — toca una figura, o despliega desde la banca."
	_refresh_status_labels()

# ---------------------------------------------------------------- input
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if not _busy and not _over and _gs.turn_team == "player":
				_on_board_click(mb.position)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_cam.position *= 0.93
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_cam.position *= 1.07

func _node_under_cursor(mouse: Vector2) -> int:
	var from := _cam.project_ray_origin(mouse)
	var dir := _cam.project_ray_normal(mouse)
	if absf(dir.y) < 0.00001:
		return -1
	var t := -from.y / dir.y
	if t < 0.0:
		return -1
	var p := from + dir * t
	var best := -1
	var best_d := 0.7
	for n in _gs.map.nodes:
		var d := Vector2(n["pos"].x - p.x, n["pos"].z - p.z).length()
		if d < best_d:
			best_d = d
			best = n["id"]
	return best

func _on_board_click(mouse: Vector2) -> void:
	var nid := _node_under_cursor(mouse)
	if nid == -1:
		return
	if _deploy_uid != -1:
		if nid in _gs.free_entrances("player"):
			_player_deploy(_deploy_uid, nid)
		else:
			_reset_activation()
			_update_status()
		return
	if _active_uid != -1:
		if _reach.has(nid):
			_player_move(nid)
			return
		if _foe_nodes.has(nid):
			_player_attack(int(_foe_nodes[nid]))
			return
		var uid2: int = _gs.board.get(nid, -1)
		if uid2 != -1 and _gs.units[uid2]["team"] == "player" and not _committed:
			_activate_unit(uid2)
		return
	var uid: int = _gs.board.get(nid, -1)
	if uid != -1 and _gs.units[uid]["team"] == "player":
		_activate_unit(uid)

# ---------------------------------------------------------------- activation
func _begin_deploy(uid: int) -> void:
	if _busy or _over or _gs.turn_team != "player" or _committed:
		return
	_reset_activation()
	_deploy_uid = uid
	for e in _gs.free_entrances("player"):
		_set_highlight(e, HILITE_DEPLOY)
		_highlighted.append(e)
	_status.text = "Toca una entrada azul iluminada para desplegar a %s." % Roster.FIGURES[_gs.units[uid]["rindex"]]["name"]

func _activate_unit(uid: int) -> void:
	_deploy_uid = -1
	_active_uid = uid
	_remaining = int(_gs.units[uid]["stamina"])
	_refresh_active_highlights()
	_update_status()

func _refresh_active_highlights() -> void:
	_clear_highlights()
	_reach = {}
	_foe_nodes = {}
	if _active_uid == -1:
		return
	var node: int = _gs.units[_active_uid]["node"]
	if _remaining > 0:
		var blocked := {}
		for n in _gs.board.keys():
			if n != node:
				blocked[n] = true
		_reach = _gs.map.reachable(node, _remaining, blocked)
		for rid in _reach.keys():
			_set_highlight(rid, HILITE_MOVE)
			_highlighted.append(rid)
	if _gs.can_attack(_active_uid):
		for foe in _gs.adjacent_enemies(_active_uid):
			var fn: int = _gs.units[foe]["node"]
			_foe_nodes[fn] = foe
			_set_highlight(fn, HILITE_ATK)
			_highlighted.append(fn)

func _reset_activation() -> void:
	_active_uid = -1
	_remaining = 0
	_committed = false
	_deploy_uid = -1
	_reach = {}
	_foe_nodes = {}
	_clear_highlights()

func _clear_highlights() -> void:
	for nid in _highlighted:
		_set_highlight(nid, Color(0, 0, 0, 0))
	_highlighted.clear()

func _set_highlight(nid: int, col: Color) -> void:
	var mat: StandardMaterial3D = _node_mat[nid]
	if col.a > 0.0:
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 0.9
		mat.albedo_color = col.darkened(0.3)
	else:
		var role: String = _gs.map.role_of(nid)
		var base: Color = ROLE_COLOR.get(role, ROLE_COLOR["normal"])
		mat.albedo_color = base
		if role == "normal":
			mat.emission_enabled = false
		else:
			mat.emission = base
			mat.emission_energy_multiplier = 0.5

# ---------------------------------------------------------------- player actions
func _player_deploy(uid: int, node: int) -> void:
	_clear_highlights()
	_deploy_uid = -1
	_gs.deploy(uid, node)
	_spawn_vis(uid)
	_active_uid = uid
	_remaining = maxi(0, int(_gs.units[uid]["stamina"]) - 1)  # deploy costs 1
	_committed = true
	_refresh_bench_ui()
	await _resolve_surround()
	if _check_and_show_winner():
		return
	if _active_uid != -1 and not _gs.units[_active_uid]["alive"]:
		await _end_player_turn()
		return
	_refresh_active_highlights()
	_update_status()
	await _maybe_auto_end()

func _player_move(node: int) -> void:
	var cost: int = int(_reach[node])
	_clear_highlights()
	_busy = true
	_committed = true
	_refresh_bench_ui()
	_update_status()
	_gs.move_unit(_active_uid, node)
	_remaining -= cost
	await _walk_vis(_active_uid, _gs.map.pos_of(node))
	_busy = false
	if _check_and_show_winner():
		return
	await _resolve_surround()
	if _check_and_show_winner():
		return
	if _active_uid != -1 and not _gs.units[_active_uid]["alive"]:
		await _end_player_turn()
		return
	_refresh_active_highlights()
	_update_status()
	await _maybe_auto_end()

## After a committed action, if the active figure has no moves left and no enemy
## to attack, end the turn automatically.
func _maybe_auto_end() -> void:
	if _over or _busy or _gs.turn_team != "player":
		return
	if _committed and _reach.is_empty() and _foe_nodes.is_empty():
		await _end_player_turn()

func _player_has_actions() -> bool:
	if _gs.can_deploy("player"):
		return true
	for uid in _gs.units_on_board("player"):
		if not _gs.reachable_for(uid).is_empty():
			return true
		if _gs.can_attack(uid) and not _gs.adjacent_enemies(uid).is_empty():
			return true
	return false

func _refresh_status_labels() -> void:
	for uid in _status_lbls.keys():
		var lbl = _status_lbls[uid]
		if not is_instance_valid(lbl) or not _vis.has(uid) or not _gs.units.has(uid):
			continue
		var sl := _gs.status_list(uid)
		lbl.text = _status_text(sl)
		lbl.visible = not sl.is_empty()

func _status_text(list: Array) -> String:
	var parts := []
	for s in list:
		parts.append(STATUS_ES.get(s, s))
	return " · ".join(parts)

## Big dramatic effect word that pops over the affected figure, then fades.
func _dramatize_effect(uid: int, fx_text: String) -> void:
	var f: Figure3D = _vis.get(uid)
	if f == null:
		return
	var l := Label3D.new()
	l.text = "¡" + fx_text + "!"
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.pixel_size = 0.006
	l.font_size = 110
	l.outline_size = 22
	l.modulate = Color(1.0, 0.45, 1.0)
	l.position = Vector3(0, 2.6, 0)
	l.scale = Vector3(0.3, 0.3, 0.3)
	f.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector3(1.5, 1.5, 1.5), 0.25)
	tw.tween_interval(0.7)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)

func _player_attack(foe_uid: int) -> void:
	var att := _active_uid
	_clear_highlights()
	_busy = true
	_committed = true
	_update_status()
	var rec := _gs.attack(att, foe_uid)
	await _play_combat(att, foe_uid, rec)
	await _end_player_turn()

func _on_end_turn_pressed() -> void:
	if _busy or _over or _gs.turn_team != "player":
		return
	await _end_player_turn()

# ---------------------------------------------------------------- flow / bot
func _end_player_turn() -> void:
	_reset_activation()
	_busy = true
	_refresh_bench_ui()
	_gs.end_turn()
	_update_status()
	if _check_and_show_winner():
		return
	await _bot_loop()
	_busy = false
	_refresh_bench_ui()
	_update_status()

func _bot_loop() -> void:
	while _gs.winner == "" and _gs.turn_team == "enemy":
		var rec := _gs.bot_action("enemy")
		await _animate_bot(rec)
		if _check_and_show_winner():
			return
		_gs.end_turn()
		if _check_and_show_winner():
			return

func _animate_bot(rec: Dictionary) -> void:
	match String(rec.get("type", "pass")):
		"deploy":
			_spawn_vis(int(rec["uid"]))
			await get_tree().create_timer(0.3).timeout
			await _resolve_surround()
		"move":
			await _walk_vis(int(rec["uid"]), _gs.map.pos_of(int(rec["node"])))
			await _resolve_surround()
		"attack":
			await _play_combat(int(rec["att"]), int(rec["def"]), rec)
		_:
			await get_tree().create_timer(0.2).timeout

func _walk_vis(uid: int, target: Vector3) -> void:
	var fig: Figure3D = _vis[uid]
	_face(fig, target - fig.position)
	fig.play_clip("move_walk")
	var dur := maxf(0.3, fig.position.distance_to(target) * 0.28)
	var tw := create_tween()
	tw.tween_property(fig, "position", target, dur)
	await tw.finished
	fig.play_clip("idle")

# ---------------------------------------------------------------- combat
func _play_combat(att_uid: int, def_uid: int, rec: Dictionary) -> void:
	var a_name := _named(att_uid)
	var b_name := _named(def_uid)
	var a_col := _team_color(_gs.units[att_uid]["team"])
	var b_col := _team_color(_gs.units[def_uid]["team"])
	# Pre-combat windup on the board: face off + attacker winds up.
	var fa0: Figure3D = _vis.get(att_uid)
	var fb0: Figure3D = _vis.get(def_uid)
	if fa0 and fb0:
		_face(fa0, fb0.position - fa0.position)
		_face(fb0, fa0.position - fb0.position)
		fa0.play_clip("attack")
	await get_tree().create_timer(0.45).timeout
	var msg := _combat_msg(a_name, b_name, rec)
	# 1) the wheel (announce + spin + result)
	await _overlay.play(a_name, b_name, rec["seg_a"], rec["seg_b"], msg[0], msg[1],
		Roster.FIGURES[_gs.units[att_uid]["rindex"]]["attack"],
		Roster.FIGURES[_gs.units[def_uid]["rindex"]]["attack"], a_col, b_col)
	# 2) the close-up action shot
	await _combat_cutaway(att_uid, def_uid, rec)
	# 2.5) displacement (push / pull / swap), if any
	var disp: Dictionary = rec.get("disp", {})
	if not disp.is_empty():
		await _animate_displacement(disp)
	# 3) resolve KO removal (only real KOs)
	var ko: int = int(rec.get("ko", -1))
	if ko != -1 and _vis.has(ko):
		_vis[ko].queue_free()
		_vis.erase(ko)
		_status_lbls.erase(ko)
	_refresh_status_labels()
	await _resolve_surround()

## KO any figures that combat/movement just surrounded (enemies on every side).
func _resolve_surround() -> void:
	var koed := _gs.check_surround()
	if koed.is_empty():
		return
	for uid in koed:
		if _vis.has(uid):
			_vis[uid].play_clip("ko")
	await get_tree().create_timer(1.2).timeout
	for uid in koed:
		if _vis.has(uid):
			_vis[uid].queue_free()
			_vis.erase(uid)
			_status_lbls.erase(uid)
	_refresh_status_labels()

func _animate_displacement(disp: Dictionary) -> void:
	match String(disp.get("type", "")):
		"swap":
			var fa: Figure3D = _vis.get(int(disp["a"]))
			var fb: Figure3D = _vis.get(int(disp["b"]))
			var ta := _gs.map.pos_of(int(disp["a_to"]))
			var tb := _gs.map.pos_of(int(disp["b_to"]))
			var tw := create_tween()
			tw.set_parallel(true)
			if fa:
				fa.play_clip("move_walk")
				tw.tween_property(fa, "position", ta, 0.4)
			if fb:
				fb.play_clip("move_walk")
				tw.tween_property(fb, "position", tb, 0.4)
			await tw.finished
			if fa:
				fa.play_clip("idle")
			if fb:
				fb.play_clip("idle")
		"push", "pull":
			var f: Figure3D = _vis.get(int(disp["uid"]))
			if f:
				var to := _gs.map.pos_of(int(disp["to"]))
				if f.position.distance_to(to) > 0.05:
					f.play_clip("move_walk")
					var tw2 := create_tween()
					tw2.tween_property(f, "position", to, 0.4)
					await tw2.finished
					f.play_clip("idle")

func _named(uid: int) -> String:
	var n: String = Roster.FIGURES[_gs.units[uid]["rindex"]]["name"]
	return n + ("  (tú)" if _gs.units[uid]["team"] == "player" else "  (rival)")

func _team_color(team: String) -> Color:
	return Color(0.45, 0.7, 1.0) if team == "player" else Color(1.0, 0.5, 0.45)

func _combat_msg(a_name: String, b_name: String, rec: Dictionary) -> Array:
	var r: int = int(rec["result"])
	if r == 0:
		return ["Empate — nadie cae", Color(1, 1, 1)]
	var winner := a_name if r > 0 else b_name
	var loser := b_name if r > 0 else a_name
	if int(rec.get("ko", -1)) != -1:
		return ["%s vence — %s ¡KO!" % [winner, loser], Color(0.6, 1.0, 0.7)]
	match String(rec.get("win_col", "")):
		"purple":
			return ["%s gana (Morado) — %s: %s. ¡No cae!" % [winner, loser, rec.get("effect", "Estado")], Color(0.78, 0.55, 1.0)]
		"blue":
			return ["%s bloquea (Azul) — nadie cae" % winner, Color(0.45, 0.65, 1.0)]
		_:
			return ["%s gana — %s resiste" % [winner, loser], Color(1, 1, 1)]

func _combat_cutaway(att_uid: int, def_uid: int, rec: Dictionary) -> void:
	var fa: Figure3D = _vis.get(att_uid)
	var fb: Figure3D = _vis.get(def_uid)
	if fa == null or fb == null:
		return
	var pa := fa.global_position
	var pb := fb.global_position
	var m := (pa + pb) * 0.5
	var dir := pb - pa
	dir.y = 0.0
	if dir.length() < 0.01:
		dir = Vector3(0, 0, 1)
	dir = dir.normalized()
	var side := dir.cross(Vector3.UP).normalized()
	var sep := pa.distance_to(pb)
	# Hide the other figures so they don't block the shot.
	for uid in _vis.keys():
		if uid != att_uid and uid != def_uid:
			_vis[uid].visible = false
	# 3/4 side angle, backed off a bit more to frame BOTH fighters.
	var cam_pos := m + side * (sep + 4.3) + Vector3(0, 2.0, 0)
	_combat_cam.look_at_from_position(cam_pos, m + Vector3(0, 0.9, 0), Vector3.UP)
	_combat_cam.current = true
	_face(fa, pb - pa)
	_face(fb, pa - pb)
	fa.play_clip("attack")
	await get_tree().create_timer(0.65).timeout
	var ko: int = int(rec.get("ko", -1))
	if ko != -1:
		var winner_uid := def_uid if ko == att_uid else att_uid
		if _vis.has(winner_uid):
			_vis[winner_uid].play_clip("attack_heavy")
		if _vis.has(ko):
			_vis[ko].play_clip("ko")
		await get_tree().create_timer(2.5).timeout      # hold so the KO is appreciated
	else:
		# Survives: defender blocks (Blue) or flinches, then both return to idle.
		if _vis.has(def_uid):
			_vis[def_uid].play_clip("defend" if String(rec.get("win_col", "")) == "blue" else "hit")
		# Drama: pop the applied effect over the affected figure.
		var st: Dictionary = rec.get("status", {})
		if not st.is_empty():
			_dramatize_effect(int(st["target"]), String(st.get("fx", "Estado")))
		await get_tree().create_timer(1.9).timeout
		if _vis.has(att_uid):
			_vis[att_uid].play_clip("idle")
		if _vis.has(def_uid):
			_vis[def_uid].play_clip("idle")
		await get_tree().create_timer(0.6).timeout
	# Restore the others.
	for uid in _vis.keys():
		if uid != att_uid and uid != def_uid:
			_vis[uid].visible = true
	_cam.current = true

# ---------------------------------------------------------------- victory
func _check_and_show_winner() -> bool:
	if _gs.winner == "":
		return false
	_show_winner(_gs.winner)
	return true

func _show_winner(team: String) -> void:
	_over = true
	_busy = true
	_reset_activation()
	_end_btn.visible = false
	var l := Label.new()
	l.set_anchors_preset(Control.PRESET_CENTER)
	l.add_theme_font_size_override("font_size", 48)
	l.text = "¡GANASTE!" if team == "player" else "Derrota…"
	l.modulate = Color(0.6, 1, 0.7) if team == "player" else Color(1, 0.6, 0.6)
	var cl := CanvasLayer.new()
	cl.layer = 20
	add_child(cl)
	cl.add_child(l)
	_status.text = "Fin de la partida."
