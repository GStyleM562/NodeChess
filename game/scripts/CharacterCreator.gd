extends Control
class_name CharacterCreator
## Character Creator — compose a figure from existing engine-supported building
## blocks (5 attack types, 5 colours, the status/displacement library, the passive
## catalog), validate it (FigureValidator / GDD §32) and save it (CustomFigures).
## Saved figures merge into the Roster → Dex, Deck Builder and matches. A real 3D
## model is wired in later; until then the figure borrows an existing model.
##
## The figure-building logic is a pure static (make_figure) so it can be unit-tested
## without the UI (see tools/test_creator.gd).

const COL_IDS := ["white", "gold", "purple", "blue", "red"]
const COL_ES := ["Blanco (daño)", "Oro (daño)", "Púrpura (★)", "Azul (bloqueo)", "Rojo (fallo)"]
const CLASSES := ["Balanced", "Agile", "Tank", "Debuffer", "Buffer", "Striker", "Controller", "Specialist"]
const RARITIES := ["common", "rare", "epic", "legend", "mythic"]
const RARITY_ES := ["Común", "Rara", "Épica", "Legendaria", "Mítica"]
const TYPES := ["Ruleta", "Dado (D4)", "Dado (D6)", "Dado (D8)", "Dado (D10)", "Dado (D12)", "Moneda", "Doble Moneda", "Suma 2d6"]
# fx label -> extra segment fields. Statuses match GameState.FX_STATUS; the last
# three are displacements (carry "disp"/"n" instead of a status).
const FX_OPTS := [
	{"label": "Ninguno"},
	{"label": "Miedo", "fx": "Miedo"}, {"label": "Debilitado", "fx": "Debilitado"},
	{"label": "Paralizado", "fx": "Paralizado"}, {"label": "Inmovilizado", "fx": "Inmovilizado"},
	{"label": "Quemadura", "fx": "Quemadura"}, {"label": "Veneno", "fx": "Veneno"},
	{"label": "Congelado", "fx": "Congelado"}, {"label": "Silencio", "fx": "Silencio"},
	{"label": "Confusión", "fx": "Confusión"}, {"label": "Sueño", "fx": "Sueño"},
	{"label": "Maldición", "fx": "Maldición"}, {"label": "Marcado", "fx": "Marcado"},
	{"label": "Escudo Roto", "fx": "Escudo Roto"},
	{"label": "Empuje 1", "fx": "Empuje", "disp": "push", "n": 1},
	{"label": "Jalón 1", "fx": "Jalón", "disp": "pull", "n": 1},
	{"label": "Intercambio", "fx": "Intercambio", "disp": "swap"},
]
# Passives that are unlocked only via Rank Up (cannot be equipped directly).
const HIDDEN_PASSIVES := ["venom_aura", "burning_aura", "loaded_dice", "phase", "kindling_resolve"]

# Help text shown by the ⓘ buttons (same order as COL_IDS).
const COL_DESC := [
	"Blanco — daño directo. Vence a Oro, pierde con Púrpura. Si gana: K.O.",
	"Oro — daño/especial. Vence a Púrpura, puede perder con Blanco. Si gana: K.O.",
	"Púrpura — especial (★1–3). Vence a Blanco, pierde con Oro. Aplica su efecto (no K.O.).",
	"Azul — bloqueo defensivo. Vence a Blanco/Oro/Púrpura. Nunca noquea.",
	"Rojo — Fallo. Siempre pierde.",
]
const FX_DESC := {
	"Ninguno": "Sin efecto extra.",
	"Miedo": "La víctima no puede atacar.",
	"Debilitado": "−20 daño y −1★ en sus tiradas.",
	"Paralizado": "No puede moverse ni atacar.",
	"Inmovilizado": "No puede moverse.",
	"Quemadura": "K.O. tras 6 turnos si no se limpia, y −10 daño mientras arde.",
	"Veneno": "K.O. tras 8 turnos si no se limpia (más lento).",
	"Congelado": "No mueve ni ataca; además su Azul no bloquea.",
	"Silencio": "Sus ataques Púrpura fallan.",
	"Confusión": "Al atacar, 50% de probabilidad de fallar.",
	"Sueño": "No mueve ni ataca; despierta al entrar en combate.",
	"Maldición": "Pierde todos los empates.",
	"Marcado": "El rival recibe +20 daño / +1★ al atacarla.",
	"Escudo Roto": "Su Azul no bloquea.",
	"Empuje 1": "Empuja al rival 1 nodo.",
	"Jalón 1": "Atrae al rival 1 nodo hacia ti.",
	"Intercambio": "Intercambia posiciones con el rival.",
}

