extends Control
## Simple main menu: Jugar (play the board) and Dex (figure library).

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 26)
	center.add_child(vb)

	var title := Label.new()
	title.text = "NodeChess"
	title.add_theme_font_size_override("font_size", 56)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	var sub := Label.new()
	sub.text = "MVP — prototipo"
	sub.add_theme_font_size_override("font_size", 20)
	sub.modulate = Color(0.7, 0.75, 0.9)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)

	vb.add_child(_spacer(20))
	vb.add_child(_menu_button("Jugar", func(): get_tree().change_scene_to_file("res://scenes/board.tscn")))
	vb.add_child(_menu_button("Dex", func(): get_tree().change_scene_to_file("res://scenes/dex.tscn")))
	vb.add_child(_menu_button("Probar ataques", func(): get_tree().change_scene_to_file("res://scenes/attack_tester.tscn")))

func _menu_button(text: String, cb: Callable) -> CenterContainer:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(300, 78)
	b.add_theme_font_size_override("font_size", 32)
	b.pressed.connect(cb)
	var cc := CenterContainer.new()
	cc.add_child(b)
	return cc

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
