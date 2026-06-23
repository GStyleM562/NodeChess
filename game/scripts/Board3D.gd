extends Node3D
## Procedural 3D board: builds nodes + paths from MapData, places team figures on
## nodes, and supports tap-to-select + move within stamina (BFS) with a walk
## animation. No rules yet — this is the playable shell to prove board + figures
## + animation feel. Cosmetic terrain (Meshy) comes later as a skin.

const ROLE_COLOR := {
	"normal": Color(0.20, 0.22, 0.30),
	"entrance_player": Color(0.20, 0.45, 0.95),
	"entrance_enemy": Color(0.95, 0.35, 0.30),
	"goal_player": Color(0.30, 0.85, 0.50),
	"goal_enemy": Color(0.98, 0.80, 0.25),
	"buff": Color(1.0, 0.6, 0.2),
}
const HILITE := Color(0.35, 1.0, 0.5)
# Models face +Z by default; flip if they end up looking backwards.
const FACE_OFFSET := 0.0

# Per-figure stamina (moves to Roster/rules engine later).
const STAMINA := {
	"stone_golem": 1, "ironclad_knight": 2, "nightblade": 3,
	"rift_mage": 2, "venom_witch": 2, "storm_valkyrie": 4,
}

var _map: MapData
var _cam: Camera3D
var _node_mi := {}            # node id -> MeshInstance3D (disc)
var _node_mat := {}           # node id -> StandardMaterial3D
var _occ := {}                # node id -> Figure3D
var _fig_node := {}           # Figure3D -> node id
var _team := {}               # Figure3D -> "player"/"enemy"
var _stam := {}               # Figure3D -> int
var _selected: Figure3D = null
var _reach := {}              # node id -> dist (current selection)
var _highlighted: Array = []
var _busy := false
var _label: Label

func _ready() -> void:
	_build_environment()
	_map = MapData.new(5, 7, 1.35)
	_build_board()
	_place_figures()
	_build_ui()
	var conns := 0
	for id in _map.adj:
		conns += _map.adj[id].size()
	print("[Board] nodes=%d conns=%d figures=%d" % [_map.nodes.size(), conns / 2, _fig_node.size()])

# ---------------------------------------------------------------- environment
func _build_environment() -> void:
	_cam = Camera3D.new()
	_cam.fov = 45.0
	_cam.look_at_from_position(Vector3(0.0, 9.0, 8.5), Vector3(0.0, 0.0, 0.0), Vector3.UP)
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
	# connections (draw each undirected pair once)
	var seen := {}
	for id in _map.adj:
		for nb in _map.adj[id]:
			var key := mini(id, nb) * 10000 + maxi(id, nb)
			if seen.has(key):
				continue
			seen[key] = true
			_make_line(_map.pos_of(id), _map.pos_of(nb))
	# nodes
	for n in _map.nodes:
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
	mat.albedo_color = Color(0.35, 0.45, 0.7, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.45, 0.8)
	mat.emission_energy_multiplier = 0.3
	mi.material_override = mat
	var mid := (a + b) * 0.5 + Vector3(0, 0.02, 0)
	mi.look_at_from_position(mid, b + Vector3(0, 0.02, 0), Vector3.UP)
	add_child(mi)

# ---------------------------------------------------------------- figures
func _place_figures() -> void:
	var player_ids := [0, 1, 2]   # golem, knight, nightblade
	var enemy_ids := [3, 4, 5]    # rift_mage, venom_witch, valkyrie
	var p_nodes := [_map.id_at(1, 1), _map.id_at(2, 1), _map.id_at(3, 1)]
	var e_nodes := [_map.id_at(1, _map.rows - 2), _map.id_at(2, _map.rows - 2), _map.id_at(3, _map.rows - 2)]
	for i in 3:
		_spawn_figure(player_ids[i], p_nodes[i], "player")
		_spawn_figure(enemy_ids[i], e_nodes[i], "enemy")

