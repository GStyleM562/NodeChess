extends Node3D
## HOME screen — "hall luminoso" estilo TCG Pocket: cielo cálido, tarjetas
## blancas FLOTANTES en dos carriles laterales (con puntos rojos de aviso),
## identidad + monedas arriba, el líder 3D al centro y TRES modos de juego
## abajo (el central, dorado y más grande). Cada sección aparece UNA sola vez:
## Perfil vive en la identidad, los cofres en 🎁 Recompensas (popup) y los
## mazos dentro de ⚔ BATALLA (el Deck Builder ES la antesala de jugar).

## Cofres REALES del lobby: caja gratis + TUS COFRES ganados (se descifran en
## el Inventario) + cofre de nivel. Los t5/t10/t15 ya NO son de reloj: se GANAN
## venciendo partidas (modo usuario) y viven en el inventario de cofres.
const CHEST_LOBBY := {
	"free": {"icon": "🎁", "col": Color(0.30, 0.55, 0.98), "name": "Gratis"},
	"won": {"icon": "📦", "col": Color(0.13, 0.62, 0.36), "name": "Cofres"},
	"level": {"icon": "🏅", "col": Color(0.88, 0.44, 0.12), "name": "Nivel"},
}

# --- TEMA CLARO del Home (solo esta pantalla; el resto del juego conserva el
# tema oscuro de UITheme). Estilo "juicy" tipo TCG Pocket: fondo amarillo
# cálido, tarjetas CREMA con LABIO inferior 3D (borde grueso abajo = botón
# físico presionable) y brillo superior en los botones de modo.
# Estos SIGUEN el tema (leen tokens de UITheme al instanciar el Home) para que
# el modo oscuro también aplique al Home. Los acentos de modo son vivos en ambos.
var INK := UITheme.TEXT                        # texto principal
var INK_SOFT := UITheme.TEXT2                  # texto secundario
var SUN := UITheme.SKY                         # lavado de fondo (cielo)
var CARD_BG := UITheme.SURFACE                 # tarjeta
var CARD_LIP := UITheme.BORDER                 # labio inferior
const DOT_RED := Color(0.88, 0.35, 0.36)      # punto de aviso (menos chillón)
var GREEN_OK := UITheme.SUCCESS               # "listo"
# Acentos de modo SUAVIZADOS: nada de dorado neón; contraste amable en ambos temas.
const MODE_BLUE := Color(0.42, 0.63, 0.90)    # 🛠 Crear
const MODE_GOLD := Color(0.93, 0.73, 0.33)    # ⚔ BATALLA (central)
const MODE_PURPLE := Color(0.63, 0.53, 0.88)  # 🌐 Online (sala privada)

var _pivot: Node3D
var _leader: Figure3D
var _toast: Label
var _chest_states := {}   # id -> Label del estado (timer / ¡LISTO!)
var _chest_tick := 0.0
var _level_slot: Control   # slot del cofre de NIVEL (oculto sin pendientes)
var _reward_modal: CanvasLayer # popup 🎁 Recompensas (pre-construido, oculto)
var _reward_state: Label   # estado en vivo bajo la tarjeta 🎁
var _reward_dot: Control   # punto rojo de la tarjeta 🎁
var _ad_cards := {}        # kind -> tarjeta de anuncio (para refrescar usos)
var _coin_lbl: Label       # chip 🪙 de la barra superior (refresco tras anuncios)
var _gem_lbl: Label        # chip 💎 de la barra superior

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	_build_env()
	_build_ui()
	Music.play_menu()
	# Si una partida ONLINE se abortó, decir POR QUÉ (antes: rebote mudo al menú
	# y nadie sabía qué pasó — imposible de diagnosticar desde el teléfono).
	if NetSession.abort_reason != "":
		var dlg := AcceptDialog.new()
		dlg.title = "Partida online abortada"
		dlg.dialog_text = NetSession.abort_reason
		dlg.ok_button_text = "Entendido"
		NetSession.abort_reason = ""
		add_child(dlg)
		dlg.popup_centered.call_deferred()
	# BIENVENIDA (1 vez por sesión): si hay tutoriales pendientes, invitarlos —
	# con las categorías, cuántos por cada una y las recompensas jugosas.
	if not TutorialLib.welcomed and TutorialLib.pending_total() > 0:
		TutorialLib.welcomed = true
		_show_welcome.call_deferred()

## Modal de bienvenida: pendientes por categoría + XP por reclamar.
func _show_welcome() -> void:
	var modal := Control.new()
	modal.name = "WelcomeModal"
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	var layer := CanvasLayer.new()
	layer.layer = 28
	modal.add_child(layer)
	add_child(modal)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(cc)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(420.0, get_viewport().get_visible_rect().size.x - 28.0), 0)
	panel.add_theme_stylebox_override("panel", UITheme.panel(UITheme.SURFACE, UITheme.GOLD, 22, 2, 18))
	cc.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	vb.add_child(_lbl("👋 ¡Bienvenido a NodeChess!", 20, UITheme.GOLD, true, 800))
	var body := Label.new()
	var nb := TutorialLib.pending_in(TutorialLib.CAT_BOARD)
	var nm := TutorialLib.pending_in(TutorialLib.CAT_MENU)
	body.text = "Tienes %d tutoriales pendientes en el aula «Cómo jugar»:" % TutorialLib.pending_total()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(body, 14, UITheme.TEXT, false, 600)
	vb.add_child(body)
	if nb > 0:
		vb.add_child(_welcome_row("🎲", "Tablero — despliegue, combate, saltos, rodeos…", nb))
	var nmeta := TutorialLib.pending_in(TutorialLib.CAT_META)
	if nmeta > 0:
		vb.add_child(_welcome_row("📈", "Progreso — crear personajes, cajas y recursos", nmeta))
	if nm > 0:
		vb.add_child(_welcome_row("📱", "Menú — craftear piezas y descifrar cofres", nm))
	var juicy := Label.new()
	juicy.text = "🎁 Cada capítulo superado da XP: hay ✨ %d XP esperándote (¡con monedas y cofres por subir de nivel!)" % TutorialLib.xp_pending()
	juicy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	juicy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(juicy, 13, UITheme.SUCCESS, true, 700)
	vb.add_child(juicy)
	var go := Button.new()
	go.text = "🎓 Ir a los tutoriales"
	go.custom_minimum_size = Vector2(0, 50)
	UITheme.button_font(go, 16, Color.WHITE, true, 800)
	UITheme.style_primary(go, UITheme.PRIMARY, 14)
	go.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/tutorials.tscn"))
	vb.add_child(go)
	var later := Button.new()
	later.text = "Luego"
	later.custom_minimum_size = Vector2(0, 42)
	UITheme.button_font(later, 13, UITheme.TEXT2, true, 700)
	UITheme.style_surface(later)
	later.pressed.connect(func(): modal.queue_free())
	vb.add_child(later)

