extends Control
## PERFIL (esquema del handoff §11) — SOLO VER: identidad (avatar + nivel + XP),
## estadísticas REALES (ganadas/perdidas/% victorias/mejor racha, persistidas en
## Inventory) y favoritos (mazo activo, mapa elegido, figura ⭐).

var _toast: Label

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UITheme.BG_DEEP
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 16
	root.offset_right = -16
	root.offset_top = 12
	root.offset_bottom = -8
	root.add_theme_constant_override("separation", 13)
	add_child(root)

	var title := Label.new()
	title.text = "Perfil"
	UITheme.label(title, 24, UITheme.TEXT, true, 800)
	root.add_child(title)

	var scr := ScrollContainer.new()
	scr.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scr.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scr)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 13)
	scr.add_child(body)

	_build_identity(body)
	_build_stats(body)
	_build_favs(body)

	_build_nav(root)

	var ts := PanelContainer.new()
	ts.set_anchors_preset(Control.PRESET_CENTER)
	ts.offset_left = -150
	ts.offset_right = 150
	ts.offset_top = -26
	ts.offset_bottom = 26
	ts.add_theme_stylebox_override("panel", UITheme.panel(UITheme.SURFACE, UITheme.GOLD.darkened(0.1), 12, 1, 10))
	ts.visible = false
	_toast = Label.new()
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(_toast, 14, UITheme.GOLD, true, 700)
	ts.add_child(_toast)
	add_child(ts)
	_toast.set_meta("box", ts)

# ---------------------------------------------------------------- identidad
func _build_identity(body: VBoxContainer) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UITheme.group_panel(18, 14))
	body.add_child(card)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	card.add_child(hb)
	# avatar con aro dorado
	var av := Panel.new()
	av.custom_minimum_size = Vector2(58, 58)
	var sb := StyleBoxFlat.new()
	sb.bg_color = UITheme.PRIMARY.darkened(0.1)
	sb.set_corner_radius_all(29)
	sb.set_border_width_all(3)
	sb.border_color = UITheme.GOLD
	av.add_theme_stylebox_override("panel", sb)
	var ini := Label.new()
	ini.text = Settings.name_initials()
	ini.set_anchors_preset(Control.PRESET_FULL_RECT)
	ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.label(ini, 18, Color.WHITE, true, 800)
	av.add_child(ini)
	hb.add_child(av)
	# nombre + nivel + barra XP
	var who := VBoxContainer.new()
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	who.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	who.add_theme_constant_override("separation", 3)
	hb.add_child(who)
	var nm := Label.new()
	nm.text = Settings.name_or_default()
	UITheme.label(nm, 18, UITheme.TEXT, true, 800)
	who.add_child(nm)
	var xpbar := ProgressBar.new()
	xpbar.custom_minimum_size = Vector2(0, 6)
	xpbar.show_percentage = false
	xpbar.max_value = maxf(1.0, float(Inventory.xp_needed()))
	xpbar.value = clampf(float(Inventory.xp), 0.0, xpbar.max_value)
	var xbg := StyleBoxFlat.new(); xbg.bg_color = Color(0.88, 0.85, 0.76); xbg.set_corner_radius_all(3)
	var xfg := StyleBoxFlat.new(); xfg.bg_color = UITheme.PRIMARY; xfg.set_corner_radius_all(3)
	xpbar.add_theme_stylebox_override("background", xbg)
	xpbar.add_theme_stylebox_override("fill", xfg)
	who.add_child(xpbar)
	var lv := Label.new()
	lv.text = "Nivel %d  ·  %d/%d XP" % [Inventory.level, Inventory.xp, Inventory.xp_needed()]
	UITheme.label(lv, 12, UITheme.MUTED, false, 600)
	who.add_child(lv)
	# lápiz: editar el nombre (se refleja en avatar, Home y online)
	var pen := Button.new()
	pen.text = "✎"
	pen.custom_minimum_size = Vector2(44, 44)
	pen.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UITheme.button_font(pen, 16, UITheme.TEXT2, false, 600)
	UITheme.style_surface(pen, UITheme.SURFACE2, UITheme.BORDER, 11)
	pen.pressed.connect(func(): _edit_name(nm, ini))
	hb.add_child(pen)

## Diálogo para editar el nombre del jugador (1–16 chars). Al aceptar, guarda
## en Settings y refresca el nombre + iniciales del avatar en vivo.
func _edit_name(nm: Label, ini: Label) -> void:
	var dlg := AcceptDialog.new()
	dlg.title = "Editar nombre"
	dlg.ok_button_text = "Guardar"
	dlg.add_cancel_button("Cancelar")
	var le := LineEdit.new()
	le.text = Settings.name_or_default()
	le.max_length = 16
	le.custom_minimum_size = Vector2(300, 44)
	le.add_theme_stylebox_override("normal", UITheme.input())
	le.add_theme_stylebox_override("focus", UITheme.input(UITheme.INPUT_BG, UITheme.PRIMARY))
	le.add_theme_color_override("font_color", UITheme.TEXT)
	le.add_theme_color_override("caret_color", UITheme.PRIMARY_EDGE)
	dlg.add_child(le)
	var apply := func():
		Settings.set_player_name(le.text)
		nm.text = Settings.name_or_default()
		ini.text = Settings.name_initials()
	dlg.confirmed.connect(apply)
	le.text_submitted.connect(func(_t): apply.call(); dlg.hide())
	add_child(dlg)
	dlg.popup_centered()
	le.grab_focus()
	le.select_all()

