extends Node3D
## HOME screen — BASE design (Pokémon-Duel identity + Clash-Royale usability, per
## GDD Part 5 §2). Painted structure with placeholders: top bar (avatar, currencies,
## energy), a 3D character centerpiece (deck leader), reward/gift slots (cards/boxes/
## chests — undecided), primary buttons, and a bottom nav. Functional: Jugar, Mazos,
## Colección, Probar. Placeholders show a "Próximamente" toast. Claude Design later
## makes it pretty; here we leave the slots/layout ready.

var _pivot: Node3D
var _leader: Figure3D
var _toast: Label

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	_build_env()
	_build_ui()

func _process(delta: float) -> void:
	if _pivot != null:
		_pivot.rotate_y(delta * 0.4)

# ----------------------------------------------------------------- 3D centerpiece
func _build_env() -> void:
	var cam := Camera3D.new()
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	cam.fov = 26.0
	cam.look_at_from_position(Vector3(0.0, 1.5, 4.0), Vector3(0.0, 1.15, 0.0), Vector3.UP)
	add_child(cam)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -35, 0)
	sun.light_energy = 1.3
	add_child(sun)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.08, 0.16)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.55, 0.85)
	env.ambient_light_energy = 0.8
	we.environment = env
	add_child(we)
	# pedestal
	var base := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.85
	disc.bottom_radius = 0.95
	disc.height = 0.12
	base.mesh = disc
	base.position = Vector3(0, -0.06, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.2, 0.32)
	mat.metallic = 0.4
	base.material_override = mat
	add_child(base)
	_pivot = Node3D.new()
	add_child(_pivot)
	# deck leader
	var lead := 0
	if not Loadout.player_team.is_empty():
		lead = clampi(int(Loadout.player_team[0]), 0, Roster.FIGURES.size() - 1)
	var d: Dictionary = Roster.FIGURES[lead]
	_leader = Figure3D.new()
	_pivot.add_child(_leader)
	_leader.setup(d["glb"], d["clips"], float(d.get("size", 1.0)))
	_leader.play_clip("idle")