func _welcome_row(icon: String, text: String, n: int) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.panel(UITheme.PANEL_DEEP, UITheme.GROUP_BORDER, 12, 1, 8))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	p.add_child(hb)
	var tile := UITheme.icon_tile_node(icon, UITheme.GOLD, 34, 17)
	hb.add_child(tile)
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UITheme.label(l, 12, UITheme.TEXT2, false, 600)
	hb.add_child(l)
	var c := Label.new()
	c.text = "×%d" % n
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UITheme.label(c, 15, UITheme.GOLD, true, 800)
	hb.add_child(c)
	return p

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
	# estado compartido: ¿algún cofre ganado listo? ¿alguno descifrándose?
	var ready := false
	var left := -1
	for i in Inventory.chest_inv.size():
		var info: Dictionary = Inventory.chest_info(i)
		if String(info.get("state", "")) == "ready":
			ready = true
		elif String(info.get("state", "")) == "unlocking":
			left = int(info["left"])
	for id in _chest_states.keys():
		var lbl: Label = _chest_states[id]
		if not is_instance_valid(lbl):
			continue
		if id == "free":
			lbl.text = "¡Gratis!"
			continue
		if id == "level":
			lbl.text = "×%d" % Inventory.level_chests
			lbl.add_theme_color_override("font_color", GREEN_OK)
			continue
		if id == "won":
			# ¿algún cofre listo? → ¡ABRIR! · ¿descifrando? → cuenta atrás · si no → ×N
			if ready:
				lbl.text = "¡ABRIR!"
				lbl.add_theme_color_override("font_color", GREEN_OK)
			elif left >= 0:
				lbl.text = "%d:%02d" % [left / 60, left % 60]
				lbl.add_theme_color_override("font_color", INK_SOFT)
			else:
				lbl.text = "×%d" % Inventory.chest_inv.size()
				lbl.add_theme_color_override("font_color",
					GREEN_OK if Inventory.chest_inv.size() > 0 else INK_SOFT)
	# resumen EN la tarjeta 🎁 Recompensas: punto rojo si hay algo que abrir
	if _reward_state != null and is_instance_valid(_reward_state):
		var claim := ready or Inventory.level_chests > 0
		if _reward_dot != null and is_instance_valid(_reward_dot):
			_reward_dot.visible = claim
		if claim:
			_reward_state.text = "¡ABRIR!"
			_reward_state.add_theme_color_override("font_color", GREEN_OK)
		elif left >= 0:
			_reward_state.text = "%d:%02d" % [left / 60, left % 60]
			_reward_state.add_theme_color_override("font_color", INK_SOFT)
		else:
			_reward_state.text = "Gratis 🎁"
			_reward_state.add_theme_color_override("font_color", INK_SOFT)

# ----------------------------------------------------------------- 3D centerpiece
func _build_env() -> void:
	var cam := Camera3D.new()
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	cam.fov = 26.0
	# Más lejos y un pelín más alto que antes: el líder debe caber ENTERO entre
	# la barra superior y el trío de botones (ya no hay paneles que lo tapen).
	cam.look_at_from_position(Vector3(0.0, 1.75, 6.2), Vector3(0.0, 1.05, 0.0), Vector3.UP)
	add_child(cam)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -35, 0)
	sun.light_energy = 1.35
	add_child(sun)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = UITheme.BG_DEEP   # sigue el tema (claro cálido / navy)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.98, 0.92)
	env.ambient_light_energy = 1.1
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
	mat.albedo_color = Color(0.95, 0.85, 0.55)   # peana dorada clara
	mat.metallic = 0.35
	mat.roughness = 0.45
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
	# CIELO: banda amarilla intensa arriba que se funde con el fondo, y un
	# "suelo" crema suave abajo que asienta los botones (como el mockup).
	var sky := _vgrad(Color(SUN.r, SUN.g, SUN.b, 0.9), Color(SUN.r, SUN.g, SUN.b, 0.0))
	sky.set_anchors_preset(Control.PRESET_TOP_WIDE)
	sky.offset_bottom = 320
	layer.add_child(sky)
	var gcol := UITheme.BG   # "suelo" que asienta los botones (sigue el tema)
	var ground := _vgrad(Color(gcol.r, gcol.g, gcol.b, 0.0), Color(gcol.r, gcol.g, gcol.b, 0.9))
	ground.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	ground.offset_top = -280
	layer.add_child(ground)

	_build_bg_particles(layer)

	# (Se quitó el "cuadro de luz" sobre la figura: se veía translúcido y no
	# ayudaba. El líder se acompaña solo con el halo cálido bajo el botón BATALLA.)

	_build_topbar(layer)
	_build_centerpiece(layer)
	_build_chests(layer)
	_build_side(layer)
	_build_buttons(layer)
	layer.add_child(UITheme.bottom_nav(self, "home"))
	_build_reward_modal()

	var ts := PanelContainer.new()
	ts.set_anchors_preset(Control.PRESET_CENTER)
	ts.offset_left = -150
	ts.offset_right = 150
	ts.offset_top = 50
	ts.offset_bottom = 92
	ts.add_theme_stylebox_override("panel", _card_style(UITheme.GOLD.darkened(0.1), 14))
	ts.visible = false
	_toast = _lbl("", 16, INK, true, 700)
	ts.add_child(_toast)
	layer.add_child(ts)
	_toast.set_meta("box", ts)

