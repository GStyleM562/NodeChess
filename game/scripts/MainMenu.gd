extends Node3D
## HOME screen — Claude Design hi-fi (Pokémon Duel × Clash Royale). Top bar
## (avatar + currency pills + energy), 3D deck-leader centerpiece with a gold glow,
## reward/gift slots, a juicy PLAY button, secondary buttons and a bottom nav.
## Style only — scene routes and the 3D model are unchanged.

## Cofres REALES del lobby (los "regalos" del diseño): gratis + 5/10/15 min.
const CHEST_LOBBY := {
	"free": {"icon": "🎁", "col": Color(0.35, 0.6, 1.0), "name": "Gratis"},
	"t5": {"icon": "🧰", "col": Color(0.212, 0.82, 0.498), "name": "Común"},
	"t10": {"icon": "💎", "col": Color(0.722, 0.451, 1.0), "name": "Épico"},
	"t15": {"icon": "👑", "col": Color(1.0, 0.773, 0.239), "name": "Legendario"},
}

var _pivot: Node3D
var _leader: Figure3D
var _toast: Label
var _chest_states := {}   # id -> Label del estado (timer / ¡LISTO!)
var _chest_tick := 0.0

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	_build_env()
	_build_ui()
	Music.play_menu()

func _process(delta: float) -> void:
	if _pivot != null:
		_pivot.rotate_y(delta * 0.4)
	_chest_tick += delta
	if _chest_tick >= 0.5:
		_chest_tick = 0.0
		_refresh_chest_states()

func _refresh_chest_states() -> void:
	for id in _chest_states.keys():
		var lbl: Label = _chest_states[id]
		if not is_instance_valid(lbl):
			continue
		if id == "free":
			lbl.text = "¡Gratis!"
			continue
		var left: int = Inventory.chest_left(id)
		if left <= 0:
			lbl.text = "¡LISTO!"
			lbl.add_theme_color_override("font_color", UITheme.SUCCESS)
		else:
			lbl.text = "%d:%02d" % [left / 60, left % 60]
			lbl.add_theme_color_override("font_color", UITheme.TEXT2)

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
	var gear := _icon_btn("⚙")
	gear.pressed.disconnect(_soon)
	gear.pressed.connect(_toggle_settings)
	tb.add_child(gear)

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
	var hdr := _lbl("COFRES  ·  toca uno para abrirlo", 11, UITheme.MUTED, true, 700)
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
	for id in ["free", "t5", "t10", "t15"]:
		gifts.add_child(_chest_slot(id))
	_refresh_chest_states()

## Slot de cofre del lobby: icono + nombre + estado en vivo; toca para abrir.
func _chest_slot(id: String) -> Control:
	var st: Dictionary = CHEST_LOBBY[id]
	var col: Color = st["col"]
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(108, 92)
	p.add_theme_stylebox_override("panel", UITheme.panel(UITheme.SURFACE.lerp(col, 0.08), col, 14, 2, 6))
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	p.add_child(v)
	v.add_child(_lbl(String(st["icon"]), 30, col.lightened(0.2), false, 700))
	v.add_child(_lbl(String(st["name"]), 11, col, true, 700))
	var state := _lbl("…", 12, UITheme.TEXT2, true, 700)
	v.add_child(state)
	_chest_states[id] = state
	var b := Button.new()
	b.flat = true
	b.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.pressed.connect(_tap_chest.bind(id))
	p.add_child(b)
	return p

func _tap_chest(id: String) -> void:
	if id == "free":
		var got: Dictionary = Inventory.open_free()
		var lines: Array = []
		for key in got:
			lines.append("%s %s  +%d fragmentos" % [_piece_icon(String(key)), Inventory.piece_name(String(key)), int(got[key])])
		_open_chest_anim(id, lines)
		return
	if not Inventory.chest_ready(id):
		var left: int = Inventory.chest_left(id)
		_toast_msg("⏳ %s disponible en %d:%02d" % [String(Inventory.CHESTS[id]["name"]), left / 60, left % 60])
		return
	var pieces: Array = Inventory.open_chest(id)
	var lines2: Array = []
	for key in pieces:
		lines2.append("%s %s" % [_piece_icon(String(key)), Inventory.piece_name(String(key))])
	_open_chest_anim(id, lines2)

func _piece_icon(key: String) -> String:
	if key.begins_with("model:"): return "🧍"
	if key.begins_with("rarity:"): return "⭐"
	if key.begins_with("atype:"): return "🎲"
	if key.begins_with("color:"): return "🎯"
	if key.begins_with("fx:"): return "🌀"
	if key.begins_with("passive:"): return "✨"
	return "👟"   # stamina

