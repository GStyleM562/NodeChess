extends CanvasLayer
class_name CombatOverlay
## Combat presentation (portrait-friendly): darkens the board and shows both
## figures' attack "wheels" stacked VERTICALLY (so nothing is cut off on a phone),
## announces "X inicia combate contra Y", spins, then reveals the result.
## `await overlay.play(...)` returns when the presentation finishes.

const CONTENT_W := 480   # fits inside the 540-wide portrait viewport with margins

var _root: Control
var _vb: VBoxContainer
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

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for s in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(s, 26)
	_root.add_child(margin)

	var center := CenterContainer.new()
	margin.add_child(center)

	_vb = VBoxContainer.new()
	_vb.custom_minimum_size = Vector2(CONTENT_W, 0)
	_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	_vb.add_theme_constant_override("separation", 12)
	center.add_child(_vb)

	_title = _mk_label("¡Combate!", 32, Color(1, 0.9, 0.6))
	_vb.add_child(_title)

	_name_a = _mk_label("A", 24, Color(0.45, 0.7, 1.0))
	_vb.add_child(_name_a)
	var pa := _mk_wheel()
	_rect_a = pa[0]
	_lbl_a = pa[1]
	_vb.add_child(_center(_rect_a))

	_vb.add_child(_mk_label("VS", 26, Color(1, 1, 1)))

	_name_b = _mk_label("B", 24, Color(1.0, 0.5, 0.45))
	_vb.add_child(_name_b)
	var pb := _mk_wheel()
	_rect_b = pb[0]
	_lbl_b = pb[1]
	_vb.add_child(_center(_rect_b))

	_result = _mk_label("", 22, Color(1, 1, 1))
	_vb.add_child(_result)

func _mk_label(t: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.modulate = col
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(CONTENT_W, 0)
	return l

func _mk_wheel() -> Array:
	var rect := ColorRect.new()
	rect.custom_minimum_size = Vector2(320, 66)
	rect.color = Color(0.2, 0.2, 0.25)
	var l := Label.new()
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 26)
	l.text = "?"
	rect.add_child(l)
	return [rect, l]

func _center(c: Control) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.add_child(c)
	return cc

## Presents the combat. `msg`/`msg_col` describe the outcome; `col_a`/`col_b` color
## the names by team (ally = blue, enemy = red). Returns when finished (caller awaits).
func play(name_a: String, name_b: String, seg_a: Dictionary, seg_b: Dictionary,
		msg: String, msg_col: Color, pool_a: Array, pool_b: Array,
		col_a: Color = Color(1, 1, 1), col_b: Color = Color(1, 1, 1)) -> void:
	_name_a.text = name_a
	_name_a.modulate = col_a
	_name_b.text = name_b
	_name_b.modulate = col_b
	_lbl_a.text = "?"
	_lbl_b.text = "?"
	_rect_a.color = Color(0.2, 0.2, 0.25)
	_rect_b.color = Color(0.2, 0.2, 0.25)
	_root.visible = true

	# Announce
	_title.text = "¡Combate!"
	_result.text = name_a + " inicia combate contra " + name_b
	_result.modulate = Color(1.0, 0.95, 0.7)
	await get_tree().create_timer(1.2).timeout
	_result.text = ""

	# Spin
	var spins := 16
	for i in spins:
		_show_seg(_rect_a, _lbl_a, pool_a[randi() % pool_a.size()])
		_show_seg(_rect_b, _lbl_b, pool_b[randi() % pool_b.size()])
		await get_tree().create_timer(0.07 + i * 0.006).timeout

	# Land
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