## Barra superior de PÍLDORAS flotantes: identidad (tocar = Perfil) + saldos + ⚙.
func _build_topbar(layer: CanvasLayer) -> void:
	var tb := HBoxContainer.new()
	tb.set_anchors_preset(Control.PRESET_TOP_WIDE)
	tb.offset_left = 10
	tb.offset_right = -10
	tb.offset_top = 10
	tb.offset_bottom = 96
	tb.add_theme_constant_override("separation", 8)
	layer.add_child(tb)

	# --- identidad: avatar + nombre + Nv + barra XP → toca para abrir tu PERFIL
	var idp := PanelContainer.new()
	idp.add_theme_stylebox_override("panel", _card_style(UITheme.GOLD.darkened(0.05), 18))
	tb.add_child(idp)
	var ih := HBoxContainer.new()
	ih.add_theme_constant_override("separation", 9)
	idp.add_child(ih)
	ih.add_child(_avatar())
	var who := VBoxContainer.new()
	who.add_theme_constant_override("separation", 2)
	who.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ih.add_child(who)
	var nm := _lbl(Settings.name_or_default(), 18, INK, true, 800)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	who.add_child(nm)
	var lvrow := HBoxContainer.new()
	lvrow.add_theme_constant_override("separation", 6)
	who.add_child(lvrow)
	var lvpill := PanelContainer.new()
	var lsb := StyleBoxFlat.new()
	lsb.bg_color = MODE_GOLD
	lsb.set_corner_radius_all(8)
	lsb.set_content_margin_all(0)
	lsb.content_margin_left = 7
	lsb.content_margin_right = 7
	lvpill.add_theme_stylebox_override("panel", lsb)
	lvpill.add_child(_lbl("Nv %d" % Inventory.level, 12, Color(0.28, 0.19, 0.02), true, 800))
	lvrow.add_child(lvpill)
	var xpbar := ProgressBar.new()
	xpbar.custom_minimum_size = Vector2(96, 11)
	xpbar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	xpbar.show_percentage = false
	xpbar.max_value = maxf(1.0, float(Inventory.xp_needed()))
	xpbar.value = clampf(float(Inventory.xp), 0.0, xpbar.max_value)
	var xbg := StyleBoxFlat.new(); xbg.bg_color = Color(0.88, 0.85, 0.76); xbg.set_corner_radius_all(4)
	var xfg := StyleBoxFlat.new(); xfg.bg_color = MODE_GOLD.darkened(0.06); xfg.set_corner_radius_all(4)
	xpbar.add_theme_stylebox_override("background", xbg)
	xpbar.add_theme_stylebox_override("fill", xfg)
	lvrow.add_child(xpbar)
	var idbtn := Button.new()
	idbtn.flat = true
	idbtn.set_anchors_preset(Control.PRESET_FULL_RECT)
	idbtn.pressed.connect(func():
		Sfx.play("ui_click")
		get_tree().change_scene_to_file("res://scenes/profile.tscn"))
	idp.add_child(idbtn)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tb.add_child(sp)
	# saldos REALES (🪙 por subir de nivel · 💎 cada 5 niveles y en cofres)
	tb.add_child(_chip("🪙", str(Inventory.coins)))
	tb.add_child(_chip("💎", str(Inventory.gems)))
	var gear := _icon_btn("⚙")
	gear.pressed.connect(_toggle_settings)
	tb.add_child(gear)

func _build_centerpiece(layer: CanvasLayer) -> void:
	var d: Dictionary = Roster.FIGURES[_lead()]
	# UNA píldora-cabecera centrada bajo la barra (el nombre encima del líder
	# le atravesaba el torso): "★ Nombre · RAREZA" con borde de su rareza.
	var box := HBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	box.offset_left = -180
	box.offset_right = 180
	box.offset_top = 74
	box.offset_bottom = 108
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	layer.add_child(box)
	var rar := FigureCard.rarity_color(d)
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", _card_style(rar.darkened(0.05), 14))
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pl := _lbl("★ %s · %s" % [String(d["name"]), FigureCard.rarity_name(d)], 12, INK, true, 800)
	pill.add_child(pl)
	box.add_child(pill)

## BARRA DE NAVEGACIÓN INFERIOR (antes eran carriles a los lados): Colección /
## Crear / 🎁 Recompensas (cofres+cajas, con punto rojo y estado) / Tienda /
## Cómo jugar. Los espacios de las cajas se abren desde 🎁 Recompensas.
## RAIL lateral (derecha): 🎁 Recompensas (cajas/anuncios) y 🎓 Cómo jugar. Se
## separan de la barra inferior (que es solo navegación Inicio/Colección/Tienda/
## Inventario) para no mezclar "acciones" con "navegación".
func _build_side(layer: CanvasLayer) -> void:
	var right := VBoxContainer.new()
	right.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	right.offset_left = -108
	right.offset_right = -10
	right.offset_top = -100
	right.add_theme_constant_override("separation", 12)
	layer.add_child(right)
	var rew := _rail_card("🎁", "Recompensas", MODE_GOLD.darkened(0.05), _open_rewards, "…")
	_reward_state = rew.get_meta("sub")
	_reward_dot = rew.get_meta("dot")
	right.add_child(rew)
	var tut := _rail_card("🎓", "Cómo jugar", MODE_GOLD.darkened(0.1),
		func(): get_tree().change_scene_to_file("res://scenes/tutorials.tscn"))
	(tut.get_meta("dot") as Control).visible = TutorialLib.pending_total() > 0
	right.add_child(tut)

## FILA DE COFRES visible en el Home (Gratis / Cofres ganados con su TIEMPO de
## liberación / Nivel), tocable para abrir. Registra los estados en _chest_states
## (los refresca _refresh_chest_states cada 0.5 s con el timer/¡ABRIR! en vivo).
func _build_chests(layer: CanvasLayer) -> void:
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_TOP_LEFT)
	row.offset_left = 10
	row.offset_top = 108
	row.add_theme_constant_override("separation", 8)
	layer.add_child(row)
	for id in ["free", "won", "level"]:
		var slot := _chest_slot(id)
		row.add_child(slot)
		if id == "level":
			_level_slot = slot   # oculto si no hay cofres de nivel
	_refresh_chest_states()

