extends Control
## Deck Builder — pick your team of Loadout.DECK_SIZE figures (duplicates allowed)
## before a match. Writes the choice to Loadout.player_team and starts the board.

var _team: Array = []
var _map_index := 0
var _mods: Array = []
var _team_box: HBoxContainer
var _avail_box: VBoxContainer
var _map_box: HBoxContainer
var _modsel_box: GridContainer
var _counter: Label
var _play_btn: Button
var _deck_row: HBoxContainer

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_team = Loadout.player_team.duplicate()
	_map_index = Loadout.map_index
	_mods = Loadout.player_modifiers.duplicate()

	var bg := ColorRect.new()
	bg.color = UITheme.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 14
	root.offset_right = -14
	root.offset_top = 14
	root.offset_bottom = -14
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	# título + contador en una sola línea (más aire para la lista)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	root.add_child(head)
	var title := Label.new()
	title.text = "Arma tu equipo"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.label(title, 26, UITheme.TEXT, true, 800)
	head.add_child(title)
	_counter = Label.new()
	_counter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.label(_counter, 18, UITheme.SUCCESS, true, 800)
	head.add_child(_counter)
	var hint := Label.new()
	hint.text = "Todo se guarda solo: equipo, modificadores y mapa."
	UITheme.label(hint, 11, UITheme.MUTED, false, 600)
	root.add_child(hint)

	# --- TUS MAZOS: tarjetas (el activo lleva ✓ EN USO y es el que JUEGA) ---
	var dh := _hdr("TUS MAZOS  ·  el ✓ EN USO juega online y vs CPU")
	root.add_child(dh)
	var deck_scroll := ScrollContainer.new()
	deck_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	deck_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	deck_scroll.custom_minimum_size = Vector2(0, 84)
	root.add_child(deck_scroll)
	_deck_row = HBoxContainer.new()
	_deck_row.add_theme_constant_override("separation", 8)
	deck_scroll.add_child(_deck_row)
	_theme_scrollbar(deck_scroll.get_h_scroll_bar())
	_build_deck_tabs()
	# acciones sobre el mazo EN USO
	var act_row := HBoxContainer.new()
	act_row.add_theme_constant_override("separation", 8)
	root.add_child(act_row)
	act_row.add_child(_action_btn("✎ Nombre", UITheme.TEXT2, _rename_deck))
	act_row.add_child(_action_btn("⧉ Código", UITheme.GOLD, func():
		DisplayServer.clipboard_set(Loadout.deck_code())
		_counter.text = "⧉ copiado"))
	act_row.add_child(_action_btn("⇪ Importar", UITheme.PRIMARY_EDGE, func():
		var r: Dictionary = Loadout.import_deck_code(DisplayServer.clipboard_get())
		if bool(r["ok"]):
			_switch_deck(Loadout.decks.size() - 1)
		else:
			_counter.text = "✗ código inválido"))
	act_row.add_child(_action_btn("🗑 Borrar", UITheme.DANGER, _confirm_delete_deck))

	# CUERPO scrolleable: todo (mapa/mods/dificultad + equipo + disponibles) se
	# desliza; el header (título/pestañas) y la barra Menú/Jugar quedan fijos.
	var body := ScrollContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	root.add_child(body)
	var body_vb := VBoxContainer.new()
	body_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_vb.add_theme_constant_override("separation", 10)
	body.add_child(body_vb)

	# 1) TU EQUIPO primero: armar el mazo es LO principal de esta pantalla.
	var sec_team := _panel_section(body_vb)
	sec_team.add_child(_hdr("TU EQUIPO  ·  toca una carta para quitarla"))
	# Scroll HORIZONTAL con barra visible: 6 cartas no caben de golpe (§9.1).
	var team_scroll := ScrollContainer.new()
	team_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	team_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	team_scroll.custom_minimum_size = Vector2(0, 84)
	team_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sec_team.add_child(team_scroll)
	_team_box = HBoxContainer.new()
	_team_box.add_theme_constant_override("separation", 8)
	team_scroll.add_child(_team_box)
	_theme_scrollbar(team_scroll.get_h_scroll_bar())

	# 2) DISPONIBLES enseguida (sin scroll anidado: se desliza con el cuerpo).
	body_vb.add_child(_hdr("DISPONIBLES  ·  toca para añadir"))
	_avail_box = VBoxContainer.new()
	_avail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_avail_box.add_theme_constant_override("separation", 7)
	body_vb.add_child(_avail_box)
	_build_available()

	# 3) AJUSTES DE PARTIDA al final (mapa, modificadores, dificultad CPU).
	var sec_top := _panel_section(body_vb)
	sec_top.add_child(_hdr("AJUSTES DE PARTIDA  ·  MAPA"))
	var map_scroll := ScrollContainer.new()
	map_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	map_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	map_scroll.custom_minimum_size = Vector2(0, 56)
	map_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sec_top.add_child(map_scroll)
	_map_box = HBoxContainer.new()
	_map_box.add_theme_constant_override("separation", 8)
	map_scroll.add_child(_map_box)
	_build_maps()
	_theme_scrollbar(map_scroll.get_h_scroll_bar())
	sec_top.add_child(_hdr("MODIFICADORES  ·  elige hasta 3"))
	_modsel_box = GridContainer.new()
	_modsel_box.columns = 2
	_modsel_box.add_theme_constant_override("h_separation", 8)
	_modsel_box.add_theme_constant_override("v_separation", 6)
	sec_top.add_child(_modsel_box)
	_build_modsel()
	sec_top.add_child(_hdr("DIFICULTAD CPU (vs máquina)"))
	var cpu_row := HBoxContainer.new()
	cpu_row.add_theme_constant_override("separation", 8)
	sec_top.add_child(cpu_row)
	var cpu_names := ["😌 Fácil", "🙂 Media", "😈 Difícil"]
	for lvl in 3:
		var cb := Button.new()
		cb.text = cpu_names[lvl]
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cb.custom_minimum_size = Vector2(0, 44)
		_style_chip(cb, Settings.cpu_level == lvl, UITheme.PRIMARY)
		cb.pressed.connect(func():
			Settings.set_cpu_level(lvl)
			for c in cpu_row.get_children():
				_style_chip(c, false, UITheme.PRIMARY)
			_style_chip(cb, true, UITheme.PRIMARY))
		cpu_row.add_child(cb)
	_theme_scrollbar(body.get_v_scroll_bar())

	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 16)
	root.add_child(nav)
	var back := Button.new()
	back.text = "Menú"
	back.custom_minimum_size = Vector2(140, 58)
	UITheme.button_font(back, 22, UITheme.TEXT2, true, 700)
	UITheme.style_surface(back, UITheme.SURFACE, UITheme.BORDER, 16)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	nav.add_child(back)
	_play_btn = Button.new()
	_play_btn.text = "▶  Jugar"
	_play_btn.custom_minimum_size = Vector2(230, 58)
	UITheme.button_font(_play_btn, 24, Color.WHITE, true, 800)
	UITheme.style_primary(_play_btn, UITheme.PRIMARY, 16)
	_play_btn.pressed.connect(_on_play)
	nav.add_child(_play_btn)

	_refresh()

