extends CanvasLayer
class_name CombatOverlay
## Combat presentation — SIMULTANEOUS. Both figures roll with THEIR attack type at
## the SAME time (attacker on top, defender on the bottom), then the outcome (who
## won) is shown once both have landed. Visuals are delegated to two AttackPresenters.
## `await overlay.play(...)` returns when the presentation finishes.

const AREA := Vector2(500, 268)

var _root: Control
var _title: Label
var _card_a: CenterContainer
var _card_b: CenterContainer
var _presA: AttackPresenter
var _presB: AttackPresenter
var _result: Label
var _pa_done := false
var _pb_done := false

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
	bg.color = Color(0, 0, 0, 0.86)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(AREA.x, 0)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 6)
	center.add_child(vb)

	_title = _mk("¡Combate!", 30, Color(1, 0.9, 0.6))
	vb.add_child(_title)

	_card_a = CenterContainer.new()
	_card_a.custom_minimum_size = Vector2(AREA.x, 66)
	vb.add_child(_card_a)
	_presA = AttackPresenter.new()
	_presA.custom_minimum_size = AREA
	_presA.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(_presA)

	vb.add_child(_mk("— VS —", 22, Color(1, 1, 1)))

	_card_b = CenterContainer.new()
	_card_b.custom_minimum_size = Vector2(AREA.x, 66)
	vb.add_child(_card_b)
	_presB = AttackPresenter.new()
	_presB.custom_minimum_size = AREA
	_presB.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(_presB)

	_result = _mk("", 24, Color(1, 1, 1))
	vb.add_child(_result)

func _mk(t: String, sz: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", sz)
	l.modulate = col
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(AREA.x, 0)
	return l

func _build_card(slot: CenterContainer, fig: Dictionary, fallback: String, col: Color) -> void:
	for c in slot.get_children():
		c.queue_free()
	if fig.is_empty():
		slot.add_child(_mk(fallback, 20, col))
		return
	var card := FigureCard.new()
	slot.add_child(card)
	card.setup(fig, 0, col, true)

func _on_pa() -> void:
	_pa_done = true

func _on_pb() -> void:
	_pb_done = true

func play(name_a: String, name_b: String, seg_a: Dictionary, seg_b: Dictionary,
		msg: String, msg_col: Color, pool_a: Array, pool_b: Array,
		col_a: Color = Color(1, 1, 1), col_b: Color = Color(1, 1, 1),
		type_a: String = "Ruleta", type_b: String = "Ruleta",
		fig_a: Dictionary = {}, fig_b: Dictionary = {},
		idx_a: int = -1, idx_b: int = -1) -> void:
	_build_card(_card_a, fig_a, "⚔  " + name_a, col_a)
	_build_card(_card_b, fig_b, "🛡  " + name_b, col_b)
	_presA.clear()
	_presB.clear()
	_root.visible = true

	_title.text = "¡Combate!"
	_result.text = name_a + "  vs  " + name_b
	_result.modulate = Color(1.0, 0.95, 0.7)
	await get_tree().create_timer(0.8).timeout

	# Both presentations run AT THE SAME TIME; wait until both have landed.
	_pa_done = false
	_pb_done = false
	_presA.done.connect(_on_pa, CONNECT_ONE_SHOT)
	_presB.done.connect(_on_pb, CONNECT_ONE_SHOT)
	_presA.present(type_a, pool_a, seg_a, idx_a, fig_a)
	_presB.present(type_b, pool_b, seg_b, idx_b, fig_b)
	while not (_pa_done and _pb_done):
		await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout

	# Outcome (who won), shown with both results already on screen.
	_result.text = msg
	_result.modulate = msg_col
	await get_tree().create_timer(2.2).timeout

	_root.visible = false