## Un ítem de la barra inferior: icono + etiqueta corta, punto rojo de aviso
## (meta "dot") y sub-estado opcional (meta "sub", p. ej. estado de cofres).
func _nav_item(icon: String, caption: String, accent: Color, want_sub: bool, sub: String, cb: Callable) -> Control:
	var p := Control.new()
	p.custom_minimum_size = Vector2(60, 64)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	v.add_child(_lbl(icon, 22, accent, false, 700))
	var cap := _lbl(caption, 9, INK, true, 700)
	cap.clip_text = true
	v.add_child(cap)
	if want_sub:
		var sl := _lbl(sub, 8, INK_SOFT, true, 700)
		sl.clip_text = true
		v.add_child(sl)
		p.set_meta("sub", sl)
	var b := Button.new()
	b.flat = true
	b.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.pressed.connect(func(): Sfx.play("ui_click"); cb.call())
	b.button_down.connect(func(): p.pivot_offset = p.size * 0.5; p.scale = Vector2(0.9, 0.9))
	b.button_up.connect(func(): p.scale = Vector2.ONE)
	p.add_child(b)
	var dot := Panel.new()
	var ds := StyleBoxFlat.new()
	ds.bg_color = DOT_RED
	ds.set_corner_radius_all(6)
	ds.set_border_width_all(2)
	ds.border_color = UITheme.SURFACE
	dot.add_theme_stylebox_override("panel", ds)
	dot.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	dot.offset_left = -16
	dot.offset_right = -4
	dot.offset_top = 2
	dot.offset_bottom = 14
	dot.visible = false
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(dot)
	p.set_meta("dot", dot)
	return p

func _open_rewards() -> void:
	Sfx.play("ui_click")
	if _reward_modal != null and is_instance_valid(_reward_modal):
		_refresh_ad_cards()
		_reward_modal.visible = true

## Popup 🎁 Recompensas: los 3 cofres del lobby + acceso al Inventario. Se
## PRE-construye oculto para que sus estados vivan desde el arranque (los
## refresca _refresh_chest_states y los valida test_menu_smoke).
func _build_reward_modal() -> void:
	# OJO: un CanvasLayer NO hereda el `visible` de un Control padre (se dibuja
	# aparte) — por eso el modal ES el CanvasLayer y ocultamos ESE.
	_reward_modal = CanvasLayer.new()
	_reward_modal.name = "RewardModal"
	_reward_modal.layer = 26
	_reward_modal.visible = false
	add_child(_reward_modal)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			_reward_modal.visible = false)
	_reward_modal.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	_reward_modal.add_child(cc)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(400.0, get_viewport().get_visible_rect().size.x - 28.0), 0)
	panel.add_theme_stylebox_override("panel", _card_style(MODE_GOLD.darkened(0.05), 22))
	cc.add_child(panel)
	# Scroll: con cofres + anuncios + cajas por tipo el popup no cabe en pantallas
	# bajas -> se desliza (arriba→abajo), como el resto de la UI.
	var scr := ScrollContainer.new()
	scr.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scr.custom_minimum_size = Vector2(0, minf(get_viewport().get_visible_rect().size.y * 0.8, 640.0))
	panel.add_child(scr)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 9)
	scr.add_child(vb)
	vb.add_child(_lbl("🎁 Recompensas", 19, INK, true, 800))

	# (Los COFRES viven ahora en la fila del Home, con su tiempo en vivo. Aquí
	# el popup se centra en ANUNCIOS y CAJAS por tipo + acceso al inventario.)
	var inv := Button.new()
	inv.text = "📦 Inventario y descifrado"
	inv.custom_minimum_size = Vector2(0, 46)
	UITheme.button_font(inv, 14, Color(0.28, 0.19, 0.02), true, 800)
	UITheme.style_primary(inv, MODE_GOLD, 14)
	inv.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/inventory.tscn"))
	vb.add_child(inv)

	# --- 📺 ANUNCIOS (usos por día) ---
	vb.add_child(_reward_hdr("📺 Anuncios · recursos gratis cada día"))
	var adrow := HBoxContainer.new()
	adrow.alignment = BoxContainer.ALIGNMENT_CENTER
	adrow.add_theme_constant_override("separation", 8)
	vb.add_child(adrow)
	for kind in ["coins", "gems", "box"]:
		adrow.add_child(_ad_card(kind))

	# --- 🎁 CAJAS POR TIPO (compra + abre al momento) ---
	vb.add_child(_reward_hdr("🎁 Cajas por tipo · consigue lo que buscas"))
	var boxgrid := GridContainer.new()
	boxgrid.columns = 2
	boxgrid.add_theme_constant_override("h_separation", 8)
	boxgrid.add_theme_constant_override("v_separation", 8)
	vb.add_child(boxgrid)
	for tid in ["figures", "attack", "passive", "random"]:
		boxgrid.add_child(_buybox_card(tid))
	var bhint := _lbl("Mejor rareza = más contenido. La Variada da de todo.", 10, INK_SOFT, false, 600)
	bhint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(bhint)

	var close := Button.new()
	close.text = "Cerrar"
	close.custom_minimum_size = Vector2(0, 40)
	UITheme.button_font(close, 13, INK_SOFT, true, 700)
	UITheme.style_surface(close, Color(0.95, 0.93, 0.88), Color(0, 0, 0, 0.10), 12)
	close.pressed.connect(func(): _reward_modal.visible = false)
	vb.add_child(close)
	_refresh_chest_states()
	_refresh_ad_cards()

## Encabezado de sección dentro del popup de recompensas (tinta suave).
func _reward_hdr(text: String) -> Label:
	var l := _lbl(text, 12, INK_SOFT, true, 800)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return l

