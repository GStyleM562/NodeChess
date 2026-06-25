extends Control
## Attack Tester — activate a single figure's attack to test its presentation per
## TYPE: Moneda (coin flip), Dado (die roll), Suma 2d6 (two dice), Ruleta (slot
## machine reel). Uses each figure's REAL attack pool, so you verify the visuals
## and the outcomes match the figure.

var _index := 0
var _stage: Control
var _name_label: Label
var _type_label: Label
var _result_label: Label
var _launch_btn: Button
var _busy := false

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var top := VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = 16
	top.offset_left = 12
	top.offset_right = -12
	add_child(top)
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 30)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(_name_label)
	_type_label = Label.new()
	_type_label.add_theme_font_size_override("font_size", 22)
	_type_label.modulate = Color(0.8, 0.85, 1.0)
	_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(_type_label)

	_stage = Control.new()
	_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.offset_top = 120
	_stage.offset_bottom = -210
	add_child(_stage)

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
	_result_label.add_theme_font_size_override("font_size", 24)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom.add_child(_result_label)

	_launch_btn = Button.new()
	_launch_btn.text = "Lanzar ataque"
	_launch_btn.custom_minimum_size = Vector2(300, 64)
	_launch_btn.add_theme_font_size_override("font_size", 28)
	_launch_btn.pressed.connect(_on_launch)
	bottom.add_child(_center(_launch_btn))

	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 16)
	var prev := Button.new()
	prev.text = "◀"
	prev.custom_minimum_size = Vector2(70, 46)
	prev.pressed.connect(func(): _switch(-1))
	nav.add_child(prev)
	var menu := Button.new()
	menu.text = "Menú"
	menu.custom_minimum_size = Vector2(130, 46)
	menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	nav.add_child(menu)
	var nxt := Button.new()
	nxt.text = "▶"
	nxt.custom_minimum_size = Vector2(70, 46)
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
	_clear_stage()

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
	var result: Dictionary = Combat.roll(d["attack"])
	await _present(String(d.get("type", "")), d["attack"], result)
	var extra := "   [" + String(result["fx"]) + "]" if result.has("fx") else ""
	_result_label.text = "Resultado: " + Combat.label(result) + extra
	_result_label.modulate = Combat.color_of(result).lightened(0.2)
	_busy = false
	_launch_btn.disabled = false

func _present(type: String, pool: Array, result: Dictionary) -> void:
	_clear_stage()
	match type:
		"Moneda":
			await _coin(pool, result)
		"Dado (D6)":
			await _die(pool, result)
		"Suma 2d6":
			await _dice2(pool, result)
		_:
			await _reel(pool, result)

func _clear_stage() -> void:
	for c in _stage.get_children():
		c.queue_free()

# --------------------------------------------------------------- shapes
func _mk_shape(seg: Dictionary, size: int, circle: bool) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(size, size)
	p.size = Vector2(size, size)
	var lbl := Label.new()
	lbl.name = "lbl"
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.offset_left = 10
	lbl.offset_right = -10
	lbl.offset_top = 6
	lbl.offset_bottom = -6
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 21)
	p.add_child(lbl)
	_set_shape(p, seg, circle)
	return p

func _set_shape(p: Panel, seg: Dictionary, circle: bool) -> void:
	var col := Combat.color_of(seg)
	var sb := StyleBoxFlat.new()
	sb.bg_color = col.darkened(0.3)
	var r := int(p.custom_minimum_size.x * 0.5) if circle else 16
	sb.corner_radius_top_left = r
	sb.corner_radius_top_right = r
	sb.corner_radius_bottom_left = r
	sb.corner_radius_bottom_right = r
	sb.border_width_left = 4
	sb.border_width_right = 4
	sb.border_width_top = 4
	sb.border_width_bottom = 4
	sb.border_color = col.lightened(0.4)
	p.add_theme_stylebox_override("panel", sb)
	var lbl := p.get_node_or_null("lbl")
	if lbl:
		(lbl as Label).text = Combat.label(seg)
		(lbl as Label).modulate = col.lightened(0.45)

