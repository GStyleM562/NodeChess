extends Node3D
## Dex / library: browse each roster figure — its 3D model (turntable), attack
## TYPE, and its ACTUAL attack pool with probabilities. Lets you verify every
## figure really uses its own attacks (not random/mismatched ones).

var _index := 0
var _current: Figure3D
var _pivot: Node3D
var _cam: Camera3D
var _name_label: Label
var _type_label: Label
var _attacks_box: VBoxContainer
var _passives_box: VBoxContainer
var _evos_box: VBoxContainer
var _edit_btn: Button
var _copy_btn: Button
var _info_panel: PanelContainer
var _info_toggle: Button
var _search: LineEdit
var _filter_btn: Button
var _fav_btn: Button
var _completion: Label
var _filter_mode := 0          # 0 Todas · 1 ⭐ · 2 Poseídas · 3 Tuyas
var _filtered: Array = []      # índices del roster que pasan el filtro

const FILTER_NAMES := ["Todas", "⭐ Favoritas", "Poseídas", "Tuyas ✎"]

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	_build_env()
	_build_ui()
	_rebuild_filter()
	_spawn(_filtered[0] if not _filtered.is_empty() else 0)

func _process(delta: float) -> void:
	if _pivot != null:
		_pivot.rotate_y(delta * 0.6)