# ---------------------------------------------------------------- mazos (tarjetas)
## Tira de TARJETAS de mazo: nombre + conteo N/6; la activa lleva ✓ EN USO
## (es el mazo que juega ONLINE y vs CPU). Tocar otra tarjeta la pone EN USO.
func _build_deck_tabs() -> void:
	for c in _deck_row.get_children():
		c.queue_free()
	Loadout.stash_active()
	for i in maxi(1, Loadout.decks.size()):
		var d: Dictionary = Loadout.decks[i] if i < Loadout.decks.size() else {}
		_deck_row.add_child(_deck_card(i, d))
	if Loadout.decks.size() < Loadout.MAX_DECKS:
		var add := Button.new()
		add.custom_minimum_size = Vector2(72, 64)
		UITheme.style_surface(add, Color(0.06, 0.08, 0.15), UITheme.SUCCESS.darkened(0.35), 14)
		var av := VBoxContainer.new()
		av.alignment = BoxContainer.ALIGNMENT_CENTER
		av.set_anchors_preset(Control.PRESET_FULL_RECT)
		av.mouse_filter = Control.MOUSE_FILTER_IGNORE
		av.add_theme_constant_override("separation", 0)
		add.add_child(av)
		var ap := Label.new()
		ap.text = "＋"
		ap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UITheme.label(ap, 20, UITheme.SUCCESS, true, 800)
		av.add_child(ap)
		var al := Label.new()
		al.text = "Nuevo"
		al.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UITheme.label(al, 10, UITheme.SUCCESS, true, 700)
		av.add_child(al)
		add.tooltip_text = "Nuevo mazo (copia del actual)"
		add.pressed.connect(func():
			Loadout.stash_active()
			Loadout.decks.append({"name": "Mazo %d" % (Loadout.decks.size() + 1),
				"team": (Loadout.decks[Loadout.active_deck] as Dictionary).get("team", []).duplicate(),
				"mods": Loadout.player_modifiers.duplicate(), "map": Loadout.map_index})
			_switch_deck(Loadout.decks.size() - 1))
		_deck_row.add_child(add)

