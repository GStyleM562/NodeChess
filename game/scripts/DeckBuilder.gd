extends Control
## Deck Builder — pick your team of Loadout.DECK_SIZE figures (duplicates allowed)
## before a match. Writes the choice to Loadout.player_team and starts the board.

var _team: Array = []
var _map_index := 0
var _team_box: HBoxContainer
var _avail_box: VBoxContainer
var _map_box: HBoxContainer
var _counter: Label
var _play_btn: Button

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_team = Loadout.player_team.duplicate()
	_map_index = Loadout.map_index

	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 14
	root.offset_right = -14
	root.offset_top = 16
	root.offset_bottom = -14
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var title := Label.new()
	title.text = "Arma tu equipo"
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	_counter = Label.new()
	_counter.add_theme_font_size_override("font_size", 20)
	_counter.modulate = Color(0.8, 0.85, 1.0)
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_counter)

	var map_hdr := Label.new()
	map_hdr.text = "Mapa:"
	map_hdr.add_theme_font_size_override("font_size", 18)
	root.add_child(map_hdr)
	_map_box = HBoxContainer.new()
	_map_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_map_box.add_theme_constant_override("separation", 8)
	root.add_child(_map_box)
	_build_maps()

	var team_hdr := Label.new()
	team_hdr.text = "Tu equipo (toca para quitar):"
	team_hdr.add_theme_font_size_override("font_size", 18)
	root.add_child(team_hdr)
	_team_box = HBoxContainer.new()
	_team_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_team_box.add_theme_constant_override("separation", 6)
	root.add_child(_team_box)

	var avail_hdr := Label.new()
	avail_hdr.text = "Disponibles (toca para añadir):"
	avail_hdr.add_theme_font_size_override("font_size", 18)
	root.add_child(avail_hdr)
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
	back.custom_minimum_size = Vector2(150, 56)
	back.add_theme_font_size_override("font_size", 24)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	nav.add_child(back)
	_play_btn = Button.new()
	_play_btn.text = "Jugar"
	_play_btn.custom_minimum_size = Vector2(220, 56)
	_play_btn.add_theme_font_size_override("font_size", 26)
	_play_btn.pressed.connect(_on_play)
	nav.add_child(_play_btn)

	_refresh()

func _build_maps() -> void:
	for c in _map_box.get_children():
		c.queue_free()
	for i in MapData.count():
		var b := Button.new()
		b.text = MapData.display_name(i)
		b.toggle_mode = true
		b.button_pressed = (i == _map_index)
		b.custom_minimum_size = Vector2(0, 46)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(_select_map.bind(i))
		_map_box.add_child(b)

func _select_map(i: int) -> void:
	_map_index = i
	_build_maps()

func _build_available() -> void:
	for ri in Roster.FIGURES.size():
		var d: Dictionary = Roster.FIGURES[ri]
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 54)
		b.add_theme_font_size_override("font_size", 20)
		b.text = "%s   ·   %s   ·   ST %d" % [d["name"], String(d.get("type", "?")), int(d.get("stamina", 1))]
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
		b.custom_minimum_size = Vector2(96, 64)
		b.add_theme_font_size_override("font_size", 15)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if slot < _team.size():
			b.text = Roster.FIGURES[_team[slot]]["name"]
			b.pressed.connect(_remove.bind(slot))
		else:
			b.text = "vacío"
			b.disabled = true
		_team_box.add_child(b)
	_play_btn.disabled = not Loadout.valid(_team)

func _on_play() -> void:
	if not Loadout.valid(_team):
		return
	Loadout.player_team = _team.duplicate()
	Loadout.map_index = _map_index
	get_tree().change_scene_to_file("res://scenes/board.tscn")
