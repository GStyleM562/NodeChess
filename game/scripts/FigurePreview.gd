extends Node3D
## Figure viewer: shows each roster figure on a base, auto-frames the camera,
## auto-plays idle, and lets you cycle figures and play any Tier 1 clip.

const TIER1 := ["idle", "move_walk", "move_run", "attack", "attack_heavy", "defend", "hit", "ko"]

var _index := 0
var _current: Figure3D
var _pivot: Node3D
var _cam: Camera3D
var _name_label: Label
var _clip_label: Label
var _turntable := true

func _ready() -> void:
	_build_environment()
	_build_ui()
	_spawn(_index)

func _process(delta: float) -> void:
	if _turntable and _pivot != null:
		_pivot.rotate_y(delta * 0.6)

# ---------------------------------------------------------------- scene setup
func _build_environment() -> void:
	_cam = Camera3D.new()
	_cam.fov = 45.0
	_cam.position = Vector3(0.0, 0.9, 3.5)
	add_child(_cam)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -40.0, 0.0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	add_child(sun)

	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.08, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.6, 0.8)
	env.ambient_light_energy = 0.7
	we.environment = env
	add_child(we)

	# Node "base" disc (chibi figures stand on a pedestal, like a board node)
	var base := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.55
	disc.bottom_radius = 0.6
	disc.height = 0.06
	base.mesh = disc
	base.position = Vector3(0.0, -0.03, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.18, 0.26)
	base.material_override = mat
	add_child(base)

	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	add_child(_pivot)

func _frame_camera(fig: Figure3D) -> void:
	var half_h := maxf(fig.view_height * 0.5, fig.view_radius)
	var dist := half_h / tan(deg_to_rad(_cam.fov * 0.5)) * 1.45 + fig.view_radius + 0.3
	_cam.position = Vector3(0.0, fig.view_center_y, dist)
	_cam.look_at(Vector3(0.0, fig.view_center_y, 0.0), Vector3.UP)

# ---------------------------------------------------------------- ui
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var header := VBoxContainer.new()
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 12
	header.offset_top = 10
	header.offset_right = -12
	layer.add_child(header)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 26)
	header.add_child(_name_label)

	_clip_label = Label.new()
	_clip_label.add_theme_font_size_override("font_size", 18)
	_clip_label.modulate = Color(0.75, 0.85, 1.0)
	header.add_child(_clip_label)

	var footer := VBoxContainer.new()
	footer.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = 12
	footer.offset_top = -180
	footer.offset_right = -12
	footer.offset_bottom = -12
	footer.alignment = BoxContainer.ALIGNMENT_END
	layer.add_child(footer)

	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_child(nav)
	var prev_btn := Button.new()
	prev_btn.text = "◀ Prev"
	prev_btn.pressed.connect(func(): _switch(-1))
	nav.add_child(prev_btn)
	var next_btn := Button.new()
	next_btn.text = "Next ▶"
	next_btn.pressed.connect(func(): _switch(1))
	nav.add_child(next_btn)
	var spin_btn := Button.new()
	spin_btn.text = "Turntable"
	spin_btn.toggle_mode = true
	spin_btn.button_pressed = true
	spin_btn.toggled.connect(func(on): _turntable = on)
	nav.add_child(spin_btn)

	var clips := HFlowContainer.new()
	clips.alignment = FlowContainer.ALIGNMENT_CENTER
	footer.add_child(clips)
	for clip_name in TIER1:
		var b := Button.new()
		b.text = clip_name
		b.pressed.connect(_play_clip.bind(clip_name))
		clips.add_child(b)

# ---------------------------------------------------------------- logic
func _spawn(i: int) -> void:
	if _current != null:
		_current.queue_free()
		_current = null
	var data: Dictionary = Roster.FIGURES[i]
	_current = Figure3D.new()
	_pivot.add_child(_current)
	var ok := _current.setup(data["glb"], data["clips"], float(data.get("size", 1.0)))
	var warn := "" if data.get("complete", true) else "   ⚠ anim incompleta"
	_name_label.text = "%d/%d   %s%s" % [i + 1, Roster.FIGURES.size(), data["name"], warn]
	if not ok:
		_clip_label.text = "ERROR: no se pudo cargar el modelo"
		return
	_frame_camera(_current)
	_play_clip("idle")

func _switch(dir: int) -> void:
	_index = wrapi(_index + dir, 0, Roster.FIGURES.size())
	_spawn(_index)

func _play_clip(clip_name: String) -> void:
	if _current == null:
		return
	if _current.has_clip(clip_name):
		_current.play_clip(clip_name)
		_clip_label.text = "clip: " + clip_name
	else:
		_clip_label.text = "clip: " + clip_name + "  (no disponible en esta figura)"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_RIGHT:
				_switch(1)
			KEY_LEFT:
				_switch(-1)
			KEY_SPACE:
				_play_clip("idle")