## Tarjeta de ANUNCIO: icono + nombre + "quedan N hoy"; toca para ver+reclamar.
func _ad_card(kind: String) -> Control:
	var spec: Dictionary = Inventory.AD_TYPES[kind]
	var col: Color = MODE_GOLD if kind == "coins" else (Color(0.36, 0.7, 0.95) if kind == "gems" else Color(0.13, 0.62, 0.36))
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(112, 92)
	p.add_theme_stylebox_override("panel", _card_style(col, 14))
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 1)
	p.add_child(v)
	v.add_child(_lbl(String(spec["icon"]), 24, col, false, 700))
	var nm := _lbl(String(spec["name"]), 10, INK, true, 800)
	nm.clip_text = true
	v.add_child(nm)
	var left := _lbl("", 10, INK_SOFT, true, 700)
	v.add_child(left)
	p.set_meta("left", left)
	var b := Button.new()
	b.flat = true
	b.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.pressed.connect(func(): _watch_ad(kind))
	p.add_child(b)
	_ad_cards[kind] = p
	return p

## Tarjeta de compra de CAJA por tipo: icono + nombre + precio.
func _buybox_card(tid: String) -> Control:
	var spec: Dictionary = Inventory.BOX_TYPES[tid]
	var pr: Dictionary = Inventory.BOX_PRICE[tid]
	var cc: Array = spec["col"]
	var col := Color(cc[0], cc[1], cc[2])
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(0, 62)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", _card_style(col, 14))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	p.add_child(h)
	h.add_child(_lbl(String(spec["icon"]), 24, col, false, 700))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.add_theme_constant_override("separation", 0)
	h.add_child(v)
	var nm := _lbl(String(spec["name"]).replace("Caja de ", "").replace("Caja ", ""), 12, INK, true, 800)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(nm)
	var cur_icon := "💎" if String(pr["cur"]) == "gems" else "🪙"
	var price := _lbl("%s %d" % [cur_icon, int(pr["price"])], 11, INK_SOFT, true, 700)
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(price)
	var b := Button.new()
	b.flat = true
	b.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.pressed.connect(func(): _buy_box(tid))
	p.add_child(b)
	return p

## Ver un anuncio: breve simulación → reclama la recompensa de Inventory.
func _watch_ad(kind: String) -> void:
	if Inventory.ad_left(kind) <= 0:
		_toast_msg("Sin usos hoy — vuelve mañana")
		return
	Sfx.play("ui_click")
	# ANUNCIO: si hay plugin AdMob, muestra uno REAL; si no, overlay simulado.
	# La recompensa se da SOLO si el usuario lo completa (Ads.show_rewarded).
	var completed := true
	if Ads.available():
		completed = await Ads.show_rewarded()
	else:
		var layer := CanvasLayer.new()
		layer.layer = 42
		add_child(layer)
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, 0.8)
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		dim.mouse_filter = Control.MOUSE_FILTER_STOP
		layer.add_child(dim)
		var msg := _lbl("📺 Viendo anuncio…", 20, Color.WHITE, true, 800)
		msg.set_anchors_preset(Control.PRESET_CENTER)
		layer.add_child(msg)
		completed = await Ads.show_rewarded()
		await get_tree().create_timer(1.4).timeout
		layer.queue_free()
	if not completed:
		_toast_msg("Anuncio no completado — sin recompensa")
		return
	var res: Dictionary = Inventory.watch_ad(kind)
	if not bool(res.get("ok", false)):
		_toast_msg("Sin usos hoy — vuelve mañana")
		return
	_refresh_topbar_funds()
	_refresh_ad_cards()
	if kind == "box":
		var box: Dictionary = res.get("box", {})
		_show_box_reward("random", box)
	elif kind == "coins":
		_toast_msg("🪙 +%d monedas" % int(res.get("coins", 0)))
	else:
		_toast_msg("💎 +%d diamantes" % int(res.get("gems", 0)))

## Comprar+abrir una caja por tipo.
func _buy_box(tid: String) -> void:
	var res: Dictionary = Inventory.buy_box(tid)
	if not bool(res.get("ok", false)):
		_toast_msg(String(res.get("error", "No se pudo")))
		return
	Sfx.play("ui_click")
	_refresh_topbar_funds()
	_show_box_reward(tid, res.get("box", {}))

## Muestra las piezas de una caja abierta reutilizando la animación de cofre.
func _show_box_reward(tid: String, box: Dictionary) -> void:
	var lines: Array = []
	for key in box.get("pieces", []):
		lines.append("%s %s" % [_piece_icon(String(key)), Inventory.piece_name(String(key))])
	if int(box.get("gems", 0)) > 0:
		lines.append("💎 +%d ¡DIAMANTES!" % int(box["gems"]))
	# reusa la animación con el color/icono del tipo (o del cofre "won" por defecto)
	var col: Color = MODE_GOLD
	if Inventory.BOX_TYPES.has(tid):
		var cc: Array = Inventory.BOX_TYPES[tid]["col"]
		col = Color(cc[0], cc[1], cc[2])
	_open_reward_anim(String(Inventory.BOX_TYPES.get(tid, {}).get("icon", "📦")), col, lines)

## Refresca los contadores "quedan N hoy" de las tarjetas de anuncio.
func _refresh_ad_cards() -> void:
	for kind in _ad_cards.keys():
		var card = _ad_cards[kind]
		if is_instance_valid(card) and card.has_meta("left"):
			var l: Label = card.get_meta("left")
			var n := Inventory.ad_left(kind)
			l.text = ("quedan %d hoy" % n) if n > 0 else "agotado hoy"
			l.add_theme_color_override("font_color", INK_SOFT if n > 0 else DOT_RED)

## Refresca los chips 🪙/💎 de la barra superior tras ganar recursos.
func _refresh_topbar_funds() -> void:
	if _coin_lbl != null and is_instance_valid(_coin_lbl):
		_coin_lbl.text = str(Inventory.coins)
	if _gem_lbl != null and is_instance_valid(_gem_lbl):
		_gem_lbl.text = str(Inventory.gems)