# Set this static before changing to the creator scene to EDIT an existing figure
# (Dex "Modificar" does this). _ready loads it and clears it.
static var edit_figure := {}

var _scroll: ScrollContainer
var _name: LineEdit
var _desc: LineEdit
var _class: OptionButton
var _rarity: OptionButton
var _type: OptionButton
var _model: OptionButton
var _stamina: SpinBox
var _evolve: CheckBox
var _evo_box: VBoxContainer       # evolution sub-section (hidden until "Evoluciona")
var _phase_count: SpinBox
var _phase_holder: VBoxContainer
var _phase_opts: Array = []        # one OptionButton per evolution phase
var _evo_fig_ids: Array = []       # figure ids selectable as an evolution stage
var _evo_names: Array = []
var _passive_boxes := {}          # pid -> toggle Button
var _rows: Array = []             # each: { panel, col, name, pow, stars, fx, prob }
var _rows_box: VBoxContainer
var _total_lbl: Label
var _status_lbl: Label
var _save_btn: Button
var _model_ids: Array = []
var _editing_id := ""             # non-empty when editing -> save overwrites it

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = UITheme.BG_DEEP
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_build_topbar()

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 60
	scroll.offset_bottom = -70
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_scroll = scroll
	_setup_scroll(scroll)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 14)
	pad.add_theme_constant_override("margin_right", 14)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_theme_constant_override("margin_bottom", 8)
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(pad)
	var form := VBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_theme_constant_override("separation", 12)
	pad.add_child(form)

	_build_identity(form)
	_build_combat(form)
	_build_passives(form)
	_build_pool(form)

	_build_footer()
	_seed_default_pool()
	if not edit_figure.is_empty():
		_load_figure(edit_figure)
		edit_figure = {}
	_revalidate()

# ---------------------------------------------------------------- top / footer
func _build_topbar() -> void:
	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 56
	bar.add_theme_stylebox_override("panel", UITheme.panel(UITheme.BG, UITheme.BORDER, 0, 0, 8))
	add_child(bar)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	bar.add_child(hb)
	var back := Button.new()
	back.text = "←"
	UITheme.button_font(back, 22, UITheme.TEXT)
	UITheme.style_surface(back)
	back.custom_minimum_size = Vector2(48, 40)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	hb.add_child(back)
	var title := Label.new()
	title.text = "Editar Personaje" if not edit_figure.is_empty() else "Crear Personaje"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.label(title, 22, UITheme.GOLD, true, 800)
	hb.add_child(title)

func _build_footer() -> void:
	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -66
	bar.add_theme_stylebox_override("panel", UITheme.panel(UITheme.BG, UITheme.BORDER, 0, 1, 8))
	add_child(bar)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	bar.add_child(vb)
	_status_lbl = Label.new()
	_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.label(_status_lbl, 12, UITheme.TEXT2, false, 600)
	vb.add_child(_status_lbl)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	vb.add_child(hb)
	_save_btn = Button.new()
	_save_btn.text = "Guardar figura"
	_save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.button_font(_save_btn, 16, UITheme.TEXT, true, 800)
	UITheme.style_primary(_save_btn, UITheme.SUCCESS)
	_save_btn.pressed.connect(_on_save)
	hb.add_child(_save_btn)

# ---------------------------------------------------------------- sections
func _section(parent: VBoxContainer, title: String) -> VBoxContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.panel(UITheme.SURFACE, UITheme.BORDER, 16, 1, 12))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	p.add_child(vb)
	var t := Label.new()
	t.text = title
	UITheme.label(t, 14, UITheme.PRIMARY_EDGE, true, 800)
	vb.add_child(t)
	return vb