func _toast_msg(text: String) -> void:
	var box = _toast.get_meta("box") if _toast != null and _toast.has_meta("box") else null
	if box == null:
		return
	_toast.text = text
	box.visible = true
	var t := get_tree().create_timer(1.6)
	t.timeout.connect(func(): if is_instance_valid(box): box.visible = false)

## Animación de apertura: el cofre tiembla, se abre con un destello y las
## recompensas van saltando una por una.
func _open_chest_anim(id: String, lines: Array) -> void:
	var st: Dictionary = CHEST_LOBBY[id]
	var col: Color = st["col"]
	Sfx.play("rankup")
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)
	create_tween().tween_property(dim, "color:a", 0.75, 0.25)
	# destello radial detrás del cofre
	var glow := _radial(col, 0.55)
	glow.set_anchors_preset(Control.PRESET_CENTER)
	glow.offset_left = -30
	glow.offset_right = 30
	glow.offset_top = -230
	glow.offset_bottom = -170
	glow.pivot_offset = Vector2(30, 30)
	glow.scale = Vector2(0.2, 0.2)
	glow.modulate.a = 0.0
	layer.add_child(glow)
	# el cofre
	var chest := _lbl(String(st["icon"]), 84, col.lightened(0.15), false, 800)
	chest.set_anchors_preset(Control.PRESET_CENTER)
	chest.offset_left = -80
	chest.offset_right = 80
	chest.offset_top = -270
	chest.offset_bottom = -130
	chest.pivot_offset = Vector2(80, 70)
	layer.add_child(chest)
	# tiembla…
	var shake := create_tween()
	for i in 3:
		shake.tween_property(chest, "rotation_degrees", 9.0, 0.07)
		shake.tween_property(chest, "rotation_degrees", -9.0, 0.07)
	shake.tween_property(chest, "rotation_degrees", 0.0, 0.05)
	# …se aplasta y ¡POP! (destello florece)
	shake.tween_property(chest, "scale", Vector2(1.25, 0.72), 0.1)
	shake.tween_property(chest, "scale", Vector2(1.45, 1.45), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	shake.tween_callback(func():
		var g := create_tween()
		g.set_parallel(true)
		g.tween_property(glow, "scale", Vector2(9, 9), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		g.tween_property(glow, "modulate:a", 1.0, 0.12)
		g.chain().tween_property(glow, "modulate:a", 0.0, 0.6))
	await shake.finished
	# recompensas: pastillas que van saltando una por una
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -170
	box.offset_right = 170
	box.offset_top = -95
	box.add_theme_constant_override("separation", 8)
	layer.add_child(box)
	for line in lines:
		var pill := PanelContainer.new()
		pill.add_theme_stylebox_override("panel", UITheme.panel(UITheme.SURFACE, col, 12, 2, 10))
		var l := _lbl(String(line), 15, UITheme.TEXT, true, 700)
		pill.add_child(l)
		pill.pivot_offset = Vector2(170, 24)
		pill.scale = Vector2(0.05, 0.05)
		box.add_child(pill)
		var pt := create_tween()
		pt.tween_property(pill, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Sfx.play("ui_click")
		await get_tree().create_timer(0.16).timeout
	# recoger
	var take := Button.new()
	take.text = "✓ RECOGER"
	take.custom_minimum_size = Vector2(220, 52)
	UITheme.button_font(take, 17, Color.WHITE, true, 800)
	UITheme.style_primary(take, col.darkened(0.25), 14)
	take.set_anchors_preset(Control.PRESET_CENTER)
	take.offset_left = -110
	take.offset_right = 110
	take.offset_top = 150
	take.offset_bottom = 202
	take.modulate.a = 0.0
	take.pressed.connect(func(): layer.queue_free())
	layer.add_child(take)
	create_tween().tween_property(take, "modulate:a", 1.0, 0.3)
	_refresh_chest_states()

func _build_buttons(layer: CanvasLayer) -> void:
	var play := _big_button("JUGAR", "Partida rápida")
	play.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	play.offset_top = -288
	play.offset_bottom = -212
	play.offset_left = 22
	play.offset_right = -22
	play.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/deck_builder.tscn"))
	layer.add_child(play)

	# UNA sola parrilla grande (3×2) — antes había dos barras con botones
	# duplicados (Colección/Probar) y todo se veía chiquito.
	var grid := GridContainer.new()
	grid.columns = 3
	grid.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	grid.offset_top = -204
	grid.offset_bottom = -72
	grid.offset_left = 12
	grid.offset_right = -12
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	layer.add_child(grid)
	grid.add_child(_menu_button("🃏", "Mazos", func(): get_tree().change_scene_to_file("res://scenes/deck_builder.tscn")))
	grid.add_child(_menu_button("📖", "Colección", func(): get_tree().change_scene_to_file("res://scenes/dex.tscn")))
	grid.add_child(_menu_button("📦", "Inventario", func(): get_tree().change_scene_to_file("res://scenes/inventory.tscn")))
	grid.add_child(_menu_button("🌐", "Online", func(): get_tree().change_scene_to_file("res://scenes/online_lobby.tscn")))
	grid.add_child(_menu_button("🛠", "Crear", func(): get_tree().change_scene_to_file("res://scenes/character_creator.tscn")))
	grid.add_child(_menu_button("🎲", "Probar", func(): get_tree().change_scene_to_file("res://scenes/attack_tester.tscn")))

func _build_nav(layer: CanvasLayer) -> void:
	var nav := PanelContainer.new()
	nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav.offset_top = -62
	nav.add_theme_stylebox_override("panel", UITheme.panel(Color(0.07, 0.08, 0.14, 0.99), UITheme.BORDER, 0, 1, 4))
	layer.add_child(nav)
	var nb := HBoxContainer.new()
	nb.alignment = BoxContainer.ALIGNMENT_CENTER
	nb.add_theme_constant_override("separation", 26)
	nav.add_child(nb)
	nb.add_child(_nav_btn("🏠", "Home", true, func(): pass))
	nb.add_child(_nav_btn("🛍", "Tienda", false, _soon))
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

# ---------------------------------------------------------------- settings
## ATRÁS (Android) en el menú: abre/cierra la Configuración en vez de salir.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_toggle_settings()

func _toggle_settings() -> void:
	var old := get_node_or_null("SettingsModal")
	if old != null:
		old.queue_free()
		return
	_show_settings()

## Panel de Configuración (engranaje ⚙): volúmenes + dónde van los archivos de audio.
func _show_settings() -> void:
	var modal := Control.new()
	modal.name = "SettingsModal"
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	var layer := CanvasLayer.new()
	layer.layer = 30
	modal.add_child(layer)
	add_child(modal)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			modal.queue_free())
	layer.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(cc)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(470, 0)
	panel.add_theme_stylebox_override("panel", UITheme.panel(UITheme.SURFACE, UITheme.PRIMARY_EDGE, 18, 2, 18))
	cc.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	var t := _lbl("⚙ Configuración", 20, UITheme.GOLD, true, 800)
	vb.add_child(t)

	vb.add_child(_volume_row("Música", Settings.music_vol, func(v: float): Settings.set_music(v)))
	vb.add_child(_volume_row("Sonidos (SFX)", Settings.sfx_vol, func(v: float):
		Settings.set_sfx(v)
		Sfx.play("ui_click")))   # feedback inmediato del nuevo volumen

	# --- tablero 3D con assets vs 2D digital (solo visual, no afecta gameplay) ---
	var bh := _lbl("TABLERO (solo visual)", 11, UITheme.MUTED, true, 700)
	bh.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vb.add_child(bh)
	var brow := HBoxContainer.new()
	brow.add_theme_constant_override("separation", 8)
	vb.add_child(brow)
	var b3d := Button.new()
	var b2d := Button.new()
	var bstyle := func():
		b3d.text = "🗿 3D con assets" + ("  ✓" if Settings.board_view == "3d" else "")
		b2d.text = "💠 2D digital" + ("  ✓" if Settings.board_view == "2d" else "")
		if Settings.board_view == "3d":
			UITheme.style_primary(b3d, UITheme.PRIMARY, 10)
			UITheme.style_surface(b2d, UITheme.SURFACE2, UITheme.BORDER, 10)
		else:
			UITheme.style_surface(b3d, UITheme.SURFACE2, UITheme.BORDER, 10)
			UITheme.style_primary(b2d, UITheme.PRIMARY, 10)
	for b in [b3d, b2d]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 42)
		UITheme.button_font(b, 14, UITheme.TEXT, true, 700)
		brow.add_child(b)
	b3d.pressed.connect(func(): Settings.set_board_view("3d"); bstyle.call())
	b2d.pressed.connect(func(): Settings.set_board_view("2d"); bstyle.call())
	bstyle.call()
	var bhint := Label.new()
	bhint.text = "El 2D digital carga más rápido; se aplica al iniciar la siguiente partida."
	bhint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bhint.custom_minimum_size = Vector2(430, 0)
	UITheme.label(bhint, 11, UITheme.TEXT2, false, 600)
	vb.add_child(bhint)

	# --- vista Admin / Usuario (progresión e inventario) ---
	var mh := _lbl("VISTA (progresión)", 11, UITheme.MUTED, true, 700)
	mh.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vb.add_child(mh)
	var mrow := HBoxContainer.new()
	mrow.add_theme_constant_override("separation", 8)
	vb.add_child(mrow)
	var madmin := Button.new()
	var muser := Button.new()
	var restyle := func():
		madmin.text = ("👑 Admin" + ("  ✓" if Inventory.is_admin() else ""))
		muser.text = ("👤 Usuario" + ("" if Inventory.is_admin() else "  ✓"))
		if Inventory.is_admin():
			UITheme.style_primary(madmin, UITheme.GOLD.darkened(0.25), 10)
			UITheme.style_surface(muser, UITheme.SURFACE2, UITheme.BORDER, 10)
		else:
			UITheme.style_surface(madmin, UITheme.SURFACE2, UITheme.BORDER, 10)
			UITheme.style_primary(muser, UITheme.PRIMARY, 10)
	for b in [madmin, muser]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 42)
		UITheme.button_font(b, 14, UITheme.TEXT, true, 700)
		mrow.add_child(b)
	madmin.pressed.connect(func(): Inventory.set_mode("admin"); restyle.call())
	muser.pressed.connect(func(): Inventory.set_mode("user"); restyle.call())
	restyle.call()
	var mhint := Label.new()
	mhint.text = "Admin: todo desbloqueado e ilimitado. Usuario: solo puedes usar en el Creador las piezas de tu inventario (consíguelas en 🎁 Cajas)."
	mhint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mhint.custom_minimum_size = Vector2(430, 0)
	UITheme.label(mhint, 11, UITheme.TEXT2, false, 600)
	vb.add_child(mhint)

	# Dónde van los archivos de audio (chuleta para no buscar en el README).
	var hdr := _lbl("¿DÓNDE PONGO LA MÚSICA? (.mp3/.ogg/.wav, 1 por carpeta)", 11, UITheme.MUTED, true, 700)
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vb.add_child(hdr)
	var paths := Label.new()
	paths.text = ("game/assets/audio/music/\n" +
		"   menu/  ·  battle/  ·  advantage/ (tú por ganar)  ·  danger/ (rival por ganar)\n" +
		"game/assets/audio/sfx/\n" +
		"   ui_click/  end_turn/  deploy/  attack_hit/  attack_block/\n" +
		"   attack_effect/  attack_miss/  ko/  rankup/  victory/  defeat/")
	paths.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	paths.custom_minimum_size = Vector2(430, 0)
	UITheme.label(paths, 12, UITheme.TEXT2, false, 600)
	vb.add_child(paths)

	var close := Button.new()
	close.text = "Cerrar"
	close.custom_minimum_size = Vector2(0, 46)
	UITheme.button_font(close, 15, UITheme.TEXT, true, 700)
	UITheme.style_primary(close, UITheme.PRIMARY)
	close.pressed.connect(func(): modal.queue_free())
	vb.add_child(close)