## Slot de cofre del popup 🎁: tarjeta blanca con borde de color + estado en vivo.
func _chest_slot(id: String) -> Control:
	var st: Dictionary = CHEST_LOBBY[id]
	var col: Color = st["col"]
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(104, 100)
	p.add_theme_stylebox_override("panel", _card_style(col, 16))
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 3)
	p.add_child(v)
	var icon := _lbl(String(st["icon"]), 26, col, false, 700)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(icon)
	v.add_child(_lbl(String(st["name"]), 11, col.darkened(0.15), true, 800))
	var state := _lbl("…", 12, INK_SOFT, true, 700)
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
	_open_reward_anim(String(st["icon"]), st["col"], lines)

## Animación de apertura genérica (icono + color + recompensas). La usan los
## cofres del lobby, las cajas por tipo compradas y el anuncio de caja.
func _open_reward_anim(icon: String, col: Color, lines: Array) -> void:
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
	var chest := _lbl(icon, 84, col.lightened(0.15), false, 800)
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

## TRÍO de modos (como la referencia): 🎲 Probar (azul) · ⚔ BATALLA (dorado,
## central y MÁS grande — dentro va el Deck Builder: mazos + dificultad + CPU) ·
## 🌐 Online (morado, salas privadas por código).
func _build_buttons(layer: CanvasLayer) -> void:
	# Halo pulsante CIRCULAR detrás del botón central (círculo real, no un rect
	# con degradado que se veía cuadrado).
	var halo := Panel.new()
	var hsb := StyleBoxFlat.new()
	hsb.bg_color = Color(MODE_GOLD.r, MODE_GOLD.g, MODE_GOLD.b, 0.17)   # halo tenue
	hsb.set_corner_radius_all(170)
	hsb.anti_aliasing = true
	halo.add_theme_stylebox_override("panel", hsb)
	halo.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	halo.offset_left = -170
	halo.offset_right = 170
	halo.offset_top = -300
	halo.offset_bottom = -120
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(halo)
	var hp := create_tween().set_loops()
	hp.tween_property(halo, "modulate:a", 0.7, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	hp.tween_property(halo, "modulate:a", 0.3, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# "Probar" NO va a producción -> en su lugar el acceso a CREAR personaje.
	var crear := _mode_button("🛠", "Crear", "arma personajes", MODE_BLUE, false)
	crear.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	crear.offset_left = 12
	crear.offset_right = 162
	crear.offset_top = -204
	crear.offset_bottom = -104
	crear.pressed.connect(func():
		Sfx.play("ui_click")
		get_tree().change_scene_to_file("res://scenes/character_creator.tscn"))
	layer.add_child(crear)
	_shine_sweep(crear, 2.3, 0.22)   # desfasado del central

	var online := _mode_button("🌐", "Online", "sala privada", MODE_PURPLE, false)
	online.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	online.offset_left = -162
	online.offset_right = -12
	online.offset_top = -204
	online.offset_bottom = -104
	online.pressed.connect(func():
		Sfx.play("ui_click")
		get_tree().change_scene_to_file("res://scenes/online_lobby.tscn"))
	layer.add_child(online)
	_shine_sweep(online, 3.1, 0.22)   # otro desfase: nunca brillan a la vez

	var play := _mode_button("⚔", "BATALLA", "mazos · dificultad · CPU", MODE_GOLD, true)
	play.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	play.offset_left = -104
	play.offset_right = 104
	play.offset_top = -258
	play.offset_bottom = -98
	play.pressed.connect(func():
		# Primera vez: tutorial guiado directo al tablero (mapa 0, CPU pasiva).
		if not Settings.tutorial_done:
			Loadout.tutorial = true
			get_tree().change_scene_to_file("res://scenes/board.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/deck_builder.tscn"))
	layer.add_child(play)
	_juice_play(play)

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
	_shine_sweep(play, 1.1, 0.34)

## BARRIDO DE BRILLO mejorado: banda diagonal con doble borde suave (entra y sale
## fundida, no un corte duro) que cruza el botón cada `pause` segundos. Se aplica
## a los 3 botones de modo con desfases distintos para que no brillen a la vez.
func _shine_sweep(btn: Button, pause: float, peak: float) -> void:
	btn.clip_contents = true
	await get_tree().process_frame
	var shine := TextureRect.new()
	shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g := Gradient.new()
	# perfil suave: 0 → tenue → PICO → tenue → 0 (sin bordes duros)
	g.set_color(0, Color(1, 1, 1, 0.0))
	g.set_color(1, Color(1, 1, 1, 0.0))
	g.add_point(0.30, Color(1, 1, 1, peak * 0.35))
	g.add_point(0.50, Color(1, 1, 1, peak))
	g.add_point(0.70, Color(1, 1, 1, peak * 0.35))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 0)
	shine.texture = gt
	shine.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shine.stretch_mode = TextureRect.STRETCH_SCALE
	shine.rotation_degrees = 20.0
	var w := maxf(64.0, btn.size.x * 0.42)
	shine.size = Vector2(w, maxf(120.0, btn.size.y * 2.6))
	shine.position = Vector2(-w - 30.0, -btn.size.y * 0.8)
	btn.add_child(shine)
	var sw := create_tween().set_loops()
	sw.tween_interval(pause)
	sw.tween_property(shine, "position:x", btn.size.x + w, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sw.tween_callback(func(): shine.position.x = -w - 30.0)

## Partículas suaves de fondo: puntos de color que flotan lentamente (el menú
## deja de verse estático/triste sin costar nada de rendimiento).
## Partículas de fondo: motas CIRCULARES pequeñas, tenues y lentas (antes eran
## degradados en rect que se veían CUADRADOS). Círculo real = Panel con esquinas
## totalmente redondeadas; suben flotando suave. Solo ambiente, muy sutil.
func _build_bg_particles(layer: CanvasLayer) -> void:
	var vw := get_viewport().get_visible_rect().size
	var cols := [MODE_BLUE, MODE_GOLD, MODE_PURPLE, Color(0.3, 0.8, 0.5)]
	for i in 10:
		var col: Color = cols[i % cols.size()]
		var size := 8.0 + randf() * 12.0
		var dot := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(col.r, col.g, col.b, 0.14 + randf() * 0.10)
		sb.set_corner_radius_all(int(size))   # esquinas = radio -> círculo perfecto
		sb.anti_aliasing = true
		dot.add_theme_stylebox_override("panel", sb)
		dot.custom_minimum_size = Vector2(size, size)
		dot.size = Vector2(size, size)
		dot.position = Vector2(randf() * vw.x, randf() * vw.y)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(dot)
		var tw := create_tween().set_loops()
		var dur := 3.6 + randf() * 3.6
		var rise := 30.0 + randf() * 55.0
		tw.tween_property(dot, "position:y", dot.position.y - rise, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(dot, "position:y", dot.position.y, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# ----------------------------------------------------------------- widgets
func _radial(col: Color, alpha: float) -> TextureRect:
	var tr := TextureRect.new()
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g := Gradient.new()
	# Falloff que llega a 0 ANTES del borde (por ~0.72 del radio) para que no
	# quede alpha en los lados del rect y no se vea un cuadro translúcido.
	g.set_color(0, Color(col.r, col.g, col.b, alpha))
	g.add_point(0.72, Color(col.r, col.g, col.b, 0.0))
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
	p.custom_minimum_size = Vector2(56, 56)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sb := StyleBoxFlat.new()
	sb.bg_color = UITheme.PRIMARY.darkened(0.1)
	sb.set_corner_radius_all(28)
	sb.set_border_width_all(3)
	sb.border_color = MODE_GOLD
	p.add_theme_stylebox_override("panel", sb)
	var l := _lbl(Settings.name_initials(), 20, Color.WHITE, true, 800)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p

## Píldora blanca de saldo (🪙/💎) — flotante, texto tinta. Guarda la etiqueta
## del valor para poder refrescarla al ganar recursos por anuncios.
func _chip(icon: String, value: String) -> Control:
	var p := PanelContainer.new()
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sb := _card_style(Color(0, 0, 0, 0.06), 16)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 9
	sb.content_margin_bottom = 11
	p.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 5)
	p.add_child(h)
	h.add_child(_lbl(icon, 18, INK, false, 600))
	var val := _lbl(value, 18, INK, true, 800)
	h.add_child(val)
	if icon == "🪙":
		_coin_lbl = val
	elif icon == "💎":
		_gem_lbl = val
	return p

# --------------------------------------------------- widgets del tema claro
## Tarjeta "chunky": crema con LABIO inferior 3D (borde grueso abajo, fino a
## los lados) tintado con el acento — el look presionable del mockup.
func _card_style(accent: Color, radius := 18) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = CARD_BG
	sb.set_corner_radius_all(radius)
	sb.border_color = accent.lerp(CARD_LIP, 0.45)
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 7
	sb.shadow_color = Color(0.45, 0.34, 0.06, 0.16)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	sb.set_content_margin_all(8)
	sb.content_margin_bottom = 12
	return sb

## Brillo superior (gloss) que se FUNDE hacia abajo — da volumen sin verse
## como una banda pegada (degradado blanco→transparente, insetado del borde).
func _gloss(target: Control, _radius: int) -> void:
	var g := _vgrad(Color(1, 1, 1, 0.30), Color(1, 1, 1, 0.0))
	g.set_anchors_preset(Control.PRESET_TOP_WIDE)
	g.anchor_bottom = 0.55
	g.offset_left = 7
	g.offset_right = -7
	g.offset_top = 5
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.add_child(g)

## Gradiente vertical (cielo/suelo).
func _vgrad(top: Color, bottom: Color) -> TextureRect:
	var tr := TextureRect.new()
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g := Gradient.new()
	g.set_color(0, top)
	g.set_color(1, bottom)
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	tr.texture = gt
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	return tr

## Tarjeta de carril: icono + nombre (+ sub-estado opcional) + punto rojo de
## aviso (meta "dot"; el sub-Label queda en meta "sub"). La raíz es un Control
## plano (NO PanelContainer: ese estira a TODOS los hijos y el punto rojo
## acabaría tapando la tarjeta completa).
func _rail_card(icon: String, caption: String, accent: Color, cb: Callable, sub := "") -> Control:
	var p := Control.new()
	p.custom_minimum_size = Vector2(98, 92)
	var bg := Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_theme_stylebox_override("panel", _card_style(accent, 18))
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(bg)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 1)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	var ic := _lbl(icon, 30, accent, false, 700)
	v.add_child(ic)
	var cap := _lbl(caption, 11, INK, true, 800)
	cap.clip_text = true
	v.add_child(cap)
	if sub != "":
		var sl := _lbl(sub, 10, INK_SOFT, true, 700)
		v.add_child(sl)
		p.set_meta("sub", sl)
	var b := Button.new()
	b.flat = true
	b.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.pressed.connect(func():
		Sfx.play("ui_click")
		cb.call())
	# se HUNDE al tocarla (botón físico, como los modos de abajo)
	b.button_down.connect(func():
		p.pivot_offset = p.size * 0.5
		p.scale = Vector2(0.94, 0.94))
	b.button_up.connect(func(): p.scale = Vector2.ONE)
	p.add_child(b)
	# punto rojo de aviso (arriba-derecha), oculto por defecto
	var dot := Panel.new()
	var ds := StyleBoxFlat.new()
	ds.bg_color = DOT_RED
	ds.set_corner_radius_all(7)
	ds.set_border_width_all(2)
	ds.border_color = Color.WHITE
	dot.add_theme_stylebox_override("panel", ds)
	dot.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	dot.offset_left = -17
	dot.offset_right = -3
	dot.offset_top = 3
	dot.offset_bottom = 17
	dot.visible = false
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(dot)
	p.set_meta("dot", dot)
	return p

## Botón de MODO de juego EXTRUIDO (mockup): cara de color con brillo arriba y
## LABIO inferior oscuro grueso; al presionar, el labio se encoge y la cara
## baja — se siente un botón físico. El central (big) es mayor.
func _mode_button(icon: String, title: String, sub: String, col: Color, big: bool) -> Button:
	var b := Button.new()
	var lip := col.darkened(0.32)
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(22)
	sb.border_color = lip
	sb.border_width_bottom = 9
	sb.shadow_color = Color(lip.r, lip.g, lip.b, 0.35)
	sb.shadow_size = 7
	sb.shadow_offset = Vector2(0, 4)
	sb.content_margin_bottom = 9
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("focus", sb)
	var pr: StyleBoxFlat = sb.duplicate()
	pr.bg_color = col.darkened(0.10)
	pr.border_width_bottom = 2
	pr.content_margin_top = 7
	pr.content_margin_bottom = 2
	pr.shadow_size = 2
	pr.shadow_offset = Vector2(0, 1)
	b.add_theme_stylebox_override("pressed", pr)
	_gloss(b, 22)
	var fg := Color(0.28, 0.19, 0.02) if big else Color.WHITE
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", -2)
	b.add_child(v)
	v.add_child(_lbl(icon, 36 if big else 26, fg, false, 700))
	v.add_child(_lbl(title, 21 if big else 15, fg, true, 900))
	var s := _lbl(sub, 10, Color(fg.r, fg.g, fg.b, 0.82), true, 700)
	s.clip_text = true
	v.add_child(s)
	return b

# ---------------------------------------------------------------- settings
## ATRÁS (Android) en el menú: abre/cierra la Configuración en vez de salir.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_toggle_settings()

## Cambia el tema y RECARGA el Home para aplicarlo de inmediato en todo.
func _set_theme(darkv: bool) -> void:
	if Settings.dark_mode == darkv:
		return
	Settings.set_dark_mode(darkv)
	get_tree().reload_current_scene()

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
	# VERSIÓN visible: para comprobar en el teléfono que el build instalado es
	# el esperado. `config/version` la sincroniza el script del .aab con el
	# versionCode; "red vN" es el protocolo online (debe coincidir en ambos).
	var vlbl := _lbl("Versión %s  ·  red v%d" % [
		String(ProjectSettings.get_setting("application/config/version", "?")),
		NetSession.NET_BUILD], 12, UITheme.MUTED, false, 600)
	vb.add_child(vlbl)

	# --- TEMA: claro (Juicy Hall) / oscuro (fácil para la vista) ---
	var th := Label.new()
	UITheme.section(th, "Tema")
	th.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vb.add_child(th)
	var trow := HBoxContainer.new()
	trow.add_theme_constant_override("separation", 8)
	vb.add_child(trow)
	var tlight := Button.new()
	var tdark := Button.new()
	var tstyle := func():
		tlight.text = "☀ Claro" + ("  ✓" if not Settings.dark_mode else "")
		tdark.text = "🌙 Oscuro" + ("  ✓" if Settings.dark_mode else "")
		if Settings.dark_mode:
			UITheme.style_surface(tlight, UITheme.SURFACE2, UITheme.BORDER, 10)
			UITheme.style_primary(tdark, UITheme.PRIMARY, 10)
		else:
			UITheme.style_primary(tlight, UITheme.GOLD.darkened(0.05), 10)
			UITheme.style_surface(tdark, UITheme.SURFACE2, UITheme.BORDER, 10)
	for b in [tlight, tdark]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 42)
		UITheme.button_font(b, 14, UITheme.TEXT, true, 700)
		trow.add_child(b)
	tlight.pressed.connect(func(): _set_theme(false))
	tdark.pressed.connect(func(): _set_theme(true))
	tstyle.call()

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

	# --- ADMIN: 🤖 MODO ROBOT (pruebas automáticas EN la app, con log) ---
	if Inventory.is_admin():
		var rh := Label.new()
		UITheme.section(rh, "Pruebas automáticas (admin)")
		rh.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		vb.add_child(rh)
		var rrow := HBoxContainer.new()
		rrow.add_theme_constant_override("separation", 8)
		vb.add_child(rrow)
		var rb := Button.new()
		rb.text = "🤖 Prueba automática"
		rb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rb.custom_minimum_size = Vector2(0, 42)
		UITheme.button_font(rb, 13, UITheme.TEXT, true, 700)
		UITheme.style_surface(rb, UITheme.SURFACE2, UITheme.ORANGE.darkened(0.2), 10)
		rb.pressed.connect(func():
			modal.queue_free()
			AutoTester.start(get_tree(), false))
		rrow.add_child(rb)
		var bb := Button.new()
		bb.text = "🔥 Burn-in (10 partidas)"
		bb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bb.custom_minimum_size = Vector2(0, 42)
		UITheme.button_font(bb, 13, UITheme.TEXT, true, 700)
		UITheme.style_surface(bb, UITheme.SURFACE2, UITheme.DANGER.darkened(0.3), 10)
		bb.pressed.connect(func():
			modal.queue_free()
			AutoTester.start(get_tree(), true))
		rrow.add_child(bb)
		var rhint := Label.new()
		rhint.text = "Hace compras/crafteos/mazos/cofres reales y juega partidas CPU vs CPU con log [PASS]/[FAIL]. Respalda y RESTAURA tus datos al terminar."
		rhint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rhint.custom_minimum_size = Vector2(430, 0)
		UITheme.label(rhint, 11, UITheme.MUTED, false, 600)
		vb.add_child(rhint)

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

## Botón redondo blanco (⚙): flotante, texto tinta.
func _icon_btn(icon: String) -> Button:
	var b := Button.new()
	b.text = icon
	b.custom_minimum_size = Vector2(56, 56)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UITheme.button_font(b, 24, INK_SOFT, false, 600)
	b.add_theme_stylebox_override("normal", _card_style(Color(0, 0, 0, 0.06), 22))
	b.add_theme_stylebox_override("hover", _card_style(Color(0, 0, 0, 0.12), 22))
	var pr := _card_style(Color(0, 0, 0, 0.10), 22)
	pr.bg_color = Color(0.94, 0.92, 0.86)
	b.add_theme_stylebox_override("pressed", pr)
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
