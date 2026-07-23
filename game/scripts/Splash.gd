extends Control
## Pantalla de BIENVENIDA / carga (escena inicial). Aparece justo tras arrancar
## (el logo de Godot está desactivado) con una animación corta y branding del
## juego, y luego pasa al menú. Es breve — solo da la sensación de "inicio".

const NAVY := Color(0.055, 0.067, 0.114)
const NAVY2 := Color(0.14, 0.18, 0.33)
const GOLD := Color(1.0, 0.773, 0.239)
const BLUE := Color(0.353, 0.627, 1.0)

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var vw := get_viewport().get_visible_rect().size

	# fondo navy con degradado radial suave
	var bg := ColorRect.new()
	bg.color = NAVY
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var glow := TextureRect.new()
	var gg := Gradient.new()
	gg.set_color(0, Color(NAVY2.r, NAVY2.g, NAVY2.b, 0.9))
	gg.add_point(0.7, Color(NAVY2.r, NAVY2.g, NAVY2.b, 0.0))
	gg.set_color(1, Color(NAVY2.r, NAVY2.g, NAVY2.b, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = gg
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 1.0)
	glow.texture = gt
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(glow)

	# emblema: el icono del juego (red de nodos) escalando/latiendo
	var emblem := TextureRect.new()
	if ResourceLoader.exists("res://icon.svg"):
		emblem.texture = load("res://icon.svg")
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.custom_minimum_size = Vector2(160, 160)
	emblem.size = Vector2(160, 160)
	emblem.position = Vector2(vw.x * 0.5 - 80, vw.y * 0.5 - 150)
	emblem.pivot_offset = Vector2(80, 80)
	emblem.scale = Vector2(0.6, 0.6)
	emblem.modulate.a = 0.0
	add_child(emblem)

	# título
	var title := Label.new()
	title.text = "NodeChess"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = vw.y * 0.5 + 30
	_font(title, 40, GOLD, true, 800)
	title.modulate.a = 0.0
	add_child(title)

	var sub := Label.new()
	sub.text = "Tablero táctico"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.set_anchors_preset(Control.PRESET_TOP_WIDE)
	sub.offset_top = vw.y * 0.5 + 84
	_font(sub, 15, Color(0.66, 0.70, 0.82), false, 600)
	sub.modulate.a = 0.0
	add_child(sub)

	# barra de carga fina
	var barbg := Panel.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(1, 1, 1, 0.10)
	bs.set_corner_radius_all(4)
	barbg.add_theme_stylebox_override("panel", bs)
	barbg.set_anchors_preset(Control.PRESET_TOP_WIDE)
	barbg.offset_left = vw.x * 0.5 - 110
	barbg.offset_right = -(vw.x * 0.5 - 110)
	barbg.offset_top = vw.y * 0.5 + 130
	barbg.offset_bottom = vw.y * 0.5 + 138
	add_child(barbg)
	var fill := Panel.new()
	var fs := StyleBoxFlat.new()
	fs.bg_color = BLUE
	fs.set_corner_radius_all(4)
	fill.add_theme_stylebox_override("panel", fs)
	fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	fill.anchor_right = 0.0
	barbg.add_child(fill)

	# animación: emblema entra, título/subtítulo aparecen, barra se llena, fade→menú
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(emblem, "modulate:a", 1.0, 0.5)
	t.tween_property(emblem, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.chain().tween_property(title, "modulate:a", 1.0, 0.4)
	t.parallel().tween_property(sub, "modulate:a", 1.0, 0.4)
	# latido suave del emblema
	var pulse := create_tween().set_loops()
	pulse.tween_property(emblem, "scale", Vector2(1.05, 1.05), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(emblem, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# barra de carga (0 → 1 en ~1.4s)
	var bar := create_tween()
	bar.tween_interval(0.35)
	bar.tween_property(fill, "anchor_right", 1.0, 1.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	bar.tween_interval(0.15)
	bar.tween_callback(_go_menu)

func _go_menu() -> void:
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.35)
	fade.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))

func _font(l: Label, size: int, col: Color, title: bool, weight: int) -> void:
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	var f := UITheme.display(weight) if title else UITheme.body(weight)
	if f != null:
		l.add_theme_font_override("font", f)
