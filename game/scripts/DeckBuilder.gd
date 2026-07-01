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
	root.offset_top = 16
	root.offset_bottom = -14
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var title := Label.new()
	title.text = "Arma tu equipo"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(title, 30, UITheme.TEXT, true, 800)
	root.add_child(title)

	_counter = Label.new()
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(_counter, 18, UITheme.SUCCESS, true, 700)
	root.add_child(_counter)

	var map_hdr := _hdr("MAPA")
	root.add_child(map_hdr)
	_map_box = HBoxContainer.new()
	_map_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_map_box.add_theme_constant_override("separation", 8)
	root.add_child(_map_box)
	_build_maps()

	root.add_child(_hdr("MODIFICADORES  ·  elige hasta 3"))
	_modsel_box = GridContainer.new()
	_modsel_box.columns = 2
	_modsel_box.add_theme_constant_override("h_separation", 8)
	_modsel_box.add_theme_constant_override("v_separation", 6)
	root.add_child(_modsel_box)
	_build_modsel()

	root.add_child(_hdr("TU EQUIPO  ·  toca para quitar"))
	_team_box = HBoxContainer.new()
	_team_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_team_box.add_theme_constant_override("separation", 6)
	root.add_child(_team_box)

	root.add_child(_hdr("DISPONIBLES  ·  toca para añadir"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_avail_box = VBoxContainer.new()
	_avail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_avail_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_avail_box)
	_build_available()

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

func _hdr(text: String) -> Label:
	var l := Label.new()
	l.text = text
	UITheme.label(l, 14, UITheme.MUTED, true, 700)
	return l

func _build_maps() -> void:
	for c in _map_box.get_children():
		c.queue_free()
	for i in MapData.count():
		var b := Button.new()
		b.text = MapData.display_name(i)
		b.toggle_mode = true
		b.button_pressed = (i == _map_index)
		b.custom_minimum_size = Vector2(0, 46)
		UITheme.button_font(b, 16, UITheme.TEXT, true, 700)
		if i == _map_index:
			UITheme.style_primary(b, UITheme.PRIMARY, 12)
		else:
			UITheme.style_surface(b, UITheme.SURFACE, UITheme.BORDER, 12)
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
		b.custom_minimum_size = Vector2(244, 46)
		UITheme.button_font(b, 15, UITheme.TEXT, true, 700)
		if mid in _mods:
			UITheme.style_primary(b, UITheme.ORANGE, 12)
		else:
			UITheme.style_surface(b, UITheme.SURFACE, UITheme.BORDER, 12)
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
		b.custom_minimum_size = Vector2(0, 52)
		UITheme.button_font(b, 18, UITheme.TEXT, false, 600)
		UITheme.style_surface(b, UITheme.SURFACE, FigureCard.rarity_color(d), 12)
		b.text = "%s   ·   %s   ·   ⚡%d" % [d["name"], String(d.get("type", "?")), int(d.get("stamina", 1))]
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
	_counter.text = "%d / %d figuras" % [_team.size(), Loadout.DECK_SIZE]
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
	_play_btn.disabled = not Loadout.valid(_team)
	_commit()

func _on_play() -> void:
	if not Loadout.valid(_team):
		return
	_commit()
	get_tree().change_scene_to_file("res://scenes/board.tscn")
