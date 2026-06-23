extends Node3D
## Layer 1 playable board. Reads the rules engine (GameState): figures start in a
## bench and are DEPLOYED from entrances; alternating 1-action turns; move; attack
## -> wheel combat (CombatOverlay) -> resolve -> KO bench. Enemy = simple bot.
## No surround-KO / rank-up / energy yet (later layers). Map is a test sandbox.

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

var _gs: GameState
var _cam: Camera3D
var _overlay: CombatOverlay
var _vis := {}                # uid -> Figure3D
var _node_mi := {}
var _node_mat := {}
var _selected_uid := -1
var _deploy_uid := -1
var _reach := {}
var _foe_nodes := {}          # node id -> foe uid
var _highlighted := []
var _busy := false
var _over := false
var _status: Label
var _bench_box: HBoxContainer

func _ready() -> void:
	randomize()
	_build_environment()
	_gs = GameState.new(MapData.new(5, 7, 1.35))
	for ri in [0, 1, 2]:
		_gs.add_to_bench("player", ri)
	for ri in [3, 4, 1]:
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
	_cam.fov = 45.0
	_cam.look_at_from_position(Vector3(0.0, 9.0, 8.5), Vector3.ZERO, Vector3.UP)
	add_child(_cam)
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
	for uid in bench:
		var b := Button.new()
		b.text = "Desplegar " + Roster.FIGURES[_gs.units[uid]["rindex"]]["name"]
		b.pressed.connect(_begin_deploy.bind(uid))
		_bench_box.add_child(b)

func _update_status() -> void:
	if _over:
		return
	if _gs.turn_team == "player":
		_status.text = "Tu turno — toca una figura, o despliega desde la banca."
	else:
		_status.text = "Turno del enemigo…"

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
		_cancel_selection()
		return
	if _deploy_uid != -1:
		if nid in _gs.free_entrances("player"):
			_player_deploy(_deploy_uid, nid)
		else:
			_cancel_selection()
			_update_status()
		return
	if _selected_uid != -1:
		if _reach.has(nid):
			_player_move(_selected_uid, nid)
			return
		if _foe_nodes.has(nid):
			_player_attack(_selected_uid, _foe_nodes[nid])
			return
	var uid: int = _gs.board.get(nid, -1)
	if uid != -1 and _gs.units[uid]["team"] == "player":
		_select_unit(uid)
	else:
		_cancel_selection()

func _begin_deploy(uid: int) -> void:
	if _busy or _over or _gs.turn_team != "player":
		return
	_cancel_selection()
	_deploy_uid = uid
	for e in _gs.free_entrances("player"):
		_set_highlight(e, HILITE_DEPLOY)
		_highlighted.append(e)
	_status.text = "Toca una entrada azul iluminada para desplegar."

func _select_unit(uid: int) -> void:
	_cancel_selection()
	_selected_uid = uid
	_reach = _gs.reachable_for(uid)
	for rid in _reach.keys():
		_set_highlight(rid, HILITE_MOVE)
		_highlighted.append(rid)
	for foe in _gs.adjacent_enemies(uid):
		var fn: int = _gs.units[foe]["node"]
		_foe_nodes[fn] = foe
		_set_highlight(fn, HILITE_ATK)
		_highlighted.append(fn)
	_status.text = "%s — verde: mover · rojo: atacar." % Roster.FIGURES[_gs.units[uid]["rindex"]]["name"]

func _cancel_selection() -> void:
	_selected_uid = -1
	_deploy_uid = -1
	_reach = {}
	_foe_nodes = {}
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
	_cancel_selection()
	_busy = true
	_gs.deploy(uid, node)
	_spawn_vis(uid)
	_refresh_bench_ui()
	await get_tree().create_timer(0.2).timeout
	await _advance_after_action()

func _player_move(uid: int, node: int) -> void:
	_cancel_selection()
	_busy = true
	_gs.move_unit(uid, node)
	await _walk_vis(uid, _gs.map.pos_of(node))
	await _advance_after_action()

func _player_attack(att_uid: int, def_uid: int) -> void:
	_cancel_selection()
	_busy = true
	var rec := _gs.attack(att_uid, def_uid)
	await _play_combat(att_uid, def_uid, rec)
	await _advance_after_action()

# ---------------------------------------------------------------- flow / bot
func _advance_after_action() -> void:
	if _resolve_winner():
		return
	_gs.end_turn()
	_update_status()
	while _gs.winner == "" and _gs.turn_team == "enemy":
		var rec := _gs.bot_action("enemy")
		await _animate_bot(rec)
		if _resolve_winner():
			return
		_gs.end_turn()
		_update_status()
	_busy = false

func _animate_bot(rec: Dictionary) -> void:
	match String(rec.get("type", "pass")):
		"deploy":
			_spawn_vis(int(rec["uid"]))
			_refresh_bench_ui()
			await get_tree().create_timer(0.3).timeout
		"move":
			await _walk_vis(int(rec["uid"]), _gs.map.pos_of(int(rec["node"])))
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

func _play_combat(att_uid: int, def_uid: int, rec: Dictionary) -> void:
	var fa: Figure3D = _vis.get(att_uid)
	var fb: Figure3D = _vis.get(def_uid)
	if fa and fb:
		_face(fa, fb.position - fa.position)
		_face(fb, fa.position - fb.position)
		fa.play_clip("attack")
		fb.play_clip("attack")
	var a_name: String = Roster.FIGURES[_gs.units[att_uid]["rindex"]]["name"]
	var b_name: String = Roster.FIGURES[_gs.units[def_uid]["rindex"]]["name"]
	await _overlay.play(a_name, b_name, rec["seg_a"], rec["seg_b"], int(rec["result"]),
		Roster.FIGURES[_gs.units[att_uid]["rindex"]]["attack"],
		Roster.FIGURES[_gs.units[def_uid]["rindex"]]["attack"])
	var ko: int = int(rec.get("ko", -1))
	if ko != -1:
		var winner_uid := def_uid if ko == att_uid else att_uid
		if _vis.has(winner_uid):
			_vis[winner_uid].play_clip("idle")
		if _vis.has(ko):
			_vis[ko].play_clip("ko")
			await get_tree().create_timer(1.0).timeout
			_vis[ko].queue_free()
			_vis.erase(ko)
	else:
		if fa:
			fa.play_clip("idle")
		if fb:
			fb.play_clip("idle")

# ---------------------------------------------------------------- victory
func _resolve_winner() -> bool:
	if _gs.winner == "":
		return false
	_show_winner(_gs.winner)
	return true

func _show_winner(team: String) -> void:
	_over = true
	_busy = true
	_cancel_selection()
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