func _build_env() -> void:
	_cam = Camera3D.new()
	_cam.keep_aspect = Camera3D.KEEP_WIDTH
	_cam.fov = 24.0
	_cam.look_at_from_position(Vector3(0.0, 1.35, 3.8), Vector3(0.0, 1.05, 0.0), Vector3.UP)
	add_child(_cam)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -40.0, 0.0)
	sun.light_energy = 1.3
	add_child(sun)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = UITheme.BG_DEEP
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.6, 0.8)
	env.ambient_light_energy = 0.75
	we.environment = env
	add_child(we)
	var base := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.6
	disc.bottom_radius = 0.62
	disc.height = 0.06
	base.mesh = disc
	base.position = Vector3(0.0, -0.03, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.18, 0.26)
	base.material_override = mat
	add_child(base)
	_pivot = Node3D.new()
	add_child(_pivot)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var top := VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = 16
	top.offset_left = 12
	top.offset_right = -12
	layer.add_child(top)
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(_name_label, 28, UITheme.TEXT, true, 800)
	top.add_child(_name_label)
	_type_label = Label.new()
	_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(_type_label, 18, UITheme.PRIMARY_EDGE, true, 600)
	top.add_child(_type_label)
	# "Modificar": only shown for player-created (custom) figures.
	_edit_btn = Button.new()
	_edit_btn.text = "✎ Modificar este personaje"
	_edit_btn.custom_minimum_size = Vector2(0, 38)
	UITheme.button_font(_edit_btn, 14, UITheme.TEXT, true, 700)
	UITheme.style_primary(_edit_btn, UITheme.GOLD.darkened(0.1))
	_edit_btn.pressed.connect(_to_edit)
	_edit_btn.visible = false
	top.add_child(_edit_btn)
	# "Copiar código": shareable/backup code for player-created figures. Paste it in
	# the Creator ("Importar") to restore the figure after a reinstall or on another phone.
	_copy_btn = Button.new()
	_copy_btn.text = "⧉ Copiar código (respaldo)"
	_copy_btn.custom_minimum_size = Vector2(0, 38)
	UITheme.button_font(_copy_btn, 14, UITheme.TEXT, true, 700)
	UITheme.style_surface(_copy_btn, UITheme.SURFACE, UITheme.BORDER, 10)
	_copy_btn.pressed.connect(_copy_code)
	_copy_btn.visible = false
	top.add_child(_copy_btn)
	# --- Colección 2.0: buscar · filtrar · favorito · % completado ---
	var frow := HBoxContainer.new()
	frow.add_theme_constant_override("separation", 6)
	top.add_child(frow)
	_search = LineEdit.new()
	_search.placeholder_text = "🔎 Buscar…"
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.custom_minimum_size = Vector2(0, 40)
	_search.add_theme_stylebox_override("normal", UITheme.input())
	_search.add_theme_stylebox_override("focus", UITheme.input(UITheme.INPUT_BG, UITheme.PRIMARY))
	_search.add_theme_color_override("font_color", UITheme.TEXT)
	_search.add_theme_color_override("font_placeholder_color", UITheme.MUTED)
	var mf := UITheme.body(500)
	if mf != null:
		_search.add_theme_font_override("font", mf)
	_search.text_changed.connect(func(_t): _rebuild_filter(); _goto_first())
	frow.add_child(_search)
	_filter_btn = Button.new()
	_filter_btn.text = FILTER_NAMES[0]
	_filter_btn.custom_minimum_size = Vector2(120, 40)
	UITheme.button_font(_filter_btn, 12, UITheme.PRIMARY_EDGE, true, 700)
	UITheme.style_surface(_filter_btn, UITheme.SURFACE2, UITheme.BORDER, 10)
	_filter_btn.pressed.connect(func():
		_filter_mode = (_filter_mode + 1) % FILTER_NAMES.size()
		_filter_btn.text = FILTER_NAMES[_filter_mode]
		_rebuild_filter()
		_goto_first())
	frow.add_child(_filter_btn)
	_fav_btn = Button.new()
	_fav_btn.text = "☆"
	_fav_btn.custom_minimum_size = Vector2(44, 38)
	UITheme.button_font(_fav_btn, 18, UITheme.GOLD, true, 700)
	UITheme.style_surface(_fav_btn, UITheme.SURFACE2, UITheme.BORDER, 10)
	_fav_btn.pressed.connect(func():
		var id := String(Roster.FIGURES[_index].get("id", ""))
		Settings.toggle_favorite(id)
		_fav_btn.text = "⭐" if Settings.is_favorite(id) else "☆")
	frow.add_child(_fav_btn)
	_completion = Label.new()
	_completion.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.label(_completion, 11, UITheme.MUTED, true, 700)
	frow.add_child(_completion)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -468
	panel.offset_bottom = -72
	panel.offset_left = 10
	panel.offset_right = -10
	panel.add_theme_stylebox_override("panel", UITheme.group_panel(16, 12))
	layer.add_child(panel)
	_info_panel = panel
	# Toggle: hide the big info card so the 3D model can actually be admired.
	_info_toggle = Button.new()
	_info_toggle.text = "▼ Ocultar info"
	_info_toggle.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_info_toggle.offset_left = 120
	_info_toggle.offset_right = -120
	_info_toggle.offset_top = -506
	_info_toggle.offset_bottom = -472
	UITheme.button_font(_info_toggle, 13, UITheme.TEXT2, true, 700)
	UITheme.style_surface(_info_toggle, UITheme.SURFACE, UITheme.BORDER, 12)
	_info_toggle.pressed.connect(_toggle_info)
	layer.add_child(_info_toggle)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 6)
	scroll.add_child(vb)

	vb.add_child(_dex_hdr("PASIVAS"))
	_passives_box = VBoxContainer.new()
	_passives_box.add_theme_constant_override("separation", 4)
	vb.add_child(_passives_box)

	vb.add_child(_dex_hdr("EVOLUCIONES · RANK UP"))
	_evos_box = VBoxContainer.new()
	_evos_box.add_theme_constant_override("separation", 4)
	vb.add_child(_evos_box)

	vb.add_child(_dex_hdr("ATAQUES · probabilidad"))
	_attacks_box = VBoxContainer.new()
	_attacks_box.add_theme_constant_override("separation", 4)
	vb.add_child(_attacks_box)

	var nav := HBoxContainer.new()
	nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav.offset_top = -60
	nav.offset_bottom = -14
	nav.offset_left = 10
	nav.offset_right = -10
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 16)
	layer.add_child(nav)
	var prev := Button.new()
	prev.text = "◀"
	prev.custom_minimum_size = Vector2(64, 48)
	UITheme.button_font(prev, 20, UITheme.TEXT, true, 700)
	UITheme.style_surface(prev, UITheme.SURFACE, UITheme.BORDER, 12)
	prev.pressed.connect(func(): _switch(-1))
	nav.add_child(prev)
	var menu := Button.new()
	menu.text = "Menú"
	menu.custom_minimum_size = Vector2(140, 48)
	UITheme.button_font(menu, 20, UITheme.TEXT2, true, 700)
	UITheme.style_surface(menu, UITheme.SURFACE, UITheme.BORDER, 12)
	menu.pressed.connect(_to_menu)
	nav.add_child(menu)
	var nxt := Button.new()
	nxt.text = "▶"
	nxt.custom_minimum_size = Vector2(64, 48)
	UITheme.button_font(nxt, 20, UITheme.TEXT, true, 700)
	UITheme.style_surface(nxt, UITheme.SURFACE, UITheme.BORDER, 12)
	nxt.pressed.connect(func(): _switch(1))
	nav.add_child(nxt)

