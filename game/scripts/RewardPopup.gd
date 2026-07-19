extends RefCounted
class_name RewardPopup
## Ventana de RECIBO: le deja CLARO al jugador qué está recibiendo/crafteando y
## qué pagó (transparencia = menos tickets de soporte). Reutilizable desde
## cualquier pantalla: Tienda (compra), Inventario (crafteo / abrir cofre)…
##
## RewardPopup.show(self, "¡Compra realizada!", UITheme.SUCCESS,
##     [{"icon": "🎯", "text": "Ataque Oro", "sub": "×1 añadido a tu inventario"}],
##     "Pagaste 💎 30 · Saldo: 💎 4")

static func show(host: Node, title: String, accent: Color, items: Array, footer := "") -> void:
	var layer := CanvasLayer.new()
	layer.layer = 45
	host.add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)
	var tw := host.create_tween()
	tw.tween_property(dim, "color:a", 0.7, 0.2)

	# destello radial detrás de la tarjeta
	var glow := TextureRect.new()
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g := Gradient.new()
	g.set_color(0, Color(accent.r, accent.g, accent.b, 0.5))
	g.set_color(1, Color(accent.r, accent.g, accent.b, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 1.0)
	glow.texture = gt
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.set_anchors_preset(Control.PRESET_CENTER)
	glow.offset_left = -240
	glow.offset_right = 240
	glow.offset_top = -240
	glow.offset_bottom = 240
	glow.modulate.a = 0.0
	layer.add_child(glow)
	var gw := host.create_tween()
	gw.tween_property(glow, "modulate:a", 1.0, 0.35)

	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(cc)
	var panel := PanelContainer.new()
	var vw: float = host.get_viewport().get_visible_rect().size.x
	panel.custom_minimum_size = Vector2(minf(420.0, vw - 28.0), 0)
	panel.add_theme_stylebox_override("panel", UITheme.panel(UITheme.SURFACE, accent, 20, 2, 18))
	cc.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)

	var t := Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(t, 19, accent, true, 800)
	vb.add_child(t)

	for it in items:
		var d: Dictionary = it
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", UITheme.panel(UITheme.PANEL_DEEP, Color(accent.r, accent.g, accent.b, 0.4), 13, 1, 8))
		vb.add_child(row)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		row.add_child(hb)
		var tile := UITheme.icon_tile_node(String(d.get("icon", "🎁")), Color(d.get("col", accent)), 40, 20)
		hb.add_child(tile)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		col.add_theme_constant_override("separation", 0)
		hb.add_child(col)
		var nm := Label.new()
		nm.text = String(d.get("text", "?"))
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UITheme.label(nm, 14, UITheme.TEXT, true, 700)
		col.add_child(nm)
		var sub := String(d.get("sub", ""))
		if sub != "":
			var sl := Label.new()
			sl.text = sub
			sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			UITheme.label(sl, 11, UITheme.TEXT2, false, 600)
			col.add_child(sl)

	if footer != "":
		var fl := Label.new()
		fl.text = footer
		fl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UITheme.label(fl, 12, UITheme.GOLD, true, 700)
		vb.add_child(fl)

	var okb := Button.new()
	okb.text = "✓ Entendido"
	okb.custom_minimum_size = Vector2(0, 48)
	UITheme.button_font(okb, 15, Color.WHITE, true, 800)
	UITheme.style_primary(okb, accent.darkened(0.12), 14)
	okb.pressed.connect(func(): layer.queue_free())
	vb.add_child(okb)

	# entrada "juicy": la tarjeta ESTALLA en pantalla
	panel.pivot_offset = panel.size * 0.5
	panel.resized.connect(func(): panel.pivot_offset = panel.size * 0.5)
	panel.scale = Vector2(0.55, 0.55)
	panel.modulate.a = 0.0
	var pt := host.create_tween()
	pt.set_parallel(true)
	pt.tween_property(panel, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pt.tween_property(panel, "modulate:a", 1.0, 0.2)
	var sfx := (host.get_tree().root.get_node_or_null("Sfx") if host.is_inside_tree() else null)
	if sfx != null:
		sfx.call("play", "rankup")