# ----------------------------------------------------------------- UI
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	# --- Top bar (avatar · name/level · currencies · energy · settings)
	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 76
	top.add_theme_stylebox_override("panel", _panel(Color(0.10, 0.11, 0.18, 0.96), Color(0.3, 0.35, 0.6)))
	layer.add_child(top)
	var tb := HBoxContainer.new()
	tb.add_theme_constant_override("separation", 8)
	top.add_child(tb)
	tb.add_child(_avatar())
	var who := VBoxContainer.new()
	who.add_theme_constant_override("separation", 0)
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nm := _lbl("Jugador", 18, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	who.add_child(nm)
	who.add_child(_lbl("Nivel 1", 13, Color(0.7, 0.8, 1.0), HORIZONTAL_ALIGNMENT_LEFT))
	tb.add_child(who)
	tb.add_child(_chip("🪙", "1,250", Color(1.0, 0.82, 0.3)))
	tb.add_child(_chip("💎", "30", Color(0.5, 0.85, 1.0)))
	tb.add_child(_chip("⚡", "8/10", Color(0.7, 1.0, 0.5)))
	tb.add_child(_icon_btn("⚙"))

	# --- Centerpiece caption
	var lead := 0
	if not Loadout.player_team.is_empty():
		lead = clampi(int(Loadout.player_team[0]), 0, Roster.FIGURES.size() - 1)
	var cap := _lbl("★ Líder: " + String(Roster.FIGURES[lead]["name"]) + " ★", 20, Color(1.0, 0.88, 0.5))
	cap.set_anchors_preset(Control.PRESET_TOP_WIDE)
	cap.offset_top = 88
	layer.add_child(cap)

	var title := _lbl("NodeChess", 40, Color(1, 1, 1))
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 120
	title.modulate = Color(0.9, 0.92, 1.0)
	layer.add_child(title)

	# --- Reward / gift slots (cards / boxes / chests — undecided, base only)
	var gifts_hdr := _lbl("Regalos (diseño base — cartas / cajas / cofres)", 13, Color(0.7, 0.75, 0.9))
	gifts_hdr.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	gifts_hdr.offset_top = -416
	gifts_hdr.offset_bottom = -396
	layer.add_child(gifts_hdr)
	var gifts := HBoxContainer.new()
	gifts.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	gifts.offset_top = -392
	gifts.offset_bottom = -300
	gifts.alignment = BoxContainer.ALIGNMENT_CENTER
	gifts.add_theme_constant_override("separation", 10)
	layer.add_child(gifts)
	gifts.add_child(_gift_slot("🎁", "Listo"))
	gifts.add_child(_gift_slot("🎁", "2h 14m"))
	gifts.add_child(_gift_slot("🔒", "Bloq."))
	gifts.add_child(_gift_slot("➕", "Vacío"))

	# --- Primary buttons
	var play := _big_button("▶  JUGAR", Color(0.25, 0.65, 1.0))
	play.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	play.offset_top = -288
	play.offset_bottom = -214
	play.offset_left = 24
	play.offset_right = -24
	play.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/deck_builder.tscn"))
	layer.add_child(play)

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_top = -200
	row.offset_bottom = -140
	row.offset_left = 14
	row.offset_right = -14
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	layer.add_child(row)
	row.add_child(_menu_button("🃏\nMazos", func(): get_tree().change_scene_to_file("res://scenes/deck_builder.tscn")))
	row.add_child(_menu_button("📖\nColección", func(): get_tree().change_scene_to_file("res://scenes/dex.tscn")))
	row.add_child(_menu_button("🎲\nProbar", func(): get_tree().change_scene_to_file("res://scenes/attack_tester.tscn")))
	row.add_child(_menu_button("🛍\nTienda", _soon))
	row.add_child(_menu_button("🏆\nEventos", _soon))

	# --- Bottom nav bar
	var nav := PanelContainer.new()
	nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav.offset_top = -64
	nav.add_theme_stylebox_override("panel", _panel(Color(0.09, 0.10, 0.16, 0.98), Color(0.25, 0.3, 0.5)))
	layer.add_child(nav)
	var nb := HBoxContainer.new()
	nb.alignment = BoxContainer.ALIGNMENT_CENTER
	nb.add_theme_constant_override("separation", 26)
	nav.add_child(nb)
	nb.add_child(_nav_btn("🏠\nHome", func(): pass))
	nb.add_child(_nav_btn("🛍\nTienda", _soon))
	nb.add_child(_nav_btn("📖\nColección", func(): get_tree().change_scene_to_file("res://scenes/dex.tscn")))
	nb.add_child(_nav_btn("👤\nPerfil", _soon))

	# --- Toast (for placeholder taps)
	_toast = _lbl("", 22, Color(1, 0.9, 0.5))
	_toast.set_anchors_preset(Control.PRESET_CENTER)
	_toast.offset_top = 40
	_toast.visible = false
	layer.add_child(_toast)

func _soon() -> void:
	if _toast == null:
		return
	_toast.text = "Próximamente (base de diseño)"
	_toast.visible = true
	var t := get_tree().create_timer(1.4)
	t.timeout.connect(func(): if is_instance_valid(_toast): _toast.visible = false)

# ----------------------------------------------------------------- widgets
func _panel(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(10)
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_content_margin_all(8)
	return sb

func _avatar() -> Control:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(54, 54)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.3, 0.5, 0.9)
	sb.set_corner_radius_all(27)
	sb.border_color = Color(0.8, 0.9, 1.0)
	sb.set_border_width_all(3)
	p.add_theme_stylebox_override("panel", sb)
	var l := _lbl("P1", 18, Color.WHITE)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p

func _chip(icon: String, value: String, col: Color) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _panel(Color(0.05, 0.06, 0.12, 0.95), col.darkened(0.2)))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 3)
	p.add_child(h)
	h.add_child(_lbl(icon, 16, col))
	h.add_child(_lbl(value, 15, Color.WHITE))
	return p

func _icon_btn(icon: String) -> Button:
	var b := Button.new()
	b.text = icon
	b.custom_minimum_size = Vector2(44, 44)
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(_soon)
	return b

func _gift_slot(icon: String, state: String) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(110, 92)
	p.add_theme_stylebox_override("panel", _panel(Color(0.12, 0.13, 0.2, 0.96), Color(0.4, 0.42, 0.7)))
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(v)
	v.add_child(_lbl(icon, 34, Color(1.0, 0.85, 0.4)))
	v.add_child(_lbl(state, 13, Color(0.8, 0.85, 1.0)))
	var b := Button.new()
	b.flat = true
	b.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.pressed.connect(_soon)
	p.add_child(b)
	return p

func _big_button(text: String, col: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 30)
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(2)
	sb.border_color = col.lightened(0.4)
	b.add_theme_stylebox_override("normal", sb)
	var sb2 := sb.duplicate()
	sb2.bg_color = col.darkened(0.2)
	b.add_theme_stylebox_override("pressed", sb2)
	b.add_theme_stylebox_override("hover", sb)
	return b

func _menu_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(96, 58)
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_stylebox_override("normal", _panel(Color(0.14, 0.16, 0.26), Color(0.35, 0.4, 0.7)))
	b.pressed.connect(cb)
	return b

func _nav_btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.custom_minimum_size = Vector2(72, 52)
	b.add_theme_font_size_override("font_size", 14)
	b.pressed.connect(cb)
	return b

func _lbl(t: String, sz: int, col: Color, halign := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", sz)
	l.modulate = col
	l.horizontal_alignment = halign
	return l