func _spawn_figure(roster_index: int, node_id: int, team: String) -> void:
	var data: Dictionary = Roster.FIGURES[roster_index]
	var fig := Figure3D.new()
	add_child(fig)
	fig.setup(data["glb"], data["clips"], float(data.get("size", 1.0)))
	fig.position = _map.pos_of(node_id)
	_face(fig, Vector3(0, 0, 1.0) if team == "player" else Vector3(0, 0, -1.0))
	_add_team_ring(fig, team)
	fig.play_clip("idle")
	_occ[node_id] = fig
	_fig_node[fig] = node_id
	_team[fig] = team
	_stam[fig] = STAMINA.get(data["id"], 2)

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

func _face(fig: Figure3D, dir: Vector3) -> void:
	if dir.length() < 0.001:
		return
	fig.rotation.y = atan2(dir.x, dir.z) + FACE_OFFSET

# ---------------------------------------------------------------- ui
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_label.offset_left = 12
	_label.offset_top = 10
	_label.add_theme_font_size_override("font_size", 20)
	_label.text = "Toca una figura azul, luego un nodo verde para moverla."
	layer.add_child(_label)

# ---------------------------------------------------------------- interaction
func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_on_click(mb.position)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(0.92)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(1.08)

func _zoom_camera(f: float) -> void:
	_cam.position = _cam.position * f

func _on_click(mouse: Vector2) -> void:
	var nid := _node_under_cursor(mouse)
	if nid == -1:
		_deselect()
		return
	if _occ.has(nid) and _team.get(_occ[nid]) == "player":
		_select(_occ[nid], nid)
	elif _selected != null and _reach.has(nid) and not _occ.has(nid):
		_move_selected(nid)
	else:
		_deselect()

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
	for n in _map.nodes:
		var d := Vector2(n["pos"].x - p.x, n["pos"].z - p.z).length()
		if d < best_d:
			best_d = d
			best = n["id"]
	return best

func _select(fig: Figure3D, nid: int) -> void:
	_deselect()
	_selected = fig
	var blocked := {}
	for occupied in _occ.keys():
		if occupied != nid:
			blocked[occupied] = true
	_reach = _map.reachable(nid, _stam.get(fig, 2), blocked)
	for rid in _reach.keys():
		_set_highlight(rid, true)
		_highlighted.append(rid)
	_label.text = "%s — stamina %d. Toca un nodo verde." % [_team.get(fig, "?"), _stam.get(fig, 2)]

func _deselect() -> void:
	_selected = null
	_reach = {}
	for rid in _highlighted:
		_set_highlight(rid, false)
	_highlighted.clear()

func _set_highlight(nid: int, on: bool) -> void:
	var mat: StandardMaterial3D = _node_mat[nid]
	if on:
		mat.emission_enabled = true
		mat.emission = HILITE
		mat.emission_energy_multiplier = 0.9
	else:
		var role: String = _map.role_of(nid)
		var col: Color = ROLE_COLOR.get(role, ROLE_COLOR["normal"])
		mat.albedo_color = col
		if role == "normal":
			mat.emission_enabled = false
		else:
			mat.emission = col
			mat.emission_energy_multiplier = 0.5

func _move_selected(nid: int) -> void:
	var fig := _selected
	var from_node: int = _fig_node[fig]
	var target := _map.pos_of(nid)
	_deselect()
	_busy = true
	_occ.erase(from_node)
	_face(fig, target - fig.position)
	fig.play_clip("move_walk")
	var dur: float = maxf(0.3, fig.position.distance_to(target) * 0.28)
	var tw := create_tween()
	tw.tween_property(fig, "position", target, dur)
	await tw.finished
	fig.play_clip("idle")
	_occ[nid] = fig
	_fig_node[fig] = nid
	_busy = false
	_label.text = "Movido. Toca otra figura azul."