func _dex_hdr(text: String) -> Label:
	var l := Label.new()
	UITheme.section(l, text)   # azul, MAYÚSCULAS, Manrope 700
	return l

func _spawn(i: int) -> void:
	_index = i
	if _current != null:
		_current.queue_free()
		_current = null
	var data: Dictionary = Roster.FIGURES[i]
	_current = Figure3D.new()
	_pivot.add_child(_current)
	_current.setup(data["glb"], data["clips"], float(data.get("size", 1.0)))
	_current.play_clip("idle")
	var pos := _filtered.find(i)
	_name_label.text = "%d/%d   %s" % [(pos + 1) if pos >= 0 else i + 1, maxi(1, _filtered.size()), data["name"]]
	if _fav_btn != null:
		_fav_btn.text = "⭐" if Settings.is_favorite(String(data.get("id", ""))) else "☆"
	var warn := "   ⚠ anim incompleta" if not data.get("complete", true) else ""
	_type_label.text = "Tipo de ataque: " + String(data.get("type", "?")) + warn
	if _edit_btn != null:
		_edit_btn.visible = bool(data.get("custom", false))
	if _copy_btn != null:
		_copy_btn.visible = bool(data.get("custom", false))
		_copy_btn.text = "⧉ Copiar código (respaldo)"
	_build_passives(data)
	_build_evolutions(data)
	_build_attacks(data["attack"])

func _build_attacks(pool: Array) -> void:
	for c in _attacks_box.get_children():
		c.queue_free()
	var total := 0.0
	for s in pool:
		total += float(s.get("w", 1.0))
	for s in pool:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		# swatch redondeado del color del segmento (§6.3)
		var sw := Panel.new()
		sw.custom_minimum_size = Vector2(22, 22)
		var ssb := StyleBoxFlat.new()
		ssb.bg_color = Combat.color_of(s)
		ssb.set_corner_radius_all(6)
		ssb.set_border_width_all(1)
		ssb.border_color = Color(1, 1, 1, 0.22)
		sw.add_theme_stylebox_override("panel", ssb)
		row.add_child(sw)
		var seg_name := Combat.label(s)
		if s.has("fx"):
			seg_name += "   [" + String(s["fx"]) + "]"
		var lbl := Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.label(lbl, 17, UITheme.TEXT, false, 600)
		lbl.text = seg_name
		row.add_child(lbl)
		var pct := 100.0 * float(s.get("w", 1.0)) / total
		var pl := Label.new()
		UITheme.label(pl, 17, UITheme.GOLD, true, 800)
		pl.text = "%.0f%%" % pct
		row.add_child(pl)
		_attacks_box.add_child(row)

func _build_passives(d: Dictionary) -> void:
	for c in _passives_box.get_children():
		c.queue_free()
	var ids: Array = (d.get("passives", []) as Array).duplicate()
	# Include hidden passives from evolution stages (catalog marks them "(oculta)").
	for st in d.get("ranks", []):
		for h in st.get("hidden", []):
			if h not in ids:
				ids.append(h)
	if ids.is_empty():
		var l := Label.new()
		l.text = "—  (sin pasivas)"
		l.modulate = Color(0.6, 0.6, 0.7)
		l.add_theme_font_size_override("font_size", 16)
		_passives_box.add_child(l)
		return
	for pid in ids:
		var info: Dictionary = Roster.PASSIVES.get(pid, {})
		var lbl := Label.new()
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.text = "• %s — %s" % [String(info.get("name", pid)), String(info.get("desc", ""))]
		# color EXPLÍCITO: el default de Godot es blanco (invisible sobre crema)
		UITheme.label(lbl, 16, UITheme.TEXT, false, 600)
		_passives_box.add_child(lbl)
	# Resistencias a estados (inmunidades de esta figura)
	var res: Array = d.get("resists", [])
	if not res.is_empty():
		var names: Array = []
		for sid in res:
			for label in GameState.FX_STATUS.keys():
				if String(GameState.FX_STATUS[label]) == String(sid):
					names.append(String(label))
		var rl := Label.new()
		rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rl.text = "🛡 Resiste: " + ", ".join(names)
		UITheme.label(rl, 16, UITheme.ENERGY, false, 700)
		_passives_box.add_child(rl)

