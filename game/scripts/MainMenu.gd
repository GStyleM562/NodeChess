extends Node3D
## HOME screen — Claude Design hi-fi (Pokémon Duel × Clash Royale). Top bar
## (avatar + currency pills + energy), 3D deck-leader centerpiece with a gold glow,
## reward/gift slots, a juicy PLAY button, secondary buttons and a bottom nav.
## Style only — scene routes and the 3D model are unchanged.

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
	sun.light_energy = 1.35
	add_child(sun)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = UITheme.BG_DEEP
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.5, 0.8)
	env.ambient_light_energy = 0.85
	we.environment = env
	add_child(we)
	var base := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.85
	disc.bottom_radius = 0.98
	disc.height = 0.12
	base.mesh = disc
	base.position = Vector3(0, -0.06, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.14, 0.17, 0.3)
	mat.metallic = 0.5
	mat.roughness = 0.4
	base.material_override = mat
	add_child(base)
	_pivot = Node3D.new()
	add_child(_pivot)
	var d: Dictionary = Roster.FIGURES[_lead()]
	_leader = Figure3D.new()
	_pivot.add_child(_leader)
	_leader.setup(d["glb"], d["clips"], float(d.get("size", 1.0)))
	_leader.play_clip("idle")

func _lead() -> int:
	if not Loadout.player_team.is_empty():
		return clampi(int(Loadout.player_team[0]), 0, Roster.FIGURES.size() - 1)
	return 0