func _field(parent: VBoxContainer, caption: String, control: Control) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	parent.add_child(hb)
	var l := Label.new()
	l.text = caption
	l.custom_minimum_size = Vector2(96, 0)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.label(l, 12, UITheme.TEXT2, false, 600)
	hb.add_child(l)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(control)

func _build_identity(form: VBoxContainer) -> void:
	var s := _section(form, "Identidad")
	_name = LineEdit.new()
	_name.placeholder_text = "Nombre"
	_name.text_changed.connect(func(_t): _revalidate())
	_field(s, "Nombre", _name)
	_desc = LineEdit.new()
	_desc.placeholder_text = "Descripción corta"
	_field(s, "Descripción", _desc)
	_class = _opt(CLASSES)
	_field(s, "Clase", _class)
	_rarity = _opt(RARITY_ES)
	_rarity.select(2)   # Épica by default
	_field(s, "Rareza", _rarity)

func _build_combat(form: VBoxContainer) -> void:
	var s := _section(form, "Combate")
	_stamina = SpinBox.new()
	_stamina.min_value = 0; _stamina.max_value = 6; _stamina.value = 2
	_stamina.value_changed.connect(func(_v): _revalidate())
	_field(s, "Estamina", _stamina)
	_type = _opt(TYPES)
	_type.select(0)
	_type.item_selected.connect(func(_i): _revalidate())
	_field(s, "Tipo ataque", _type)
	# placeholder model (borrow an existing figure until a real GLB is added)
	_model_ids = []
	var names: Array = []
	for f in Roster.FIGURES:
		if not bool(f.get("custom", false)):
			_model_ids.append(String(f.get("id", "")))
			names.append(String(f.get("name", "?")))
	_model = _opt(names)
	_field(s, "Modelo (placeholder)", _model)
	# --- evolution ---
	_evolve = CheckBox.new()
	_evolve.text = "Evoluciona (Rank Up)"
	UITheme.button_font(_evolve, 14, UITheme.GOLD, false, 700)
	_evolve.toggled.connect(_on_evolve_toggled)
	s.add_child(_evolve)
	# Figures selectable as an evolution stage (every roster figure is already valid).
	_evo_fig_ids = []
	_evo_names = []
	for f in Roster.FIGURES:
		_evo_fig_ids.append(String(f.get("id", "")))
		_evo_names.append(String(f.get("name", "?")))
	_evo_box = VBoxContainer.new()
	_evo_box.add_theme_constant_override("separation", 6)
	_evo_box.visible = false
	s.add_child(_evo_box)
	var ev_hint := Label.new()
	ev_hint.text = "Cada fase evoluciona EN un personaje existente (toma sus ataques)."
	ev_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.label(ev_hint, 11, UITheme.MUTED, false, 500)
	_evo_box.add_child(ev_hint)
	_phase_count = SpinBox.new()
	_phase_count.min_value = 1
	_phase_count.max_value = 3
	_phase_count.value = 1
	_phase_count.value_changed.connect(func(v): _rebuild_phases(int(v)))
	_field(_evo_box, "¿Cuántas fases?", _phase_count)
	_phase_holder = VBoxContainer.new()
	_phase_holder.add_theme_constant_override("separation", 6)
	_evo_box.add_child(_phase_holder)

func _build_passives(form: VBoxContainer) -> void:
	var s := _section(form, "Pasivas (máx. 3)")
	var hint := Label.new()
	hint.text = "Toca para activar/desactivar · ⓘ explica qué hace."
	UITheme.label(hint, 11, UITheme.MUTED, false, 500)
	s.add_child(hint)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	s.add_child(grid)
	for pid in Roster.PASSIVES.keys():
		if pid in HIDDEN_PASSIVES:
			continue
		var pname := String(Roster.PASSIVES[pid].get("name", pid))
		var pdesc := String(Roster.PASSIVES[pid].get("desc", ""))
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 4)
		# A toggle button reads clearly as "selectable" (fills with accent when ON).
		var tg := Button.new()
		tg.toggle_mode = true
		tg.text = pname
		tg.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tg.clip_text = true
		tg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tg.custom_minimum_size = Vector2(0, 38)
		tg.tooltip_text = pdesc
		_style_toggle(tg)
		tg.toggled.connect(func(_p): _revalidate())
		item.add_child(tg)
		item.add_child(_info_btn(func(): _show_info(pname, pdesc)))
		grid.add_child(item)
		_passive_boxes[pid] = tg

