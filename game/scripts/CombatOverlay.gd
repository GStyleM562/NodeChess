extends CanvasLayer
class_name CombatOverlay
## Combat presentation: darkens the board, shows both figures' attack "wheels"
## spinning, lands them on the rolled segments, then reveals the result.
## `await overlay.play(...)` returns when the presentation finishes.

var _root: Control
var _bg: ColorRect
var _title: Label
var _name_a: Label
var _name_b: Label
var _rect_a: ColorRect
var _rect_b: ColorRect
var _lbl_a: Label
var _lbl_b: Label
var _result: Label

func _ready() -> void:
	layer = 10
	_build()
	_root.visible = false

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 0.72)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 18)
	center.add_child(vb)

	_title = _mk_label("¡COMBATE!", 30, Color(1, 0.9, 0.6))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_title)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 26)
	vb.add_child(row)

	var col_a := VBoxContainer.new()
	col_a.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(col_a)
	_name_a = _mk_label("A", 20, Color(0.7, 0.85, 1.0))
	_name_a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col_a.add_child(_name_a)
	var pair_a := _mk_wheel()
	_rect_a = pair_a[0]
	_lbl_a = pair_a[1]
	col_a.add_child(_rect_a)

	row.add_child(_mk_label("VS", 24, Color(1, 1, 1)))

	var col_b := VBoxContainer.new()
	col_b.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(col_b)
	_name_b = _mk_label("B", 20, Color(1.0, 0.7, 0.65))
	_name_b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col_b.add_child(_name_b)
	var pair_b := _mk_wheel()
	_rect_b = pair_b[0]
	_lbl_b = pair_b[1]
	col_b.add_child(_rect_b)

	_result = _mk_label("", 26, Color(1, 1, 1))
	_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_result)

func _mk_label(t: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.modulate = col
	return l

func _mk_wheel() -> Array:
	var rect := ColorRect.new()
	rect.custom_minimum_size = Vector2(170, 110)
	rect.color = Color(0.2, 0.2, 0.25)
	var l := Label.new()
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 22)
	l.text = "?"
	rect.add_child(l)
	return [rect, l]

## Presents the combat. `msg`/`msg_col` describe the outcome (built by the view,
## since winning is not always a KO). Returns when finished (caller `await`s).
func play(name_a: String, name_b: String, seg_a: Dictionary, seg_b: Dictionary,
		msg: String, msg_col: Color, pool_a: Array, pool_b: Array) -> void:
	_name_a.text = name_a
	_name_b.text = name_b
	_result.text = ""
	_root.visible = true

	# Spin: flicker through random segments (slower, so options are readable).
	var spins := 16
	for i in spins:
		_show_seg(_rect_a, _lbl_a, pool_a[randi() % pool_a.size()])
		_show_seg(_rect_b, _lbl_b, pool_b[randi() % pool_b.size()])
		# Ease out: each flicker a touch slower than the last.
		await get_tree().create_timer(0.07 + i * 0.006).timeout

	# Land on the real results.
	_show_seg(_rect_a, _lbl_a, seg_a)
	_show_seg(_rect_b, _lbl_b, seg_b)
	await get_tree().create_timer(0.7).timeout

	_result.text = msg
	_result.modulate = msg_col
	await get_tree().create_timer(2.2).timeout

	_root.visible = false

func _show_seg(rect: ColorRect, lbl: Label, seg: Dictionary) -> void:
	var c := Combat.color_of(seg)
	rect.color = c.darkened(0.35)
	lbl.text = Combat.label(seg)
	lbl.modulate = c