## Tarjeta de un mazo: nombre + N/6 + chip "✓ EN USO" si es el activo.
func _deck_card(i: int, d: Dictionary) -> Button:
	var active := i == Loadout.active_deck
	var n: int = (d.get("team", []) as Array).size() if not d.is_empty() else _team.size()
	var full := n >= Loadout.DECK_SIZE
	var b := Button.new()
	b.custom_minimum_size = Vector2(118, 64)
	if active:
		UITheme.style_primary(b, UITheme.PRIMARY, 14)
	else:
		UITheme.style_surface(b, UITheme.SURFACE2, UITheme.BORDER, 14)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 0)
	b.add_child(v)
	var nm := Label.new()
	nm.text = String(d.get("name", "Mazo %d" % (i + 1)))
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.clip_text = true
	UITheme.label(nm, 13, UITheme.TEXT, true, 700)
	v.add_child(nm)
	var st := Label.new()
	st.text = ("✓ EN USO · %d/%d" % [n, Loadout.DECK_SIZE]) if active else ("%d/%d" % [n, Loadout.DECK_SIZE])
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(st, 10, (Color(1, 1, 1, 0.9) if active else (UITheme.SUCCESS if full else UITheme.GOLD)), true, 700)
	v.add_child(st)
	b.pressed.connect(_switch_deck.bind(i))
	return b

## Botón de la fila de acciones del mazo EN USO.
func _action_btn(text: String, col: Color, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 40)
	UITheme.button_font(b, 12, col, true, 700)
	UITheme.style_surface(b, UITheme.SURFACE2, UITheme.BORDER, 10)
	b.pressed.connect(cb)
	return b

## Renombrar el mazo EN USO (modal con campo de texto).
func _rename_deck() -> void:
	var modal := Control.new()
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			modal.queue_free())
	modal.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.add_child(cc)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(380.0, get_viewport().get_visible_rect().size.x - 32.0), 0)
	panel.add_theme_stylebox_override("panel", UITheme.info_popup_box())
	cc.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	var t := Label.new()
	t.text = "✎ Nombre del mazo"
	UITheme.label(t, 16, UITheme.GOLD, true, 800)
	vb.add_child(t)
	var le := LineEdit.new()
	le.text = Loadout.active_name()
	le.max_length = 14
	le.custom_minimum_size = Vector2(0, 44)
	le.add_theme_stylebox_override("normal", UITheme.input())
	le.add_theme_stylebox_override("focus", UITheme.input(UITheme.INPUT_BG, UITheme.PRIMARY))
	le.add_theme_color_override("font_color", UITheme.TEXT)
	vb.add_child(le)
	var okb := Button.new()
	okb.text = "Guardar"
	okb.custom_minimum_size = Vector2(0, 44)
	UITheme.button_font(okb, 14, Color.WHITE, true, 800)
	UITheme.style_primary(okb, UITheme.PRIMARY, 12)
	okb.pressed.connect(func():
		var nm := le.text.strip_edges()
		if nm != "" and not Loadout.decks.is_empty():
			(Loadout.decks[Loadout.active_deck] as Dictionary)["name"] = nm
			Loadout.save()
			_build_deck_tabs()
		modal.queue_free())
	vb.add_child(okb)