func _build_pool(form: VBoxContainer) -> void:
	var s := _section(form, "Pool de ataque")
	var hint := Label.new()
	hint.text = "Cada segmento: color + (daño/★) + efecto + probabilidad. En Ruleta deben sumar 100%."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.label(hint, 11, UITheme.MUTED, false, 500)
	s.add_child(hint)
	_rows_box = VBoxContainer.new()
	_rows_box.add_theme_constant_override("separation", 6)
	s.add_child(_rows_box)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	s.add_child(hb)
	var add := Button.new()
	add.text = "+ Segmento"
	UITheme.button_font(add, 13, UITheme.TEXT, false, 700)
	UITheme.style_surface(add)
	add.pressed.connect(func(): _add_row({"col": "white", "pow": 40, "w": 10}); _revalidate())
	hb.add_child(add)
	_total_lbl = Label.new()
	_total_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_total_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UITheme.label(_total_lbl, 13, UITheme.GOLD, true, 800)
	hb.add_child(_total_lbl)

# ---------------------------------------------------------------- pool rows
func _add_row(seg: Dictionary) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.panel(UITheme.SURFACE2, UITheme.BORDER, 12, 1, 8))
	_rows_box.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	p.add_child(vb)

	var line1 := HBoxContainer.new()
	line1.add_theme_constant_override("separation", 6)
	vb.add_child(line1)
	var col := _opt(COL_ES)
	col.select(COL_IDS.find(String(seg.get("col", "white"))))
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.item_selected.connect(func(_i): _revalidate())
	line1.add_child(col)
	var nm := LineEdit.new()
	nm.placeholder_text = "Nombre ataque"
	nm.text = String(seg.get("name", ""))
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line1.add_child(nm)

	var line2 := HBoxContainer.new()
	line2.add_theme_constant_override("separation", 6)
	vb.add_child(line2)
	var pw := _spin(0, 200, 5, int(seg.get("pow", 0)), "Daño")
	var st := _spin(1, 3, 1, int(seg.get("stars", 1)), "★")
	var fx := _opt(_fx_labels())
	fx.select(_fx_index(seg))
	fx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var prob := _spin(0, 100, 5, int(seg.get("w", 10)), "%")
	prob.get_line_edit().add_theme_color_override("font_color", UITheme.GOLD)
	prob.value_changed.connect(func(_v): _revalidate())
	pw.value_changed.connect(func(_v): _revalidate())
	st.value_changed.connect(func(_v): _revalidate())
	fx.item_selected.connect(func(_i): _revalidate())
	line2.add_child(_labeled("Daño", pw))
	line2.add_child(_labeled("★", st))
	line2.add_child(_labeled("%", prob))
	line2.add_child(_info_btn(func():
		var ci := int(col.selected)
		var fi := int(fx.selected)
		var body: String = COL_DESC[ci] if ci >= 0 and ci < COL_DESC.size() else ""
		if fi > 0 and fi < FX_OPTS.size():
			body += "\n\nEfecto «%s»: %s" % [String(FX_OPTS[fi]["label"]), _fx_desc(String(FX_OPTS[fi]["label"]))]
		_show_info("Segmento de ataque", body)))
	var del := Button.new()
	del.text = "✕"
	UITheme.button_font(del, 14, UITheme.DANGER)
	UITheme.style_surface(del)
	line2.add_child(del)
	vb.add_child(fx)

	var row := {"panel": p, "col": col, "name": nm, "pow": pw, "stars": st, "fx": fx, "prob": prob}
	_rows.append(row)
	del.pressed.connect(func():
		_rows.erase(row)
		p.queue_free()
		_revalidate())

func _seed_default_pool() -> void:
	_add_row({"col": "white", "name": "Golpe", "pow": 60, "w": 50})
	_add_row({"col": "blue", "name": "Guardia", "w": 30})
	_add_row({"col": "red", "w": 20})