func _build_evolutions(d: Dictionary) -> void:
	for c in _evos_box.get_children():
		c.queue_free()
	var ranks: Array = d.get("ranks", [])
	if ranks.is_empty():
		var l := Label.new()
		l.text = "—  (no evoluciona)"
		l.modulate = Color(0.6, 0.6, 0.7)
		l.add_theme_font_size_override("font_size", 16)
		_evos_box.add_child(l)
		return
	_evo_row("Base: %s · %s · ST %d" % [d["name"], String(d.get("type", "?")), int(d.get("stamina", 2))])
	for i in ranks.size():
		var st: Dictionary = ranks[i]
		_evo_row("+%d: %s · %s · ST %d" % [
			i + 1, String(st.get("name", "?")), String(st.get("type", d.get("type", "?"))), int(st.get("stamina", d.get("stamina", 2)))])

func _evo_row(text: String) -> void:
	var lbl := Label.new()
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.text = "• " + text
	UITheme.label(lbl, 16, UITheme.TEXT, false, 600)
	_evos_box.add_child(lbl)

## Show/hide the info card. Hidden -> the toggle drops to the bottom, next to nav.
func _toggle_info() -> void:
	_info_panel.visible = not _info_panel.visible
	_info_toggle.text = "▼ Ocultar info" if _info_panel.visible else "▲ Ver info"
	_info_toggle.offset_top = -506 if _info_panel.visible else -110
	_info_toggle.offset_bottom = -472 if _info_panel.visible else -76

## Índices del roster que pasan búsqueda + filtro. Nunca vacío (cae a "Todas").
func _rebuild_filter() -> void:
	_filtered.clear()
	var q := (_search.text if _search != null else "").strip_edges().to_lower()
	var owned_total := 0
	var builtin_total := 0
	for i in Roster.FIGURES.size():
		var d: Dictionary = Roster.FIGURES[i]
		var id := String(d.get("id", ""))
		var custom := bool(d.get("custom", false))
		var owned := custom or Inventory.is_admin() or Inventory.has_piece("model:" + id)
		if not custom:
			builtin_total += 1
			if owned:
				owned_total += 1
		if q != "" and not String(d.get("name", "")).to_lower().contains(q):
			continue
		match _filter_mode:
			1:
				if not Settings.is_favorite(id):
					continue
			2:
				if not owned:
					continue
			3:
				if not custom:
					continue
		_filtered.append(i)
	if _filtered.is_empty():
		for i in Roster.FIGURES.size():
			_filtered.append(i)
	if _completion != null:
		_completion.text = "%d%%" % int(100.0 * owned_total / maxf(1.0, float(builtin_total)))

func _goto_first() -> void:
	if not _filtered.is_empty():
		_spawn(int(_filtered[0]))

func _switch(d: int) -> void:
	# navega DENTRO del filtro activo
	var pos := _filtered.find(_index)
	if pos == -1:
		pos = 0
	pos = wrapi(pos + d, 0, _filtered.size())
	_spawn(int(_filtered[pos]))

func _to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

## Copy this figure's share/backup code to the clipboard.
func _copy_code() -> void:
	var data: Dictionary = Roster.FIGURES[_index]
	if not bool(data.get("custom", false)):
		return
	DisplayServer.clipboard_set(CustomFigures.export_code(data))
	_copy_btn.text = "✓ Código copiado — pégalo donde quieras"

## Load this (custom) figure into the Character Creator for editing.
func _to_edit() -> void:
	var data: Dictionary = Roster.FIGURES[_index]
	if not bool(data.get("custom", false)):
		return
	CharacterCreator.edit_figure = data.duplicate(true)
	get_tree().change_scene_to_file("res://scenes/character_creator.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if (event as InputEventKey).keycode == KEY_RIGHT:
			_switch(1)
		elif (event as InputEventKey).keycode == KEY_LEFT:
			_switch(-1)
