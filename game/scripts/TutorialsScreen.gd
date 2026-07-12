extends Control
## CÓMO JUGAR — el AULA: capítulos del FULL tutorial por categoría (Tablero /
## Menú). Cada capítulo se puede repetir; la PRIMERA vez que lo superas da XP.
## Lecciones de tablero = combates guionados (TutorialLib + Board3D); las de
## Menú son guías "pícale aquí" dentro de la pantalla real.

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UITheme.BG_DEEP
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 16
	root.offset_right = -16
	root.offset_top = 12
	root.offset_bottom = -12
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	# --- header: título + progreso ---
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	root.add_child(top)
	var back := Button.new()
	back.text = "←"
	back.custom_minimum_size = Vector2(48, 44)
	UITheme.button_font(back, 22, UITheme.TEXT)
	UITheme.style_surface(back)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	top.add_child(back)
	var title := Label.new()
	title.text = "Cómo jugar"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.label(title, 24, UITheme.TEXT, true, 800)
	top.add_child(title)
	var prog := PanelContainer.new()
	prog.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	prog.add_theme_stylebox_override("panel", UITheme.pill(UITheme.PANEL_DEEP, UITheme.SUCCESS, 10))
	var pl := Label.new()
	pl.text = "🎓 %d/%d" % [TutorialLib.done_count(), TutorialLib.CHAPTERS.size()]
	UITheme.label(pl, 13, UITheme.SUCCESS, true, 800)
	prog.add_child(pl)
	top.add_child(prog)

	var hint := Label.new()
	var xp_left: int = TutorialLib.xp_pending()
	hint.text = ("Supera cada capítulo UNA vez y gana su XP (quedan ✨ %d XP por reclamar). Puedes repetirlos cuando quieras." % xp_left) \
		if xp_left > 0 else "¡Aula completada! Puedes repetir cualquier capítulo cuando quieras."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.label(hint, 12, UITheme.MUTED, false, 600)
	root.add_child(hint)

	# --- capítulos por categoría (scroll) ---
	var scr := ScrollContainer.new()
	scr.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scr.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scr)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	scr.add_child(body)

	for cat in [TutorialLib.CAT_BOARD, TutorialLib.CAT_MENU]:
		var hdr := Label.new()
		var icon := "🎲" if cat == TutorialLib.CAT_BOARD else "📱"
		UITheme.section(hdr, "%s %s  ·  %d pendientes" % [icon, cat, TutorialLib.pending_in(cat)])
		body.add_child(hdr)
		for c in TutorialLib.CHAPTERS:
			if String(c["cat"]) == cat:
				body.add_child(_chapter_row(c))

func _chapter_row(c: Dictionary) -> Control:
	var id := String(c["id"])
	var done := TutorialLib.is_done(id)
	var accent: Color = UITheme.SUCCESS if done else UITheme.GOLD
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 68)
	UITheme.style_surface(b, UITheme.PANEL_DEEP, Color(accent.r, accent.g, accent.b, 0.5), 14)
	var hb := HBoxContainer.new()
	hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	hb.offset_left = 10
	hb.offset_right = -10
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_theme_constant_override("separation", 10)
	b.add_child(hb)
	var tile := UITheme.icon_tile_node(String(c["icon"]), accent, 40, 20)
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(tile)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 0)
	hb.add_child(col)
	var t := Label.new()
	t.text = String(c["title"])
	UITheme.label(t, 15, UITheme.TEXT, true, 700)
	col.add_child(t)
	var d := Label.new()
	d.text = String(c["desc"])
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.label(d, 11, UITheme.TEXT2, false, 600)
	col.add_child(d)
	var chip := Label.new()
	chip.text = "✓" if done else "✨ +%d XP" % int(c["xp"])
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UITheme.label(chip, 14 if done else 12, accent, true, 800)
	hb.add_child(chip)
	b.pressed.connect(func(): _launch(id))
	return b

## Lanza el capítulo: lección guionada / primera partida / guía de menú.
func _launch(id: String) -> void:
	if id == "primera":
		Loadout.tutorial = true
		get_tree().change_scene_to_file("res://scenes/board.tscn")
		return
	if id.begins_with("menu_"):
		TutorialLib.active_guide = id
		get_tree().change_scene_to_file("res://scenes/inventory.tscn")
		return
	if not TutorialLib.lesson(id).is_empty():
		Loadout.lesson = id
		get_tree().change_scene_to_file("res://scenes/board.tscn")