# ---------------------------------------------------------------- figure build
## Read the UI into a figure dict (delegates to the pure static builder).
func build_figure() -> Dictionary:
	var pool: Array = []
	for row in _rows:
		pool.append({
			"col": COL_IDS[int(row["col"].selected)],
			"name": String(row["name"].text),
			"pow": int(row["pow"].value),
			"stars": int(row["stars"].value),
			"fx_index": int(row["fx"].selected),
			"w": int(row["prob"].value),
		})
	var passives: Array = []
	for pid in _passive_boxes.keys():
		if _passive_boxes[pid].button_pressed:
			passives.append(pid)
	var model_ref := ""
	if _model.selected >= 0 and _model.selected < _model_ids.size():
		model_ref = String(_model_ids[_model.selected])
	# Evolution stages: each phase evolves INTO an existing (valid) figure.
	var stages: Array = []
	if _evolve.button_pressed:
		for opt in _phase_opts:
			var sel := int(opt.selected)
			if sel >= 0 and sel < _evo_fig_ids.size():
				stages.append(_stage_from_figure(String(_evo_fig_ids[sel])))
	return make_figure({
		"name": _name.text, "desc": _desc.text,
		"class": CLASSES[_class.selected], "rarity": RARITIES[_rarity.selected],
		"stamina": int(_stamina.value), "type": TYPES[_type.selected],
		"passives": passives, "model_ref": model_ref,
		"evolve": _evolve.button_pressed, "stages": stages,
		"pool": pool,
	})

## Build one evolution-stage dict from an existing figure (its pool/type/stamina/
## passives). Stores `evolves_id` so editing can re-select the source figure.
func _stage_from_figure(id: String) -> Dictionary:
	var src := _figure_by_id(id)
	return {
		"name": String(src.get("name", "?")),
		"type": String(src.get("type", "Ruleta")),
		"stamina": int(src.get("stamina", 2)),
		"passives": (src.get("passives", []) as Array).duplicate(),
		"attack": (src.get("attack", []) as Array).duplicate(true),
		# carry the target figure's MODEL so the 3D figure changes on Rank Up
		"glb": String(src.get("glb", "")),
		"clips": (src.get("clips", {}) as Dictionary).duplicate(true),
		"size": float(src.get("size", 1.0)),
		"evolves_id": id,
	}

func _figure_by_id(id: String) -> Dictionary:
	for f in Roster.FIGURES:
		if String(f.get("id", "")) == id:
			return f
	return {}

# ---------------------------------------------------------------- evolution UI
func _on_evolve_toggled(on: bool) -> void:
	_evo_box.visible = on
	if on and _phase_opts.is_empty():
		_rebuild_phases(int(_phase_count.value))
	_revalidate()

func _rebuild_phases(n: int) -> void:
	for c in _phase_holder.get_children():
		_phase_holder.remove_child(c)
		c.queue_free()
	_phase_opts.clear()
	for i in n:
		var opt := _opt(_evo_names)
		opt.item_selected.connect(func(_i): _revalidate())
		_field(_phase_holder, "Fase %d →" % (i + 1), opt)
		_phase_opts.append(opt)
	_revalidate()

# ---------------------------------------------------------------- load (edit)
func _clear_pool() -> void:
	for row in _rows:
		row["panel"].queue_free()
	_rows.clear()

## Populate every control from an existing figure (Dex "Modificar").
func _load_figure(fig: Dictionary) -> void:
	_editing_id = String(fig.get("id", ""))
	_name.text = String(fig.get("name", ""))
	_desc.text = String(fig.get("desc", ""))
	_select_index(_class, CLASSES.find(String(fig.get("class", "Balanced"))))
	_select_index(_rarity, RARITIES.find(String(fig.get("rarity", "epic"))))
	_stamina.value = int(fig.get("stamina", 2))
	_select_index(_type, TYPES.find(String(fig.get("type", "Ruleta"))))
	_select_index(_model, _model_ids.find(String(fig.get("model_ref", ""))))
	var pl: Array = fig.get("passives", [])
	for pid in _passive_boxes.keys():
		_passive_boxes[pid].button_pressed = pid in pl
	_clear_pool()
	for seg in fig.get("attack", []):
		_add_row(seg)
	var ranks: Array = fig.get("ranks", [])
	if not ranks.is_empty():
		_evolve.button_pressed = true       # builds the evolution UI (1 phase)
		_phase_count.value = ranks.size()   # rebuilds to the right number of phases
		for i in ranks.size():
			if i < _phase_opts.size():
				var idx := _evo_fig_ids.find(String(ranks[i].get("evolves_id", "")))
				if idx >= 0:
					_phase_opts[i].select(idx)