# --------------------------------------------------------------- coin
## A real coin toss: the coin RISES in an arc and falls back down, flipping the
## whole time. It has TWO faces (heads/tails = the two main attacks); you see both
## alternate while it spins, and it lands on the rolled result.
func _coin(pool: Array, result: Dictionary) -> void:
	var faces := _two_faces(pool)
	var coin := _mk_shape(faces[0], 180, true)
	_stage.add_child(coin)
	await get_tree().process_frame
	coin.pivot_offset = coin.size * 0.5
	var base := _stage.size * 0.5 - coin.size * 0.5
	coin.position = base
	var arc := 190.0
	var n := 12
	for i in n:
		var phase := float(i + 1) / float(n)
		var y := base.y - arc * sin(PI * phase)        # up then back down
		var face: Dictionary = result if i == n - 1 else faces[i % 2]
		var t1 := create_tween().set_parallel(true)
		t1.tween_property(coin, "scale:y", 0.07, 0.06)
		t1.tween_property(coin, "position:y", (coin.position.y + y) * 0.5, 0.06)
		await t1.finished
		_set_shape(coin, face, true)
		var t2 := create_tween().set_parallel(true)
		t2.tween_property(coin, "scale:y", 1.0, 0.06)
		t2.tween_property(coin, "position:y", y, 0.06)
		await t2.finished
	var land := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	land.tween_property(coin, "position:y", base.y, 0.3)
	await land.finished

## The two highest-weight segments = the coin's two faces (heads / tails).
func _two_faces(pool: Array) -> Array:
	var s := pool.duplicate()
	s.sort_custom(func(a, b): return float(a.get("w", 1.0)) > float(b.get("w", 1.0)))
	if s.size() >= 2:
		return [s[0], s[1]]
	return [s[0], s[0]]

# --------------------------------------------------------------- die
func _die(pool: Array, result: Dictionary) -> void:
	# Large enough to show the whole die (and a wrapped attack name) on screen.
	var die := _mk_shape(result, 220, false)
	die.set_anchors_preset(Control.PRESET_CENTER)
	_stage.add_child(die)
	await get_tree().process_frame
	die.pivot_offset = die.size * 0.5
	for i in 11:
		_set_shape(die, pool[randi() % pool.size()], false)
		var tw := create_tween()
		tw.tween_property(die, "rotation", randf_range(-0.16, 0.16), 0.06)
		await tw.finished
	_set_shape(die, result, false)
	var land := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	land.tween_property(die, "rotation", 0.0, 0.28)
	await land.finished

# --------------------------------------------------------------- two dice
func _dice2(pool: Array, result: Dictionary) -> void:
	var hb := HBoxContainer.new()
	hb.set_anchors_preset(Control.PRESET_CENTER)
	hb.add_theme_constant_override("separation", 26)
	_stage.add_child(hb)
	var d1 := _mk_shape(result, 140, false)
	var d2 := _mk_shape(result, 140, false)
	hb.add_child(d1)
	hb.add_child(d2)
	await get_tree().process_frame
	d1.pivot_offset = d1.size * 0.5
	d2.pivot_offset = d2.size * 0.5
	for i in 11:
		_set_shape(d1, pool[randi() % pool.size()], false)
		_set_shape(d2, pool[randi() % pool.size()], false)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(d1, "rotation", randf_range(-0.16, 0.16), 0.06)
		tw.tween_property(d2, "rotation", randf_range(-0.16, 0.16), 0.06)
		await tw.finished
	_set_shape(d1, result, false)
	_set_shape(d2, result, false)
	var land := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	land.tween_property(d1, "rotation", 0.0, 0.28)
	land.tween_property(d2, "rotation", 0.0, 0.28)
	await land.finished

# --------------------------------------------------------------- slot reel
func _reel(pool: Array, result: Dictionary) -> void:
	var cell := 60
	var win := Control.new()
	win.custom_minimum_size = Vector2(360, 120)
	win.size = Vector2(360, 120)
	win.set_anchors_preset(Control.PRESET_CENTER)
	win.clip_contents = true
	_stage.add_child(win)
	var back := ColorRect.new()
	back.color = Color(0.08, 0.08, 0.11)
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	win.add_child(back)
	var strip := Control.new()
	win.add_child(strip)
	var line := ColorRect.new()
	line.color = Color(1, 1, 1, 0.10)
	line.position = Vector2(0, 120 * 0.5 - cell * 0.5)
	line.size = Vector2(360, cell)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win.add_child(line)
	var n := 22
	var ridx := 19
	for i in n:
		var seg: Dictionary = result if i == ridx else pool[randi() % pool.size()]
		strip.add_child(_mk_cell(seg, i * cell, 360))
	var center_y := 120 * 0.5 - cell * 0.5
	strip.position.y = center_y
	var final_y := center_y - ridx * cell
	var tw := create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_property(strip, "position:y", final_y, 1.7)
	await tw.finished

func _mk_cell(seg: Dictionary, y: float, width: int) -> Control:
	var cell := Control.new()
	cell.position = Vector2(0, y)
	cell.size = Vector2(width, 60)
	var col := Combat.color_of(seg)
	var rect := ColorRect.new()
	rect.color = col.darkened(0.35)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.offset_top = 3
	rect.offset_bottom = -3
	cell.add_child(rect)
	var lbl := Label.new()
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.text = Combat.label(seg)
	lbl.modulate = col.lightened(0.35)
	cell.add_child(lbl)
	return cell