## Borrar el mazo EN USO — con confirmación (y SIN pisar el mazo destino: el
## cambio de ranura tras borrar no vuelca el estado del mazo muerto).
func _confirm_delete_deck() -> void:
	if Loadout.decks.size() <= 1:
		_counter.text = "es tu único mazo"
		return
	var modal := Control.new()
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			modal.queue_free())
	modal.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.add_child(cc)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(380.0, get_viewport().get_visible_rect().size.x - 32.0), 0)
	panel.add_theme_stylebox_override("panel", UITheme.panel(UITheme.SURFACE, UITheme.DANGER.darkened(0.2), 18, 2, 16))
	cc.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	var t := Label.new()
	t.text = "🗑 ¿Borrar «%s»?" % Loadout.active_name()
	UITheme.label(t, 16, UITheme.DANGER, true, 800)
	vb.add_child(t)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	vb.add_child(hb)
	var no := Button.new()
	no.text = "Cancelar"
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.custom_minimum_size = Vector2(0, 44)
	UITheme.button_font(no, 14, UITheme.TEXT, true, 700)
	UITheme.style_surface(no)
	no.pressed.connect(func(): modal.queue_free())
	hb.add_child(no)
	var yes := Button.new()
	yes.text = "Borrar"
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes.custom_minimum_size = Vector2(0, 44)
	UITheme.button_font(yes, 14, Color.WHITE, true, 800)
	UITheme.style_primary(yes, UITheme.DANGER, 12)
	yes.pressed.connect(func():
		Loadout.decks.remove_at(Loadout.active_deck)
		Loadout.switch_deck(0, false)   # sin stash: no revivir el mazo borrado
		_after_switch()
		modal.queue_free())
	hb.add_child(yes)

func _switch_deck(i: int) -> void:
	Loadout.switch_deck(i)
	_after_switch()

## Refresca todo el builder tras cambiar/borrar/importar un mazo.
func _after_switch() -> void:
	_team = Loadout.player_team.duplicate()
	_map_index = Loadout.map_index
	_mods = Loadout.player_modifiers.duplicate()
	_build_deck_tabs()
	_build_maps()
	_build_modsel()
	_refresh()

# ---------------------------------------------------------------- posesión
## En modo USUARIO solo puedes alinear figuras que POSEES (pieza model:<id>) o
## tus propias creaciones. Admin alinea todo.
func _owned(d: Dictionary) -> bool:
	if Inventory.is_admin() or bool(d.get("custom", false)):
		return true
	return Inventory.has_piece("model:" + String(d.get("id", "")))

func _team_owned() -> bool:
	for ri in _team:
		if ri >= 0 and ri < Roster.FIGURES.size() and not _owned(Roster.FIGURES[ri]):
			return false
	return true

func _hdr(text: String) -> Label:
	var l := Label.new()
	UITheme.section(l, text)   # azul, MAYÚSCULAS, Manrope 700 (handoff §4.5)
	return l

## Panel contenedor de sección (agrupa visualmente en lugar de flotar todo).
func _panel_section(parent: VBoxContainer) -> VBoxContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.group_panel(18, 13))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 9)
	p.add_child(vb)
	return vb

## Estiliza un botón como CHIP conmutable (handoff §3): mapa/dificultad azul,
## modificadores naranja. Aplica normal/hover/pressed + fuente.
func _style_chip(b: Button, selected: bool, accent := UITheme.PRIMARY) -> void:
	var col: Color = Color(0.14, 0.12, 0.02) if (selected and accent == UITheme.ORANGE) else UITheme.TEXT
	UITheme.button_font(b, 14, col, true, 700)
	b.add_theme_stylebox_override("normal", UITheme.chip(selected, accent))
	b.add_theme_stylebox_override("hover", UITheme.chip(selected, accent.lightened(0.08) if selected else accent))
	b.add_theme_stylebox_override("pressed", UITheme.chip(selected, accent))
	b.add_theme_stylebox_override("disabled", UITheme.chip(false, UITheme.BORDER))

## Barra de scroll visible y tematizada (grabber azulado, riel oscuro, 7px).
func _theme_scrollbar(sb: ScrollBar) -> void:
	if sb == null:
		return
	sb.custom_minimum_size = Vector2(7, 7)
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color(0.2, 0.251, 0.42)   # #33406B
	grab.set_corner_radius_all(99)
	var rail := StyleBoxFlat.new()
	rail.bg_color = Color(0.043, 0.063, 0.141)   # #0B1024
	rail.set_corner_radius_all(99)
	sb.add_theme_stylebox_override("grabber", grab)
	sb.add_theme_stylebox_override("grabber_highlight", grab)
	sb.add_theme_stylebox_override("grabber_pressed", grab)
	sb.add_theme_stylebox_override("scroll", rail)