func _select_index(opt: OptionButton, i: int) -> void:
	if opt != null and i >= 0 and i < opt.item_count:
		opt.select(i)

func _style_toggle(b: Button) -> void:
	b.add_theme_stylebox_override("normal", UITheme.panel(UITheme.SURFACE2, UITheme.BORDER, 10, 1, 8))
	var on := UITheme.panel(UITheme.PRIMARY.darkened(0.05), UITheme.PRIMARY_EDGE, 10, 2, 8)
	b.add_theme_stylebox_override("pressed", on)
	b.add_theme_stylebox_override("hover_pressed", on)
	b.add_theme_stylebox_override("hover", UITheme.panel(UITheme.SURFACE2.lightened(0.06), UITheme.PRIMARY, 10, 1, 8))
	UITheme.button_font(b, 12, UITheme.TEXT, false, 600)
	b.add_theme_color_override("font_pressed_color", UITheme.TEXT)
	b.add_theme_color_override("font_hover_pressed_color", UITheme.TEXT)

## Pure builder — no UI. `pool` rows carry col/name/pow/stars/fx_index/w.
static func make_figure(p: Dictionary) -> Dictionary:
	var attack := _build_pool_segments(p.get("pool", []))
	var fig := {
		"id": _slug(String(p.get("name", ""))),
		"name": String(p.get("name", "")),
		"desc": String(p.get("desc", "")),
		"class": String(p.get("class", "Specialist")),
		"rarity": String(p.get("rarity", "epic")),
		"stamina": int(p.get("stamina", 2)),
		"type": String(p.get("type", "Ruleta")),
		"passives": p.get("passives", []),
		"model_ref": String(p.get("model_ref", "")),
		"attack": attack,
	}
	var stages: Array = p.get("stages", [])
	if not stages.is_empty():
		fig["ranks"] = stages                       # each phase = an existing figure
	elif bool(p.get("evolve", false)):
		fig["ranks"] = [_boosted_stage(attack, fig["name"], fig["type"], int(fig["stamina"]), fig["passives"])]
	return fig

static func _build_pool_segments(rows: Array) -> Array:
	var out: Array = []
	for r in rows:
		var col := String(r.get("col", "white"))
		var seg := {"col": col, "w": float(r.get("w", 1))}
		if String(r.get("name", "")) != "":
			seg["name"] = String(r["name"])
		if col == "white" or col == "gold":
			if int(r.get("pow", 0)) > 0:
				seg["pow"] = int(r["pow"])
		elif col == "purple":
			seg["stars"] = clampi(int(r.get("stars", 1)), 1, 3)
		var fi := int(r.get("fx_index", 0))
		if fi > 0 and fi < FX_OPTS.size():
			var fxd: Dictionary = FX_OPTS[fi]
			if fxd.has("fx"):
				seg["fx"] = String(fxd["fx"])
			if fxd.has("disp"):
				seg["disp"] = String(fxd["disp"])
			if fxd.has("n"):
				seg["n"] = int(fxd["n"])
		out.append(seg)
	return out

## A simple evolved stage: same shape, white/gold damage +20, name marked ✦.
static func _boosted_stage(attack: Array, base_name: String, typ: String, stamina: int, passives: Array) -> Dictionary:
	var pool: Array = []
	for seg in attack:
		var s: Dictionary = seg.duplicate(true)
		if (String(s.get("col", "")) == "white" or String(s.get("col", "")) == "gold") and s.has("pow"):
			s["pow"] = int(s["pow"]) + 20
		pool.append(s)
	return {"name": base_name + " ✦", "type": typ, "stamina": stamina, "passives": passives, "attack": pool}

