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

	# --- pestañas de MAZOS (hasta 20) + código NCDECK ---
	var deck_scroll := ScrollContainer.new()
	deck_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	deck_scroll.custom_minimum_size = Vector2(0, 46)
	root.add_child(deck_scroll)
	_deck_row = HBoxContainer.new()
	_deck_row.add_theme_constant_override("separation", 6)
	deck_scroll.add_child(_deck_row)
	_build_deck_tabs()

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

	var sec_top := _panel_section(body_vb)
	sec_top.add_child(_hdr("MAPA"))
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

	# DISPONIBLES va DENTRO del cuerpo scrolleable (sin scroll anidado propio),
	# así el deslizamiento vertical llega hasta la última figura y el botón Jugar.
	body_vb.add_child(_hdr("DISPONIBLES  ·  toca para añadir"))
	_avail_box = VBoxContainer.new()
	_avail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_avail_box.add_theme_constant_override("separation", 7)
	body_vb.add_child(_avail_box)
	_build_available()
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

# ---------------------------------------------------------------- mazos (tabs)
func _build_deck_tabs() -> void:
	for c in _deck_row.get_children():
		c.queue_free()
	Loadout.stash_active()
	for i in maxi(1, Loadout.decks.size()):
		var d: Dictionary = Loadout.decks[i] if i < Loadout.decks.size() else {}
		var b := Button.new()
		b.text = String(d.get("name", "Mazo %d" % (i + 1)))
		b.custom_minimum_size = Vector2(0, 40)
		b.toggle_mode = true
		b.button_pressed = i == Loadout.active_deck
		UITheme.button_font(b, 13, UITheme.TEXT, true, 700)
		if i == Loadout.active_deck:
			UITheme.style_primary(b, UITheme.PRIMARY, 10)
		else:
			UITheme.style_surface(b, UITheme.SURFACE2, UITheme.BORDER, 10)
		b.pressed.connect(_switch_deck.bind(i))
		_deck_row.add_child(b)
	if Loadout.decks.size() < Loadout.MAX_DECKS:
		var add := Button.new()
		add.text = "＋"
		add.custom_minimum_size = Vector2(44, 40)
		UITheme.button_font(add, 16, UITheme.SUCCESS, true, 800)
		UITheme.style_surface(add, UITheme.SURFACE2, UITheme.BORDER, 10)
		add.tooltip_text = "Duplicar el mazo actual"
		add.pressed.connect(func():
			Loadout.stash_active()
			Loadout.decks.append({"name": "Mazo %d" % (Loadout.decks.size() + 1),
				"team": (Loadout.decks[Loadout.active_deck] as Dictionary).get("team", []).duplicate(),
				"mods": Loadout.player_modifiers.duplicate(), "map": Loadout.map_index})
			_switch_deck(Loadout.decks.size() - 1))
		_deck_row.add_child(add)
	if Loadout.decks.size() > 1:
		var del := Button.new()
		del.text = "🗑"
		del.custom_minimum_size = Vector2(44, 40)
		UITheme.button_font(del, 14, UITheme.DANGER, true, 700)
		UITheme.style_surface(del, UITheme.SURFACE2, UITheme.BORDER, 10)
		del.tooltip_text = "Borrar este mazo"
		del.pressed.connect(func():
			Loadout.decks.remove_at(Loadout.active_deck)
			Loadout.active_deck = 0
			_switch_deck(0))
		_deck_row.add_child(del)
	var share := Button.new()
	share.text = "⧉"
	share.custom_minimum_size = Vector2(44, 40)
	UITheme.button_font(share, 14, UITheme.GOLD, true, 700)
	UITheme.style_surface(share, UITheme.SURFACE2, UITheme.BORDER, 10)
	share.tooltip_text = "Copiar código del mazo"
	share.pressed.connect(func():
		DisplayServer.clipboard_set(Loadout.deck_code())
		_counter.text = "⧉ código copiado")
	_deck_row.add_child(share)
	var imp := Button.new()
	imp.text = "⇪"
	imp.custom_minimum_size = Vector2(44, 40)
	UITheme.button_font(imp, 14, UITheme.PRIMARY_EDGE, true, 700)
	UITheme.style_surface(imp, UITheme.SURFACE2, UITheme.BORDER, 10)
	imp.tooltip_text = "Importar mazo desde el portapapeles (código NCDECK1)"
	imp.pressed.connect(func():
		var r: Dictionary = Loadout.import_deck_code(DisplayServer.clipboard_get())
		if bool(r["ok"]):
			_switch_deck(Loadout.decks.size() - 1)
		else:
			_counter.text = "✗ código inválido")
	_deck_row.add_child(imp)

func _switch_deck(i: int) -> void:
	Loadout.switch_deck(i)
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

func _on_play() -> void:
	if not (Loadout.valid(_team) and _team_owned()):
		return
	_commit()
	get_tree().change_scene_to_file("res://scenes/board.tscn")
