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
var _passives_box: VBoxContainer
var _evos_box: VBoxContainer

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
	env.background_color = UITheme.BG_DEEP
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
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(_name_label, 28, UITheme.TEXT, true, 800)
	top.add_child(_name_label)
	_type_label = Label.new()
	_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(_type_label, 18, UITheme.PRIMARY_EDGE, true, 600)
	top.add_child(_type_label)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -468
	panel.offset_bottom = -72
	panel.offset_left = 10
	panel.offset_right = -10
	panel.add_theme_stylebox_override("panel", UITheme.panel(Color(0.08, 0.09, 0.16, 0.97), UITheme.BORDER, 16, 1, 10))
	layer.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 6)
	scroll.add_child(vb)

	vb.add_child(_dex_hdr("PASIVAS"))
	_passives_box = VBoxContainer.new()
	_passives_box.add_theme_constant_override("separation", 4)
	vb.add_child(_passives_box)

	vb.add_child(_dex_hdr("EVOLUCIONES · RANK UP"))
	_evos_box = VBoxContainer.new()
	_evos_box.add_theme_constant_override("separation", 4)
	vb.add_child(_evos_box)

	vb.add_child(_dex_hdr("ATAQUES · probabilidad"))
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
	prev.custom_minimum_size = Vector2(64, 48)
	UITheme.button_font(prev, 20, UITheme.TEXT, true, 700)
	UITheme.style_surface(prev, UITheme.SURFACE, UITheme.BORDER, 12)
	prev.pressed.connect(func(): _switch(-1))
	nav.add_child(prev)
	var menu := Button.new()
	menu.text = "Menú"
	menu.custom_minimum_size = Vector2(140, 48)
	UITheme.button_font(menu, 20, UITheme.TEXT2, true, 700)
	UITheme.style_surface(menu, UITheme.SURFACE, UITheme.BORDER, 12)
	menu.pressed.connect(_to_menu)
	nav.add_child(menu)
	var nxt := Button.new()
	nxt.text = "▶"
	nxt.custom_minimum_size = Vector2(64, 48)
	UITheme.button_font(nxt, 20, UITheme.TEXT, true, 700)
	UITheme.style_surface(nxt, UITheme.SURFACE, UITheme.BORDER, 12)
	nxt.pressed.connect(func(): _switch(1))
	nav.add_child(nxt)

func _dex_hdr(text: String) -> Label:
	var l := Label.new()
	l.text = text
	UITheme.label(l, 14, UITheme.MUTED, true, 700)
	return l

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
	_build_passives(data)
	_build_evolutions(data)
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

func _build_passives(d: Dictionary) -> void:
	for c in _passives_box.get_children():
		c.queue_free()
	var ids: Array = (d.get("passives", []) as Array).duplicate()
	# Include hidden passives from evolution stages (catalog marks them "(oculta)").
	for st in d.get("ranks", []):
		for h in st.get("hidden", []):
			if h not in ids:
				ids.append(h)
	if ids.is_empty():
		var l := Label.new()
		l.text = "—  (sin pasivas)"
		l.modulate = Color(0.6, 0.6, 0.7)
		l.add_theme_font_size_override("font_size", 16)
		_passives_box.add_child(l)
		return
	for pid in ids:
		var info: Dictionary = Roster.PASSIVES.get(pid, {})
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.text = "• %s — %s" % [String(info.get("name", pid)), String(info.get("desc", ""))]
		_passives_box.add_child(lbl)

func _build_evolutions(d: Dictionary) -> void:
	for c in _evos_box.get_children():
		c.queue_free()
	var ranks: Array = d.get("ranks", [])
	if ranks.is_empty():
		var l := Label.new()
		l.text = "—  (no evoluciona)"
		l.modulate = Color(0.6, 0.6, 0.7)
		l.add_theme_font_size_override("font_size", 16)
		_evos_box.add_child(l)
		return
	_evo_row("Base: %s · %s · ST %d" % [d["name"], String(d.get("type", "?")), int(d.get("stamina", 2))])
	for i in ranks.size():
		var st: Dictionary = ranks[i]
		_evo_row("+%d: %s · %s · ST %d" % [
			i + 1, String(st.get("name", "?")), String(st.get("type", d.get("type", "?"))), int(st.get("stamina", d.get("stamina", 2)))])

func _evo_row(text: String) -> void:
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.text = "• " + text
	_evos_box.add_child(lbl)

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