# ----------------------------------------------------------------- UI
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var bg := ColorRect.new()              # vignette so the 3D blends into the UI
	bg.color = Color(UITheme.BG.r, UITheme.BG.g, UITheme.BG.b, 0.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(bg)

	# gold glow behind the leader
	var glow := _radial(UITheme.GOLD, 0.22)
	glow.set_anchors_preset(Control.PRESET_CENTER_TOP)
	glow.offset_left = -190
	glow.offset_right = 190
	glow.offset_top = 150
	glow.offset_bottom = 560
	layer.add_child(glow)

	_build_topbar(layer)
	_build_centerpiece(layer)
	_build_gifts(layer)
	_build_buttons(layer)
	_build_nav(layer)

	var ts := PanelContainer.new()
	ts.set_anchors_preset(Control.PRESET_CENTER)
	ts.offset_left = -150
	ts.offset_right = 150
	ts.offset_top = 50
	ts.offset_bottom = 92
	ts.add_theme_stylebox_override("panel", UITheme.panel(Color(0.08, 0.09, 0.16, 0.96), UITheme.GOLD.darkened(0.2), 12, 1, 8))
	ts.visible = false
	_toast = _lbl("", 18, UITheme.GOLD, true, 700)
	ts.add_child(_toast)
	layer.add_child(ts)
	_toast.set_meta("box", ts)

func _build_topbar(layer: CanvasLayer) -> void:
	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = 6
	top.offset_left = 6
	top.offset_right = -6
	top.offset_bottom = 70
	top.add_theme_stylebox_override("panel", UITheme.panel(Color(0.09, 0.10, 0.18, 0.97), UITheme.BORDER, 16, 1, 6))
	layer.add_child(top)
	var tb := HBoxContainer.new()
	tb.add_theme_constant_override("separation", 7)
	top.add_child(tb)
	tb.add_child(_avatar())
	var who := VBoxContainer.new()
	who.add_theme_constant_override("separation", 0)
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	who.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var nm := _lbl("Jugador", 17, UITheme.TEXT, true, 700)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	who.add_child(nm)
	var lv := _lbl("Nivel 1", 12, UITheme.TEXT2, false, 600)
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	who.add_child(lv)
	tb.add_child(who)
	tb.add_child(_chip("🪙", "1,250", UITheme.GOLD))
	tb.add_child(_chip("💎", "30", Color(0.5, 0.85, 1.0)))
	tb.add_child(_chip("⚡", "8", UITheme.ENERGY))
	tb.add_child(_icon_btn("⚙"))

func _build_centerpiece(layer: CanvasLayer) -> void:
	var d: Dictionary = Roster.FIGURES[_lead()]
	var title := _lbl("NodeChess", 34, Color(0.92, 0.94, 1.0), true, 800)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 86
	layer.add_child(title)
	# leader name + rarity pill (anchored mid)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	box.offset_left = -180
	box.offset_right = 180
	box.offset_top = 470
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	layer.add_child(box)
	box.add_child(_lbl(String(d["name"]), 25, UITheme.TEXT, true, 800))
	var rar := FigureCard.rarity_color(d)
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", UITheme.pill(Color(0.14, 0.11, 0.05), rar.darkened(0.3), 10))
	pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var pl := _lbl("★ LÍDER · " + FigureCard.rarity_name(d), 12, rar.lightened(0.2), true, 700)
	pill.add_child(pl)
	box.add_child(_center(pill))

func _build_gifts(layer: CanvasLayer) -> void:
	var hdr := _lbl("REGALOS  ·  cartas / cajas / cofres (base)", 11, UITheme.MUTED, true, 700)
	hdr.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hdr.offset_top = -420
	hdr.offset_bottom = -402
	layer.add_child(hdr)
	var gifts := HBoxContainer.new()
	gifts.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	gifts.offset_top = -398
	gifts.offset_bottom = -300
	gifts.alignment = BoxContainer.ALIGNMENT_CENTER
	gifts.add_theme_constant_override("separation", 10)
	layer.add_child(gifts)
	gifts.add_child(_gift_slot("🎁", "¡Listo!", UITheme.SUCCESS, UITheme.R_RARE))
	gifts.add_child(_gift_slot("🎁", "2h 14m", UITheme.TEXT2, UITheme.R_EPIC))
	gifts.add_child(_gift_slot("🔒", "Bloqueado", UITheme.MUTED, UITheme.BORDER))
	gifts.add_child(_gift_slot("➕", "Vacío", UITheme.MUTED, UITheme.BORDER))

func _build_buttons(layer: CanvasLayer) -> void:
	var play := _big_button("JUGAR", "Partida rápida")
	play.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	play.offset_top = -288
	play.offset_bottom = -212
	play.offset_left = 22
	play.offset_right = -22
	play.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/deck_builder.tscn"))
	layer.add_child(play)

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_top = -198
	row.offset_bottom = -138
	row.offset_left = 12
	row.offset_right = -12
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	layer.add_child(row)
	row.add_child(_menu_button("🃏", "Mazos", func(): get_tree().change_scene_to_file("res://scenes/deck_builder.tscn")))
	row.add_child(_menu_button("📖", "Colección", func(): get_tree().change_scene_to_file("res://scenes/dex.tscn")))
	row.add_child(_menu_button("🎲", "Probar", func(): get_tree().change_scene_to_file("res://scenes/attack_tester.tscn")))
	row.add_child(_menu_button("🛍", "Tienda", _soon))
	row.add_child(_menu_button("🏆", "Eventos", _soon))

func _build_nav(layer: CanvasLayer) -> void:
	var nav := PanelContainer.new()
	nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav.offset_top = -62
	nav.add_theme_stylebox_override("panel", UITheme.panel(Color(0.07, 0.08, 0.14, 0.99), UITheme.BORDER, 0, 1, 4))
	layer.add_child(nav)
	var nb := HBoxContainer.new()
	nb.alignment = BoxContainer.ALIGNMENT_CENTER
	nb.add_theme_constant_override("separation", 22)
	nav.add_child(nb)
	nb.add_child(_nav_btn("🏠", "Home", true, func(): pass))
	nb.add_child(_nav_btn("🛍", "Tienda", false, _soon))
	nb.add_child(_nav_btn("📖", "Colección", false, func(): get_tree().change_scene_to_file("res://scenes/dex.tscn")))
	nb.add_child(_nav_btn("🎲", "Probar", false, func(): get_tree().change_scene_to_file("res://scenes/attack_tester.tscn")))
	nb.add_child(_nav_btn("👤", "Perfil", false, _soon))

func _soon() -> void:
	var box = _toast.get_meta("box") if _toast != null and _toast.has_meta("box") else null
	if box == null:
		return
	_toast.text = "Próximamente (base de diseño)"
	box.visible = true
	var t := get_tree().create_timer(1.4)
	t.timeout.connect(func(): if is_instance_valid(box): box.visible = false)

# ----------------------------------------------------------------- widgets
func _radial(col: Color, alpha: float) -> TextureRect:
	var tr := TextureRect.new()
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g := Gradient.new()
	g.set_color(0, Color(col.r, col.g, col.b, alpha))
	g.set_color(1, Color(col.r, col.g, col.b, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 1.0)
	tr.texture = gt
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	return tr

func _avatar() -> Control:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(52, 52)
	var sb := StyleBoxFlat.new()
	sb.bg_color = UITheme.PRIMARY.darkened(0.1)
	sb.set_corner_radius_all(26)
	sb.set_border_width_all(3)
	sb.border_color = UITheme.GOLD
	p.add_theme_stylebox_override("panel", sb)
	var l := _lbl("P1", 17, Color.WHITE, true, 800)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p

func _chip(icon: String, value: String, col: Color) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.pill(Color(0.07, 0.09, 0.16), UITheme.BORDER, 8))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 3)
	p.add_child(h)
	h.add_child(_lbl(icon, 15, col, false, 600))
	h.add_child(_lbl(value, 14, UITheme.TEXT, true, 700))
	return p