func _build_maps() -> void:
	for c in _map_box.get_children():
		c.queue_free()
	for i in MapData.count():
		var b := Button.new()
		b.text = MapData.display_name(i)
		b.toggle_mode = true
		b.button_pressed = (i == _map_index)
		b.custom_minimum_size = Vector2(0, 44)
		_style_chip(b, i == _map_index, UITheme.PRIMARY)
		b.pressed.connect(_select_map.bind(i))
		_map_box.add_child(b)

func _select_map(i: int) -> void:
	_map_index = i
	_build_maps()
	_commit()

## Persist the current team + modifiers + map to disk (survives app restarts).
func _commit() -> void:
	Loadout.player_team = _team.duplicate()
	Loadout.map_index = _map_index
	Loadout.player_modifiers = _mods.duplicate()
	Loadout.save()

func _build_modsel() -> void:
	for c in _modsel_box.get_children():
		c.queue_free()
	for mid in GameState.MODIFIERS.keys():
		var m: Dictionary = GameState.MODIFIERS[mid]
		var b := Button.new()
		b.toggle_mode = true
		b.button_pressed = mid in _mods
		b.text = "%s   ⚡%d" % [String(m["name"]), int(m["cost"])]
		b.tooltip_text = String(m["desc"])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 46)
		b.clip_text = true
		_style_chip(b, mid in _mods, UITheme.ORANGE)   # seleccionado naranja (§4)
		b.pressed.connect(_toggle_mod.bind(mid))
		_modsel_box.add_child(b)

func _toggle_mod(mid: String) -> void:
	if mid in _mods:
		_mods.erase(mid)
	elif _mods.size() < 3:
		_mods.append(mid)
	_build_modsel()
	_commit()

func _build_available() -> void:
	for ri in Roster.FIGURES.size():
		var d: Dictionary = Roster.FIGURES[ri]
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 54)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		UITheme.button_font(b, 17, UITheme.TEXT, false, 600)
		UITheme.style_surface(b, UITheme.SURFACE, FigureCard.rarity_color(d), 12)
		var custom_tag := "  · tuya ✎" if bool(d.get("custom", false)) else ""
		b.text = "  %s   ·   %s   ·   ⚡%d%s" % [d["name"], String(d.get("type", "?")), int(d.get("stamina", 1)), custom_tag]
		if not _owned(d):
			b.disabled = true
			b.text = "  🔒" + b.text
			b.tooltip_text = "No posees esta figura — consíguela en 🎁 Cajas"
		b.pressed.connect(_add.bind(ri))
		_avail_box.add_child(b)

func _add(ri: int) -> void:
	if _team.size() >= Loadout.DECK_SIZE:
		return
	_team.append(ri)
	_refresh()

func _remove(slot: int) -> void:
	if slot >= 0 and slot < _team.size():
		_team.remove_at(slot)
		_refresh()

func _refresh() -> void:
	var owned_ok := _team_owned()
	_counter.text = "%d/%d" % [_team.size(), Loadout.DECK_SIZE] + ("" if owned_ok else "  🔒")
	_counter.add_theme_color_override("font_color",
		UITheme.SUCCESS if (Loadout.valid(_team) and owned_ok) else UITheme.GOLD)
	for c in _team_box.get_children():
		c.queue_free()
	for slot in Loadout.DECK_SIZE:
		var b := Button.new()
		b.custom_minimum_size = Vector2(96, 66)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if slot < _team.size():
			var fd: Dictionary = Roster.FIGURES[_team[slot]]
			b.text = String(fd["name"])
			UITheme.button_font(b, 13, UITheme.TEXT, true, 700)
			UITheme.style_surface(b, UITheme.SURFACE2, FigureCard.rarity_color(fd), 12)
			b.pressed.connect(_remove.bind(slot))
		else:
			b.text = "+"
			UITheme.button_font(b, 26, UITheme.MUTED, true, 700)
			UITheme.style_surface(b, Color(0.07, 0.08, 0.13), UITheme.BORDER, 12)
			b.disabled = true
		_team_box.add_child(b)
	_play_btn.disabled = not (Loadout.valid(_team) and _team_owned())
	_commit()
	_build_deck_tabs()   # el conteo N/6 de la tarjeta EN USO cambia en vivo

func _on_play() -> void:
	if not (Loadout.valid(_team) and _team_owned()):
		return
	_commit()
	get_tree().change_scene_to_file("res://scenes/board.tscn")
