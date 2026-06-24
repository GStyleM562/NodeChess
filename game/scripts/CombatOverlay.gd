extends CanvasLayer
class_name CombatOverlay
## Combat presentation — CASINO SLOT MACHINE style (portrait friendly).
## Each attacker gets ONE full-width reel (a row). The attack segments scroll
## vertically (you see the one above/below) and the reel "lands" complete on the
## rolled result. Attacker reel on top, defender below. Then the outcome text.
## `await overlay.play(...)` returns when the presentation finishes.

const CONTENT_W := 480
const CELL_H := 60
const REEL_H := 120          # window shows the centered result + neighbours (above/below)
const STRIP_N := 24          # cells per spin
const RESULT_IDX := 20       # result lands here (a couple cells below for the bottom peek)

var _root: Control
var _vb: VBoxContainer
var _title: Label
var _name_a: Label
var _name_b: Label
var _strip_a: Control
var _strip_b: Control
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
	bg.color = Color(0, 0, 0, 0.82)
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
	_vb.add_theme_constant_override("separation", 10)
	center.add_child(_vb)

	_title = _mk_label("¡Combate!", 32, Color(1, 0.9, 0.6))
	_vb.add_child(_title)

	_name_a = _mk_label("A", 24, Color(0.45, 0.7, 1.0))
	_vb.add_child(_name_a)
	_strip_a = _add_reel()

	_vb.add_child(_mk_label("VS", 26, Color(1, 1, 1)))

	_name_b = _mk_label("B", 24, Color(1.0, 0.5, 0.45))
	_vb.add_child(_name_b)
	_strip_b = _add_reel()

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

## Builds one reel window and returns its inner scrolling strip.
func _add_reel() -> Control:
	var win := Control.new()
	win.custom_minimum_size = Vector2(CONTENT_W, REEL_H)
	win.clip_contents = true
	_vb.add_child(win)

	var back := ColorRect.new()
	back.color = Color(0.08, 0.08, 0.11)
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	win.add_child(back)

	var strip := Control.new()
	win.add_child(strip)

	# payline highlight (center band) on top
	var line := ColorRect.new()
	line.color = Color(1, 1, 1, 0.10)
	line.position = Vector2(0, REEL_H * 0.5 - CELL_H * 0.5)
	line.size = Vector2(CONTENT_W, CELL_H)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win.add_child(line)
	return strip

func _mk_cell(seg: Dictionary, y: float) -> Control:
	var cell := Control.new()
	cell.position = Vector2(0, y)
	cell.size = Vector2(CONTENT_W, CELL_H)
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
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.text = Combat.label(seg)
	lbl.modulate = col.lightened(0.35)
	cell.add_child(lbl)
	return cell

## Builds the reel cells and returns a running tween that lands the result centered.
func _start_reel(strip: Control, pool: Array, result_seg: Dictionary, dur: float) -> Tween:
	for c in strip.get_children():
		c.queue_free()
	for i in STRIP_N:
		var seg: Dictionary = result_seg if i == RESULT_IDX else pool[randi() % pool.size()]
		strip.add_child(_mk_cell(seg, i * CELL_H))
	var center_y := REEL_H * 0.5 - CELL_H * 0.5
	strip.position.y = center_y                                   # index 0 centered
	var final_y := center_y - RESULT_IDX * CELL_H                 # index RESULT_IDX centered
	var tw := create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_property(strip, "position:y", final_y, dur)
	return tw

## Presents the combat. col_a/col_b color the names by team (ally=blue, enemy=red).
func play(name_a: String, name_b: String, seg_a: Dictionary, seg_b: Dictionary,
		msg: String, msg_col: Color, pool_a: Array, pool_b: Array,
		col_a: Color = Color(1, 1, 1), col_b: Color = Color(1, 1, 1)) -> void:
	_name_a.text = name_a
	_name_a.modulate = col_a
	_name_b.text = name_b
	_name_b.modulate = col_b
	for c in _strip_a.get_children():
		c.queue_free()
	for c in _strip_b.get_children():
		c.queue_free()
	_root.visible = true

	# Announce
	_title.text = "¡Combate!"
	_result.text = name_a + " inicia combate contra " + name_b
	_result.modulate = Color(1.0, 0.95, 0.7)
	await get_tree().create_timer(1.2).timeout
	_result.text = ""

	# Spin both reels (defender lands a touch later for drama).
	var ta := _start_reel(_strip_a, pool_a, seg_a, 1.7)
	var tb := _start_reel(_strip_b, pool_b, seg_b, 2.1)
	await ta.finished
	await tb.finished
	await get_tree().create_timer(0.5).timeout

	# Result
	_result.text = msg
	_result.modulate = msg_col
	await get_tree().create_timer(2.2).timeout

	_root.visible = false