## Fila de volumen: etiqueta + slider 0–100 + porcentaje en vivo.
func _volume_row(caption: String, val: float, on_change: Callable) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	var hb := HBoxContainer.new()
	row.add_child(hb)
	var l := _lbl(caption, 14, UITheme.TEXT, true, 700)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(l)
	var pct := _lbl("%d%%" % roundi(val * 100.0), 14, UITheme.GOLD, true, 700)
	hb.add_child(pct)
	var s := HSlider.new()
	s.min_value = 0
	s.max_value = 100
	s.step = 5
	s.value = val * 100.0
	s.custom_minimum_size = Vector2(0, 34)
	s.value_changed.connect(func(v: float):
		pct.text = "%d%%" % int(v)
		on_change.call(v / 100.0))
	row.add_child(s)
	return row

func _icon_btn(icon: String) -> Button:
	var b := Button.new()
	b.text = icon
	b.custom_minimum_size = Vector2(40, 40)
	UITheme.button_font(b, 18, UITheme.TEXT2, false, 600)
	UITheme.style_surface(b, UITheme.SURFACE2, UITheme.BORDER, 11)
	b.pressed.connect(_soon)
	return b

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
	b.custom_minimum_size = Vector2(0, 62)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.style_surface(b, UITheme.SURFACE, UITheme.BORDER, 14)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 0)
	b.add_child(v)
	v.add_child(_lbl(icon, 24, UITheme.PRIMARY_EDGE, false, 600))
	v.add_child(_lbl(text, 14, UITheme.TEXT2, true, 700))
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