# ---------------------------------------------------------------- estadísticas
func _build_stats(body: VBoxContainer) -> void:
	var hdr := Label.new()
	UITheme.section(hdr, "Estadísticas")
	body.add_child(hdr)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 9)
	grid.add_theme_constant_override("v_separation", 9)
	body.add_child(grid)
	var total: int = Inventory.wins + Inventory.losses
	var pct := ("%d%%" % roundi(100.0 * Inventory.wins / maxf(1.0, float(total)))) if total > 0 else "—"
	grid.add_child(_stat("Ganadas", str(Inventory.wins), UITheme.SUCCESS))
	grid.add_child(_stat("Perdidas", str(Inventory.losses), UITheme.DANGER))
	grid.add_child(_stat("% Victorias", pct, UITheme.PRIMARY_EDGE))
	grid.add_child(_stat("Mejor racha", str(Inventory.best_streak), UITheme.ORANGE))

func _stat(cap: String, value: String, col: Color) -> Control:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", UITheme.panel(UITheme.PANEL_DEEP, Color(col.r, col.g, col.b, 0.4), 14, 1, 12))
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 1)
	p.add_child(v)
	var vl := Label.new()
	vl.text = value
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(vl, 24, col, true, 800)
	v.add_child(vl)
	var cl := Label.new()
	cl.text = cap
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(cl, 12, UITheme.TEXT2, false, 600)
	v.add_child(cl)
	return p

# ---------------------------------------------------------------- favoritos
func _build_favs(body: VBoxContainer) -> void:
	var hdr := Label.new()
	UITheme.section(hdr, "Favoritos")
	body.add_child(hdr)
	var deck_name := "Mazo 1"
	if not Loadout.decks.is_empty() and Loadout.active_deck < Loadout.decks.size():
		deck_name = String((Loadout.decks[Loadout.active_deck] as Dictionary).get("name", "Mazo 1"))
	var fig_name := "—"
	for fid in Settings.favorites:
		for f in Roster.FIGURES:
			if String(f.get("id", "")) == String(fid):
				fig_name = String(f.get("name", "?"))
				break
		if fig_name != "—":
			break
	body.add_child(_fav_row("🃏", "Mazo activo", deck_name, UITheme.PRIMARY_EDGE))
	body.add_child(_fav_row("🗺", "Mapa elegido", MapData.display_name(Loadout.map_index), UITheme.ENERGY))
	body.add_child(_fav_row("⭐", "Figura favorita", fig_name, UITheme.GOLD))

func _fav_row(icon: String, cap: String, value: String, accent: Color) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.panel(UITheme.PANEL_DEEP, UITheme.GROUP_BORDER, 14, 1, 10))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	p.add_child(hb)
	var tile := UITheme.icon_tile_node(icon, accent, 36, 18)
	hb.add_child(tile)
	var cl := Label.new()
	cl.text = cap
	cl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.label(cl, 14, UITheme.TEXT2, false, 600)
	hb.add_child(cl)
	var vl := Label.new()
	vl.text = value
	vl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.label(vl, 14, UITheme.TEXT, true, 700)
	hb.add_child(vl)
	return p

func _toast_msg(text: String) -> void:
	var box = _toast.get_meta("box") if _toast != null and _toast.has_meta("box") else null
	if box == null:
		return
	_toast.text = text
	box.visible = true
	var t := get_tree().create_timer(1.4)
	t.timeout.connect(func(): if is_instance_valid(box): box.visible = false)

## Nav inferior Home / Tienda / Perfil (activa).
func _build_nav(root: VBoxContainer) -> void:
	var nav := PanelContainer.new()
	nav.add_theme_stylebox_override("panel", UITheme.panel(UITheme.SURFACE, UITheme.BORDER, 12, 1, 4))
	root.add_child(nav)
	var nb := HBoxContainer.new()
	nb.alignment = BoxContainer.ALIGNMENT_CENTER
	nb.add_theme_constant_override("separation", 26)
	nav.add_child(nb)
	nb.add_child(_nav_btn("🏠", "Home", false, func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn")))
	nb.add_child(_nav_btn("🛍", "Tienda", false, func(): get_tree().change_scene_to_file("res://scenes/shop.tscn")))
	nb.add_child(_nav_btn("👤", "Perfil", true, func(): pass))

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
	var il := Label.new()
	il.text = icon
	il.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(il, 18, col, false, 600)
	v.add_child(il)
	var tl := Label.new()
	tl.text = text
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(tl, 11, col, true, 700)
	v.add_child(tl)
	b.pressed.connect(cb)
	return b