static func _slug(name: String) -> String:
	var s := name.strip_edges().to_lower()
	var out := ""
	for i in s.length():
		var c := s[i]
		if (c >= "a" and c <= "z") or (c >= "0" and c <= "9"):
			out += c
		elif c == " " or c == "_" or c == "-":
			out += "_"
	out = out.strip_edges()
	if out == "":
		out = "fig"
	return "custom_" + out

# ---------------------------------------------------------------- validate/save
func _revalidate() -> void:
	var total := 0
	for row in _rows:
		total += int(row["prob"].value)
	var is_wheel: bool = String(TYPES[_type.selected]).begins_with("Ruleta")
	_total_lbl.text = ("Total: %d%%" % total) if is_wheel else ("Pesos: %d" % total)
	_total_lbl.add_theme_color_override("font_color", UITheme.SUCCESS if (not is_wheel or total == 100) else UITheme.DANGER)

	var fig: Dictionary = build_figure()
	var r: Dictionary = FigureValidator.validate(fig)
	var state := String(r["state"])
	var msgs: Array = []
	for e in r["errors"]:
		msgs.append("✗ " + String(e))
	for w in r["warnings"]:
		msgs.append("⚠ " + String(w))
	var head: String = {"VALID": "✓ Válido", "WARNING": "⚠ Válido con avisos", "INVALID": "✗ Inválido"}[state]
	_status_lbl.text = head + ("  ·  " + "  ·  ".join(msgs) if not msgs.is_empty() else "")
	_status_lbl.add_theme_color_override("font_color",
		UITheme.SUCCESS if state == "VALID" else (UITheme.GOLD if state == "WARNING" else UITheme.DANGER))
	_save_btn.disabled = state == "INVALID"

func _on_save() -> void:
	var fig: Dictionary = build_figure()
	var r: Dictionary = FigureValidator.validate(fig)
	if String(r["state"]) == "INVALID":
		_revalidate()
		return
	if _editing_id != "":
		fig["id"] = _editing_id          # editing → overwrite the original
	else:
		var base_id := String(fig["id"])
		var id := base_id
		var n := 2
		while CustomFigures.exists(id) or _builtin_has(id):
			id = "%s_%d" % [base_id, n]
			n += 1
		fig["id"] = id
	CustomFigures.add(fig)               # persist (overwrites by id)
	CustomFigures.apply_live(fig)        # update the in-memory roster now (new or edited)
	_show_saved(String(fig["name"]))

func _builtin_has(id: String) -> bool:
	for f in Roster.FIGURES:
		if String(f.get("id", "")) == id and not bool(f.get("custom", false)):
			return true
	return false

func _show_saved(figname: String) -> void:
	var ov := PanelContainer.new()
	ov.set_anchors_preset(Control.PRESET_CENTER)
	ov.add_theme_stylebox_override("panel", UITheme.panel(UITheme.SURFACE, UITheme.SUCCESS, 18, 2, 18))
	add_child(ov)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	ov.add_child(vb)
	var t := Label.new()
	t.text = "✓ ¡%s guardado!" % figname
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(t, 18, UITheme.SUCCESS, true, 800)
	vb.add_child(t)
	var sub := Label.new()
	sub.text = "Ya aparece en Colección y Mazos."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(sub, 12, UITheme.TEXT2, false, 600)
	vb.add_child(sub)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	vb.add_child(hb)
	var dex := Button.new()
	dex.text = "Ver en Colección"
	UITheme.button_font(dex, 14, UITheme.TEXT, true, 700)
	UITheme.style_primary(dex, UITheme.PRIMARY)
	dex.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/dex.tscn"))
	hb.add_child(dex)
	var again := Button.new()
	again.text = "Crear otro"
	UITheme.button_font(again, 14, UITheme.TEXT, false, 700)
	UITheme.style_surface(again)
	again.pressed.connect(func(): ov.queue_free())
	hb.add_child(again)

