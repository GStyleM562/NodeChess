extends CanvasLayer
class_name CombatOverlay
## Combat presentation. Each figure fights with ITS attack type: the attacker rolls
## first (coin / 3D die / two dice / reel), then the defender, then the outcome.
## Visuals are delegated to AttackPresenter (shared with the Attack Tester).
## `await overlay.play(...)` returns when the presentation finishes.

const AREA := Vector2(500, 380)

var _root: Control
var _title: Label
var _matchup: Label
var _roller: Label
var _presenter: AttackPresenter
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
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(AREA.x, 0)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 10)
	center.add_child(vb)

	_title = _mk("¡Combate!", 32, Color(1, 0.9, 0.6))
	vb.add_child(_title)
	_matchup = _mk("", 24, Color(1, 1, 1))
	vb.add_child(_matchup)

	_presenter = AttackPresenter.new()
	_presenter.custom_minimum_size = AREA
	_presenter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(_presenter)

	_roller = _mk("", 22, Color(1, 1, 1))
	vb.add_child(_roller)
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

func play(name_a: String, name_b: String, seg_a: Dictionary, seg_b: Dictionary,
		msg: String, msg_col: Color, pool_a: Array, pool_b: Array,
		col_a: Color = Color(1, 1, 1), col_b: Color = Color(1, 1, 1),
		type_a: String = "Ruleta", type_b: String = "Ruleta",
		fig_a: Dictionary = {}, fig_b: Dictionary = {}) -> void:
	_matchup.text = name_a + "   VS   " + name_b
	_presenter.clear()
	_roller.text = ""
	_root.visible = true

	_title.text = "¡Combate!"
	_result.text = name_a + " inicia combate contra " + name_b
	_result.modulate = Color(1.0, 0.95, 0.7)
	await get_tree().create_timer(1.0).timeout
	_result.text = ""

	_roller.text = "⚔  Ataca: " + name_a
	_roller.modulate = col_a
	await _presenter.present(type_a, pool_a, seg_a, -1, fig_a)

	_roller.text = "🛡  Defiende: " + name_b
	_roller.modulate = col_b
	await _presenter.present(type_b, pool_b, seg_b, -1, fig_b)

	_roller.text = ""
	_result.text = msg
	_result.modulate = msg_col
	await get_tree().create_timer(2.2).timeout

	_root.visible = false
