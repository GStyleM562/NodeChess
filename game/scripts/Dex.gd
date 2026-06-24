extends Node3D
## Dex / library: browse each roster figure — its 3D model (turntable), attack
## TYPE, and its ACTUAL attack pool with probabilities. Lets you verify every
## figure really uses its own attacks (not random/mismatched ones).

var _index := 0
var _current: Figure3D
var _pivot: Node3D
var _cam: Camera3D
var _name_label: Label
var _type_label: Label
var _attacks_box: VBoxContainer

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	_build_env()
	_build_ui()
	_spawn(0)

func _process(delta: float) -> void:
	if _pivot != null:
		_pivot.rotate_y(delta * 0.6)

func _build_env() -> void:
	_cam = Camera3D.new()
	_cam.keep_aspect = Camera3D.KEEP_WIDTH
	_cam.fov = 24.0
	_cam.look_at_from_position(Vector3(0.0, 1.35, 3.8), Vector3(0.0, 1.05, 0.0), Vector3.UP)
	add_child(_cam)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -40.0, 0.0)
	sun.light_energy = 1.3
	add_child(sun)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.07, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.6, 0.8)
	env.ambient_light_energy = 0.75
	we.environment = env
	add_child(we)
	var base := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.6
	disc.bottom_radius = 0.62
	disc.height = 0.06
	base.mesh = disc
	base.position = Vector3(0.0, -0.03, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.18, 0.26)
	base.material_override = mat
	add_child(base)
	_pivot = Node3D.new()
	add_child(_pivot)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var top := VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = 16
	top.offset_left = 12
	top.offset_right = -12
	layer.add_child(top)
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 30)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(_name_label)
	_type_label = Label.new()
	_type_label.add_theme_font_size_override("font_size", 20)
	_type_label.modulate = Color(0.8, 0.85, 1.0)
	_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(_type_label)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -372
	panel.offset_bottom = -72
	panel.offset_left = 10
	panel.offset_right = -10
	layer.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)
	var hdr := Label.new()
	hdr.text = "Ataques (probabilidad):"
	hdr.add_theme_font_size_override("font_size", 20)
	vb.add_child(hdr)
	_attacks_box = VBoxContainer.new()
	_attacks_box.add_theme_constant_override("separation", 4)
	vb.add_child(_attacks_box)

	var nav := HBoxContainer.new()
	nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav.offset_top = -60
	nav.offset_bottom = -14
	nav.offset_left = 10
	nav.offset_right = -10
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 16)
	layer.add_child(nav)
	var prev := Button.new()
	prev.text = "◀"
	prev.custom_minimum_size = Vector2(70, 46)
	prev.pressed.connect(func(): _switch(-1))
	nav.add_child(prev)
	var menu := Button.new()
	menu.text = "Menú"
	menu.custom_minimum_size = Vector2(130, 46)
	menu.pressed.connect(_to_menu)
	nav.add_child(menu)
	var nxt := Button.new()
	nxt.text = "▶"
	nxt.custom_minimum_size = Vector2(70, 46)
	nxt.pressed.connect(func(): _switch(1))
	nav.add_child(nxt)

func _spawn(i: int) -> void:
	if _current != null:
		_current.queue_free()
		_current = null
	var data: Dictionary = Roster.FIGURES[i]
	_current = Figure3D.new()
	_pivot.add_child(_current)
	_current.setup(data["glb"], data["clips"], float(data.get("size", 1.0)))
	_current.play_clip("idle")
	_name_label.text = "%d/%d   %s" % [i + 1, Roster.FIGURES.size(), data["name"]]
	var warn := "   ⚠ anim incompleta" if not data.get("complete", true) else ""
	_type_label.text = "Tipo de ataque: " + String(data.get("type", "?")) + warn
	_build_attacks(data["attack"])

func _build_attacks(pool: Array) -> void:
	for c in _attacks_box.get_children():
		c.queue_free()
	var total := 0.0
	for s in pool:
		total += float(s.get("w", 1.0))
	for s in pool:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var sw := ColorRect.new()
		sw.custom_minimum_size = Vector2(26, 26)
		sw.color = Combat.color_of(s)
		row.add_child(sw)
		var pct := 100.0 * float(s.get("w", 1.0)) / total
		var txt := "%s   —   %.0f%%" % [Combat.label(s), pct]
		if s.has("fx"):
			txt += "   [" + String(s["fx"]) + "]"
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.text = txt
		row.add_child(lbl)
		_attacks_box.add_child(row)

func _switch(d: int) -> void:
	_index = wrapi(_index + d, 0, Roster.FIGURES.size())
	_spawn(_index)

func _to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if (event as InputEventKey).keycode == KEY_RIGHT:
			_switch(1)
		elif (event as InputEventKey).keycode == KEY_LEFT:
			_switch(-1)