func _icon_btn(icon: String) -> Button:
	var b := Button.new()
	b.text = icon
	b.custom_minimum_size = Vector2(40, 40)
	UITheme.button_font(b, 18, UITheme.TEXT2, false, 600)
	UITheme.style_surface(b, UITheme.SURFACE2, UITheme.BORDER, 11)
	b.pressed.connect(_soon)
	return b

func _gift_slot(icon: String, state: String, state_col: Color, frame: Color) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(108, 92)
	p.add_theme_stylebox_override("panel", UITheme.panel(UITheme.SURFACE, frame, 14, 2, 6))
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	v.add_child(_lbl(icon, 32, frame.lightened(0.2), false, 700))
	v.add_child(_lbl(state, 12, state_col, true, 700))
	var b := Button.new()
	b.flat = true
	b.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.pressed.connect(_soon)
	p.add_child(b)
	return p

func _big_button(text: String, subtitle: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 70)
	UITheme.style_primary(b, UITheme.PRIMARY, 18)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", -2)
	b.add_child(v)
	v.add_child(_lbl("▶  " + text, 24, Color.WHITE, true, 800))
	v.add_child(_lbl(subtitle, 12, Color(1, 1, 1, 0.82), false, 600))
	return b

func _menu_button(icon: String, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(94, 58)
	UITheme.style_surface(b, UITheme.SURFACE, UITheme.BORDER, 14)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 0)
	b.add_child(v)
	v.add_child(_lbl(icon, 20, UITheme.PRIMARY_EDGE, false, 600))
	v.add_child(_lbl(text, 12, UITheme.TEXT2, true, 600))
	b.pressed.connect(cb)
	return b

func _nav_btn(icon: String, text: String, active: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.flat = true
	b.custom_minimum_size = Vector2(70, 52)
	var col := UITheme.PRIMARY_EDGE if active else UITheme.MUTED
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", -1)
	b.add_child(v)
	if active:
		var bar := ColorRect.new()
		bar.color = UITheme.PRIMARY_EDGE
		bar.custom_minimum_size = Vector2(26, 3)
		bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(bar)
	v.add_child(_lbl(icon, 18, col, false, 600))
	v.add_child(_lbl(text, 11, col, true, 700))
	b.pressed.connect(cb)
	return b

func _center(c: Control) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.add_child(c)
	return cc

func _lbl(t: String, sz: int, col: Color, title := false, weight := -1) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(l, sz, col, title, weight)
	return l
