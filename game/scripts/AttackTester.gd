extends Control
## Attack Tester — pick a figure and trigger ONLY its attack to test the per-type
## presentation (coin / 3D die / two 3D dice / slot reel). The actual visuals live
## in AttackPresenter (shared with the combat overlay).

var _index := 0
var _presenter: AttackPresenter
var _name_label: Label
var _type_label: Label
var _result_label: Label
var _launch_btn: Button
var _busy := false

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UITheme.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var top := VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = 16
	top.offset_left = 12
	top.offset_right = -12
	add_child(top)
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(_name_label, 28, UITheme.TEXT, true, 800)
	top.add_child(_name_label)
	_type_label = Label.new()
	_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(_type_label, 20, UITheme.PRIMARY_EDGE, true, 600)
	top.add_child(_type_label)

	_presenter = AttackPresenter.new()
	_presenter.set_anchors_preset(Control.PRESET_FULL_RECT)
	_presenter.offset_top = 120
	_presenter.offset_bottom = -210
	add_child(_presenter)

	var bottom := VBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -200
	bottom.offset_bottom = -12
	bottom.offset_left = 12
	bottom.offset_right = -12
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_theme_constant_override("separation", 12)
	add_child(bottom)

	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.label(_result_label, 22, UITheme.TEXT, true, 700)
	bottom.add_child(_result_label)

	_launch_btn = Button.new()
	_launch_btn.text = "🎲  Lanzar ataque"
	_launch_btn.custom_minimum_size = Vector2(300, 66)
	UITheme.button_font(_launch_btn, 26, Color.WHITE, true, 800)
	UITheme.style_primary(_launch_btn, UITheme.PRIMARY, 16)
	_launch_btn.pressed.connect(_on_launch)
	bottom.add_child(_center(_launch_btn))

	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 16)
	var prev := Button.new()
	prev.text = "◀"
	prev.custom_minimum_size = Vector2(64, 48)
	UITheme.button_font(prev, 20, UITheme.TEXT, true, 700)
	UITheme.style_surface(prev, UITheme.SURFACE, UITheme.BORDER, 12)
	prev.pressed.connect(func(): _switch(-1))
	nav.add_child(prev)
	var menu := Button.new()
	menu.text = "Menú"
	menu.custom_minimum_size = Vector2(140, 48)
	UITheme.button_font(menu, 20, UITheme.TEXT2, true, 700)
	UITheme.style_surface(menu, UITheme.SURFACE, UITheme.BORDER, 12)
	menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	nav.add_child(menu)
	var nxt := Button.new()
	nxt.text = "▶"
	nxt.custom_minimum_size = Vector2(64, 48)
	UITheme.button_font(nxt, 20, UITheme.TEXT, true, 700)
	UITheme.style_surface(nxt, UITheme.SURFACE, UITheme.BORDER, 12)
	nxt.pressed.connect(func(): _switch(1))
	nav.add_child(nxt)
	bottom.add_child(nav)

	_refresh()

func _center(c: Control) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.add_child(c)
	return cc

func _refresh() -> void:
	var d: Dictionary = Roster.FIGURES[_index]
	_name_label.text = "%d/%d   %s" % [_index + 1, Roster.FIGURES.size(), d["name"]]
	_type_label.text = "Tipo de ataque: " + String(d.get("type", "?"))
	_result_label.text = "Toca «Lanzar ataque»"
	_result_label.modulate = Color(0.8, 0.8, 0.9)
	_presenter.clear()

func _switch(dir: int) -> void:
	if _busy:
		return
	_index = wrapi(_index + dir, 0, Roster.FIGURES.size())
	_refresh()

func _on_launch() -> void:
	if _busy:
		return
	_busy = true
	_launch_btn.disabled = true
	_result_label.text = "…"
	var d: Dictionary = Roster.FIGURES[_index]
	var idx := _roll_index(d["attack"])
	var result: Dictionary = d["attack"][idx]
	await _presenter.present(String(d.get("type", "")), d["attack"], result, idx, d)
	var extra := "   [" + String(result["fx"]) + "]" if result.has("fx") else ""
	_result_label.text = "Resultado: " + Combat.label(result) + extra
	_result_label.modulate = Combat.color_of(result).lightened(0.2)
	_busy = false
	_launch_btn.disabled = false

func _roll_index(pool: Array) -> int:
	var total := 0.0
	for s in pool:
		total += float(s.get("w", 1.0))
	var pick := randf() * total
	for i in pool.size():
		pick -= float(pool[i].get("w", 1.0))
		if pick <= 0.0:
			return i
	return pool.size() - 1