# ---------------------------------------------------------------- widgets
func _opt(items: Array) -> OptionButton:
	var o := OptionButton.new()
	for it in items:
		o.add_item(String(it))
	UITheme.button_font(o, 13, UITheme.TEXT, false, 600)
	return o

func _spin(lo: float, hi: float, step: float, val: int, _suffix: String) -> SpinBox:
	var sp := SpinBox.new()
	sp.min_value = lo; sp.max_value = hi; sp.step = step; sp.value = val
	sp.custom_minimum_size = Vector2(64, 0)
	return sp

func _labeled(cap: String, control: Control) -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 1)
	var l := Label.new()
	l.text = cap
	UITheme.label(l, 9, UITheme.MUTED, false, 600)
	vb.add_child(l)
	vb.add_child(control)
	return vb

func _fx_labels() -> Array:
	var out: Array = []
	for o in FX_OPTS:
		out.append(String(o["label"]))
	return out

func _fx_index(seg: Dictionary) -> int:
	var fx := String(seg.get("fx", ""))
	if fx == "":
		return 0
	for i in FX_OPTS.size():
		if String(FX_OPTS[i].get("fx", "")) == fx:
			return i
	return 0

func _fx_desc(label: String) -> String:
	return String(FX_DESC.get(label, ""))

# ---------------------------------------------------------------- scroll / info
## Touch: dragging ANYWHERE pans the form. The input controls (dropdowns, spinboxes,
## text fields) would otherwise swallow the drag, leaving only the black gaps usable.
func _input(event: InputEvent) -> void:
	if _scroll != null and event is InputEventScreenDrag:
		_scroll.scroll_vertical -= int(event.relative.y)
		get_viewport().set_input_as_handled()

## Fatter, clearly-coloured vertical scrollbar so it is easy to grab on a phone.
func _setup_scroll(scroll: ScrollContainer) -> void:
	var vbar := scroll.get_v_scroll_bar()
	vbar.custom_minimum_size.x = 18
	var grab := StyleBoxFlat.new()
	grab.bg_color = UITheme.PRIMARY_EDGE
	grab.set_corner_radius_all(9)
	grab.content_margin_left = 5
	grab.content_margin_right = 5
	vbar.add_theme_stylebox_override("grabber", grab)
	var grab_h := StyleBoxFlat.new()
	grab_h.bg_color = UITheme.PRIMARY_EDGE.lightened(0.18)
	grab_h.set_corner_radius_all(9)
	vbar.add_theme_stylebox_override("grabber_highlight", grab_h)
	vbar.add_theme_stylebox_override("grabber_pressed", grab_h)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1, 1, 1, 0.07)
	track.set_corner_radius_all(9)
	vbar.add_theme_stylebox_override("scroll", track)

## A small ⓘ info button.
func _info_btn(cb: Callable) -> Button:
	var b := Button.new()
	b.text = "ⓘ"
	b.custom_minimum_size = Vector2(34, 30)
	UITheme.button_font(b, 15, UITheme.PRIMARY_EDGE, false, 700)
	UITheme.style_surface(b)
	b.pressed.connect(cb)
	return b

## A simple modal that explains an attack colour/effect or a passive.
func _show_info(title: String, body: String) -> void:
	var old := get_node_or_null("InfoModal")
	if old:
		old.queue_free()
	var modal := Control.new()
	modal.name = "InfoModal"
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			modal.queue_free())
	modal.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.add_child(cc)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 0)
	panel.add_theme_stylebox_override("panel", UITheme.panel(UITheme.SURFACE, UITheme.PRIMARY_EDGE, 18, 2, 18))
	cc.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	var t := Label.new()
	t.text = title
	UITheme.label(t, 18, UITheme.GOLD, true, 800)
	vb.add_child(t)
	var b := Label.new()
	b.text = body
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(420, 0)
	UITheme.label(b, 14, UITheme.TEXT, false, 500)
	vb.add_child(b)
	var close := Button.new()
	close.text = "Cerrar"
	UITheme.button_font(close, 14, UITheme.TEXT, true, 700)
	UITheme.style_primary(close, UITheme.PRIMARY)
	close.pressed.connect(func(): modal.queue_free())
	vb.add_child(close)
