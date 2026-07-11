extends Node3D
## HOME screen — Claude Design hi-fi (Pokémon Duel × Clash Royale). Top bar
## (avatar + currency pills + energy), 3D deck-leader centerpiece with a gold glow,
## reward/gift slots, a juicy PLAY button, secondary buttons and a bottom nav.
## Style only — scene routes and the 3D model are unchanged.

## Cofres REALES del lobby: caja gratis + TUS COFRES ganados (se descifran en
## el Inventario) + cofre de nivel. Los t5/t10/t15 ya NO son de reloj: se GANAN
## venciendo partidas (modo usuario) y viven en el inventario de cofres.
const CHEST_LOBBY := {
	"free": {"icon": "🎁", "col": Color(0.35, 0.6, 1.0), "name": "Gratis"},
	"won": {"icon": "📦", "col": Color(0.212, 0.82, 0.498), "name": "Cofres"},
	"level": {"icon": "🏅", "col": Color(0.95, 0.5, 0.2), "name": "Nivel"},
}

var _pivot: Node3D
var _leader: Figure3D
var _toast: Label
var _chest_states := {}   # id -> Label del estado (timer / ¡LISTO!)
var _chest_tick := 0.0
var _level_slot: Control   # slot del cofre de NIVEL (oculto sin pendientes)

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
	if _level_slot != null and is_instance_valid(_level_slot):
		_level_slot.visible = Inventory.level_chests > 0
	for id in _chest_states.keys():
		var lbl: Label = _chest_states[id]
		if not is_instance_valid(lbl):
			continue
		if id == "free":
			lbl.text = "¡Gratis!"
			continue
		if id == "level":
			lbl.text = "×%d" % Inventory.level_chests
			lbl.add_theme_color_override("font_color", UITheme.SUCCESS)
			continue
		if id == "won":
			# ¿algún cofre listo? → ¡ABRIR! · ¿descifrando? → cuenta atrás · si no → ×N
			var ready := false
			var left := -1
			for i in Inventory.chest_inv.size():
				var info: Dictionary = Inventory.chest_info(i)
				if String(info.get("state", "")) == "ready":
					ready = true
				elif String(info.get("state", "")) == "unlocking":
					left = int(info["left"])
			if ready:
				lbl.text = "¡ABRIR!"
				lbl.add_theme_color_override("font_color", UITheme.SUCCESS)
			elif left >= 0:
				lbl.text = "%d:%02d" % [left / 60, left % 60]
				lbl.add_theme_color_override("font_color", UITheme.TEXT2)
			else:
				lbl.text = "×%d" % Inventory.chest_inv.size()
				lbl.add_theme_color_override("font_color",
					UITheme.SUCCESS if Inventory.chest_inv.size() > 0 else UITheme.MUTED)

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

	_build_bg_particles(layer)

	# gold glow behind the leader (con pulso suave para que respire)
	var glow := _radial(UITheme.GOLD, 0.22)
	glow.set_anchors_preset(Control.PRESET_CENTER_TOP)
	glow.offset_left = -190
	glow.offset_right = 190
	glow.offset_top = 150
	glow.offset_bottom = 560
	layer.add_child(glow)
	var gp := create_tween().set_loops()
	gp.tween_property(glow, "modulate:a", 0.65, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	gp.tween_property(glow, "modulate:a", 1.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

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
	# barra fina de XP (6px, relleno PRIMARY) — §6.1 del handoff
	var xpbar := ProgressBar.new()
	xpbar.custom_minimum_size = Vector2(0, 6)
	xpbar.show_percentage = false
	xpbar.max_value = maxf(1.0, float(Inventory.xp_needed()))
	xpbar.value = clampf(float(Inventory.xp), 0.0, xpbar.max_value)
	var xbg := StyleBoxFlat.new(); xbg.bg_color = Color(0.10, 0.13, 0.22); xbg.set_corner_radius_all(3)
	var xfg := StyleBoxFlat.new(); xfg.bg_color = UITheme.PRIMARY; xfg.set_corner_radius_all(3)
	xpbar.add_theme_stylebox_override("background", xbg)
	xpbar.add_theme_stylebox_override("fill", xfg)
	who.add_child(xpbar)
	var lv := _lbl("Nv %d  ·  %d/%d" % [Inventory.level, Inventory.xp, Inventory.xp_needed()], 11, UITheme.MUTED, false, 700)
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	who.add_child(lv)
	tb.add_child(who)
	# saldos REALES (🪙 por subir de nivel · 💎 cada 5 niveles y en cofres)
	tb.add_child(_chip("🪙", str(Inventory.coins), UITheme.GOLD))
	tb.add_child(_chip("💎", str(Inventory.gems), Color(0.5, 0.85, 1.0)))
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
	for id in ["free", "won", "level"]:
		var slot := _chest_slot(id)
		gifts.add_child(slot)
		if id == "level":
			_level_slot = slot   # visible solo si hay cofres de nivel pendientes
	_refresh_chest_states()

## Slot de cofre del lobby: icono + nombre + estado en vivo; toca para abrir.
func _chest_slot(id: String) -> Control:
	var st: Dictionary = CHEST_LOBBY[id]
	var col: Color = st["col"]
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(96, 96)   # caben 5 slots (incluye Nivel)
	p.add_theme_stylebox_override("panel", UITheme.panel(UITheme.PANEL_DEEP, col, 14, 2, 6))
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 3)
	p.add_child(v)
	var tile := UITheme.icon_tile_node(String(st["icon"]), col, 38, 22)   # emoji enmarcado (§5)
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_center(tile))
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
		var frags: Dictionary = got.get("frags", {})
		for key in frags:
			lines.append("%s %s  +%d fragmentos" % [_piece_icon(String(key)), Inventory.piece_name(String(key)), int(frags[key])])
		if int(got.get("gems", 0)) > 0:
			lines.append("💎 +%d ¡DIAMANTES!" % int(got["gems"]))
		_open_chest_anim(id, lines)
		return
	if id == "level":
		var lr: Dictionary = Inventory.open_level_chest()
		if lr.is_empty():
			return
		var llines: Array = []
		for key in lr.get("pieces", []):
			llines.append("%s %s" % [_piece_icon(String(key)), Inventory.piece_name(String(key))])
		if int(lr.get("gems", 0)) > 0:
			llines.append("💎 +%d ¡DIAMANTES!" % int(lr["gems"]))
		_open_chest_anim(id, llines)
		_refresh_chest_states()
		return
	if id == "won":
		# ¿hay un cofre LISTO? ábrelo aquí con la animación; si no, ve al
		# Inventario a DESCIFRAR (ahí arrancas el progreso de cada cofre).
		for i in Inventory.chest_inv.size():
			if String(Inventory.chest_info(i).get("state", "")) == "ready":
				var wr: Dictionary = Inventory.open_won_chest(i)
				var wl: Array = []
				for key in wr.get("pieces", []):
					wl.append("%s %s" % [_piece_icon(String(key)), Inventory.piece_name(String(key))])
				if int(wr.get("gems", 0)) > 0:
					wl.append("💎 +%d ¡DIAMANTES!" % int(wr["gems"]))
				_open_chest_anim(id, wl)
				_refresh_chest_states()
				return
		if Inventory.chest_inv.is_empty():
			_toast_msg("📦 Gana partidas para conseguir cofres")
		else:
			get_tree().change_scene_to_file("res://scenes/inventory.tscn")

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
	# Halo pulsante DETRÁS del botón (se añade antes para quedar por debajo).
	var halo := _radial(UITheme.PRIMARY, 0.5)
	halo.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	halo.offset_top = -308
	halo.offset_bottom = -192
	halo.offset_left = 2
	halo.offset_right = -2
	layer.add_child(halo)
	var hp := create_tween().set_loops()
	hp.tween_property(halo, "modulate:a", 0.72, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	hp.tween_property(halo, "modulate:a", 0.3, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var play := _big_button("JUGAR", "Partida rápida")
	play.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	play.offset_top = -288
	play.offset_bottom = -212
	play.offset_left = 22
	play.offset_right = -22
	play.pressed.connect(func():
		# Primera vez: tutorial guiado directo al tablero (mapa 0, CPU pasiva).
		if not Settings.tutorial_done:
			Loadout.tutorial = true
			get_tree().change_scene_to_file("res://scenes/board.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/deck_builder.tscn"))
	layer.add_child(play)
	_juice_play(play)

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
	grid.add_child(_menu_button("🃏", "Mazos", UITheme.PRIMARY_EDGE, func(): get_tree().change_scene_to_file("res://scenes/deck_builder.tscn")))
	grid.add_child(_menu_button("📖", "Colección", UITheme.R_EPIC, func(): get_tree().change_scene_to_file("res://scenes/dex.tscn")))
	grid.add_child(_menu_button("📦", "Inventario", UITheme.GOLD, func(): get_tree().change_scene_to_file("res://scenes/inventory.tscn")))
	grid.add_child(_menu_button("🌐", "Online", UITheme.ENERGY, func(): get_tree().change_scene_to_file("res://scenes/online_lobby.tscn")))
	grid.add_child(_menu_button("🛠", "Crear", UITheme.SUCCESS, func(): get_tree().change_scene_to_file("res://scenes/character_creator.tscn")))
	grid.add_child(_menu_button("🎲", "Probar", UITheme.ORANGE, func(): get_tree().change_scene_to_file("res://scenes/attack_tester.tscn")))

## Botón JUGAR "hipnótico": respiración + barrido de brillo diagonal. NO toca `pressed`.
func _juice_play(play: Button) -> void:
	play.clip_contents = true
	# respiración (escala 1.0↔1.02 en bucle) — pivote al centro cuando ya tiene tamaño
	play.resized.connect(func(): play.pivot_offset = play.size * 0.5)
	await get_tree().process_frame
	play.pivot_offset = play.size * 0.5
	var br := create_tween().set_loops()
	br.tween_property(play, "scale", Vector2(1.02, 1.02), 2.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	br.tween_property(play, "scale", Vector2.ONE, 2.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# barrido de brillo: banda diagonal blanca que cruza el botón
	var shine := TextureRect.new()
	shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.0)); g.set_color(1, Color(1, 1, 1, 0.0))
	g.add_point(0.5, Color(1, 1, 1, 0.35))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0); gt.fill_to = Vector2(1, 0)
	shine.texture = gt
	shine.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shine.stretch_mode = TextureRect.STRETCH_SCALE
	shine.rotation_degrees = 18.0
	shine.size = Vector2(70, play.size.y * 2.4)
	shine.position = Vector2(-90, -play.size.y * 0.7)
	play.add_child(shine)
	var sw := create_tween().set_loops()
	sw.tween_interval(1.1)
	sw.tween_property(shine, "position:x", play.size.x + 90.0, 0.75).set_trans(Tween.TRANS_SINE)
	sw.tween_callback(func(): shine.position.x = -90.0)

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
	nb.add_child(_nav_btn("🛍", "Tienda", false, func(): get_tree().change_scene_to_file("res://scenes/shop.tscn")))
	nb.add_child(_nav_btn("👤", "Perfil", false, func(): get_tree().change_scene_to_file("res://scenes/profile.tscn")))

func _soon() -> void:
	var box = _toast.get_meta("box") if _toast != null and _toast.has_meta("box") else null
	if box == null:
		return
	_toast.text = "Próximamente (base de diseño)"
	box.visible = true
	var t := get_tree().create_timer(1.4)
	t.timeout.connect(func(): if is_instance_valid(box): box.visible = false)

## Partículas suaves de fondo: puntos de luz que flotan lentamente (el menú
## deja de verse estático/triste sin costar nada de rendimiento).
func _build_bg_particles(layer: CanvasLayer) -> void:
	var vw := get_viewport().get_visible_rect().size
	var cols := [UITheme.PRIMARY, UITheme.GOLD, Color(0.72, 0.45, 1.0), UITheme.ENERGY]
	for i in 12:
		var d := _radial(cols[i % cols.size()], 0.16 + randf() * 0.12)
		var size := 26.0 + randf() * 64.0
		d.position = Vector2(randf() * vw.x, randf() * vw.y)
		d.size = Vector2(size, size)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(d)
		var tw := create_tween().set_loops()
		var dur := 2.2 + randf() * 2.6
		var rise := 40.0 + randf() * 70.0
		tw.tween_property(d, "position:y", d.position.y - rise, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(d, "position:y", d.position.y, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var tx := create_tween().set_loops()
		var sway := 18.0 + randf() * 26.0
		tx.tween_property(d, "position:x", d.position.x + sway, dur * 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tx.tween_property(d, "position:x", d.position.x, dur * 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

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
	panel.add_theme_stylebox_override("panel", UITheme.panel(UITheme.SURFACE, UITheme.PRIMARY_EDGE, 22, 2, 18))
	cc.add_child(panel)
	# Scroll: en teléfonos altos la Configuración no cabe entera → se desliza.
	var scr := ScrollContainer.new()
	scr.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var vh := get_viewport().get_visible_rect().size.y
	scr.custom_minimum_size = Vector2(430, minf(vh * 0.82, 720.0))
	panel.add_child(scr)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scr.add_child(vb)
	var t := _lbl("⚙ Configuración", 20, UITheme.GOLD, true, 800)
	vb.add_child(t)

	vb.add_child(_volume_row("Música", Settings.music_vol, func(v: float): Settings.set_music(v)))
	vb.add_child(_volume_row("Sonidos (SFX)", Settings.sfx_vol, func(v: float):
		Settings.set_sfx(v)
		Sfx.play("ui_click")))   # feedback inmediato del nuevo volumen

	# --- tablero 3D con assets vs 2D digital (solo visual, no afecta gameplay) ---
	var bh := Label.new()
	UITheme.section(bh, "Tablero (solo visual)")
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

	# --- combate: velocidad y accesibilidad ---
	var ch := Label.new()
	UITheme.section(ch, "Combate y accesibilidad")
	ch.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vb.add_child(ch)
	var crow := HBoxContainer.new()
	crow.add_theme_constant_override("separation", 8)
	vb.add_child(crow)
	var spd := Button.new()
	var cbb := Button.new()
	var cstyle := func():
		spd.text = ("⏩ Combate ×2  ✓" if Settings.combat_speed == 2 else "▶ Combate ×1")
		cbb.text = ("👁 Daltónico  ✓" if Settings.colorblind else "👁 Daltónico")
		if Settings.combat_speed == 2:
			UITheme.style_primary(spd, UITheme.ORANGE, 10)
		else:
			UITheme.style_surface(spd, UITheme.SURFACE2, UITheme.BORDER, 10)
		if Settings.colorblind:
			UITheme.style_primary(cbb, UITheme.PRIMARY, 10)
		else:
			UITheme.style_surface(cbb, UITheme.SURFACE2, UITheme.BORDER, 10)
	for b in [spd, cbb]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 42)
		UITheme.button_font(b, 14, UITheme.TEXT, true, 700)
		crow.add_child(b)
	spd.pressed.connect(func(): Settings.set_combat_speed(3 - Settings.combat_speed); cstyle.call())
	cbb.pressed.connect(func(): Settings.set_colorblind(not Settings.colorblind); cstyle.call())
	cstyle.call()
	var tut := Button.new()
	tut.text = "🎓 Repetir tutorial"
	tut.custom_minimum_size = Vector2(0, 42)
	UITheme.button_font(tut, 14, UITheme.TEXT, true, 700)
	UITheme.style_surface(tut, UITheme.SURFACE2, UITheme.BORDER, 10)
	tut.pressed.connect(func():
		Loadout.tutorial = true
		get_tree().change_scene_to_file("res://scenes/board.tscn"))
	vb.add_child(tut)

	# --- vista Admin / Usuario (progresión e inventario) ---
	var mh := Label.new()
	UITheme.section(mh, "Vista (progresión)")
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

	# --- ADMIN: quitar/añadir FONDOS (🪙/💎) a la cuenta del usuario ---
	if Inventory.is_admin():
		var fh := Label.new()
		UITheme.section(fh, "Fondos del usuario (admin)")
		fh.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		vb.add_child(fh)
		var fbal := _lbl("🪙 %d   ·   💎 %d" % [Inventory.coins, Inventory.gems], 15, UITheme.GOLD, true, 800)
		vb.add_child(fbal)
		var frow := HBoxContainer.new()
		frow.add_theme_constant_override("separation", 6)
		vb.add_child(frow)
		var fund := func(dc: int, dg: int):
			Inventory.adjust_funds(dc, dg)
			fbal.text = "🪙 %d   ·   💎 %d" % [Inventory.coins, Inventory.gems]
		for spec in [["−500 🪙", -500, 0], ["+500 🪙", 500, 0], ["−25 💎", 0, -25], ["+25 💎", 0, 25]]:
			var fb := Button.new()
			fb.text = String(spec[0])
			fb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fb.custom_minimum_size = Vector2(0, 42)
			UITheme.button_font(fb, 13, UITheme.TEXT, true, 700)
			UITheme.style_surface(fb, UITheme.SURFACE2, UITheme.BORDER, 10)
			var dc: int = int(spec[1])
			var dg: int = int(spec[2])
			fb.pressed.connect(func(): fund.call(dc, dg))
			frow.add_child(fb)

	# --- reiniciar inventario (piezas + fragmentos; NADA más) ---
	var wipe := Button.new()
	wipe.text = "🗑 Borrar inventario (piezas y fragmentos)"
	wipe.custom_minimum_size = Vector2(0, 42)
	UITheme.button_font(wipe, 13, UITheme.DANGER, true, 700)
	UITheme.style_surface(wipe, UITheme.SURFACE2, UITheme.DANGER.darkened(0.35), 10)
	wipe.pressed.connect(func(): _confirm_wipe(modal))
	vb.add_child(wipe)
	var whint := Label.new()
	whint.text = "Borra TODAS tus piezas y fragmentos. Tus personajes creados, nivel, XP y cofres NO se tocan. En modo usuario recibes de nuevo el kit inicial."
	whint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	whint.custom_minimum_size = Vector2(430, 0)
	UITheme.label(whint, 11, UITheme.MUTED, false, 600)
	vb.add_child(whint)

	# Dónde van los archivos de audio (chuleta para no buscar en el README).
	var hdr := Label.new()
	UITheme.section(hdr, "¿Dónde pongo la música? (.mp3/.ogg/.wav, 1 por carpeta)")
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vb.add_child(hdr)
	var help := PanelContainer.new()
	help.add_theme_stylebox_override("panel", UITheme.panel(UITheme.PANEL_DEEP, UITheme.BORDER, 13, 1, 12))
	var paths := Label.new()
	paths.text = ("game/assets/audio/music/\n" +
		"   menu/  ·  battle/  ·  advantage/ (tú por ganar)  ·  danger/ (rival por ganar)\n" +
		"game/assets/audio/sfx/\n" +
		"   ui_click/  end_turn/  deploy/  attack_hit/  attack_block/\n" +
		"   attack_effect/  attack_miss/  ko/  rankup/  victory/  defeat/")
	paths.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	paths.custom_minimum_size = Vector2(410, 0)
	UITheme.label(paths, 12, UITheme.MUTED, false, 500)
	help.add_child(paths)
	vb.add_child(help)

	var close := Button.new()
	close.text = "Cerrar"
	close.custom_minimum_size = Vector2(0, 46)
	UITheme.button_font(close, 15, UITheme.TEXT, true, 700)
	UITheme.style_primary(close, UITheme.PRIMARY)
	close.pressed.connect(func(): modal.queue_free())
	vb.add_child(close)

## Confirmación del borrado de inventario (piezas + fragmentos, nada más).
func _confirm_wipe(settings_modal: Control) -> void:
	var modal := Control.new()
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	var layer := CanvasLayer.new()
	layer.layer = 35
	modal.add_child(layer)
	add_child(modal)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.66)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			modal.queue_free())
	layer.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(cc)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(400.0, get_viewport().get_visible_rect().size.x - 32.0), 0)
	panel.add_theme_stylebox_override("panel", UITheme.panel(UITheme.SURFACE, UITheme.DANGER.darkened(0.2), 18, 2, 16))
	cc.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	var t := _lbl("🗑 ¿Borrar tu inventario?", 17, UITheme.DANGER, true, 800)
	vb.add_child(t)
	var b := Label.new()
	b.text = "Se borran TODAS las piezas y fragmentos. Personajes creados, nivel, XP y cofres se conservan."
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(360, 0)
	UITheme.label(b, 13, UITheme.TEXT2, false, 600)
	vb.add_child(b)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	vb.add_child(hb)
	var no := Button.new()
	no.text = "Cancelar"
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.custom_minimum_size = Vector2(0, 46)
	UITheme.button_font(no, 14, UITheme.TEXT, true, 700)
	UITheme.style_surface(no)
	no.pressed.connect(func(): modal.queue_free())
	hb.add_child(no)
	var yes := Button.new()
	yes.text = "Borrar"
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes.custom_minimum_size = Vector2(0, 46)
	UITheme.button_font(yes, 14, Color.WHITE, true, 800)
	UITheme.style_primary(yes, UITheme.DANGER, 12)
	yes.pressed.connect(func():
		Inventory.wipe_pieces()
		modal.queue_free()
		if is_instance_valid(settings_modal):
			settings_modal.queue_free()
		_toast_msg("🗑 Inventario borrado (kit inicial re-entregado en modo usuario)"))
	hb.add_child(yes)

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

func _menu_button(icon: String, text: String, accent: Color, cb: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 66)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.style_surface(b, UITheme.SURFACE.lerp(accent, 0.06), Color(accent.r, accent.g, accent.b, 0.33), 14)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 4)
	b.add_child(v)
	var tile := UITheme.icon_tile_node(icon, accent, 34, 18)   # emoji enmarcado (§5)
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_center(tile))
	v.add_child(_lbl(text, 13, UITheme.TEXT2, true, 700))
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
