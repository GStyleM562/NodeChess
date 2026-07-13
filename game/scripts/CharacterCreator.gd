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
	{"label": "Dash", "fx": "Dash", "disp": "dash"},
	{"label": "Retirada", "fx": "Retirada", "disp": "retreat"},
	{"label": "Teletransporte", "fx": "Teletransporte", "disp": "teleport"},
]
# Passives that are unlocked only via Rank Up (cannot be equipped directly).
const HIDDEN_PASSIVES := ["venom_aura", "burning_aura", "loaded_dice", "phase", "kindling_resolve"]

# Help text shown by the ⓘ buttons (same order as COL_IDS).
const COL_DESC := [
	"Blanco — daño directo. Contra Oro gana el de MÁS daño; pierde con Púrpura. Si gana: K.O.",
	"Oro — daño/especial. Vence a Púrpura; contra Blanco gana el de MÁS daño. Si gana: K.O.",
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
	"Dash": "Al ganar, TÚ avanzas 1 nodo hacia el rival (ganas espacio).",
	"Retirada": "Al ganar, TÚ retrocedes 1 nodo (golpea y huye).",
	"Teletransporte": "Envía al rival a su entrada libre más cercana.",
}

# Set this static before changing to the creator scene to EDIT an existing figure
# (Dex "Modificar" does this). _ready loads it and clears it.
static var edit_figure := {}

var _scroll: ScrollContainer
var _name: LineEdit
var _desc: LineEdit
var _class: OptionButton
var _class_fx_lbl: Label          # efecto de la clase en partida (buff/debuff)
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
var _resist_boxes := {}           # status id -> toggle Button (resistencias)
var _rows: Array = []             # each: { panel, col, name, pow, stars, fx, prob }
var _rows_box: VBoxContainer
var _total_lbl: Label
var _pc_lbl: Label                # medidor "PC 95/175" (Piece Points, F1)
var _pc_bar: ProgressBar
var _pc_detail := ""              # desglose para el popup ⓘ del medidor
var _status_lbl: Label
var _status_box: PanelContainer   # banner de validación (§9.4)
var _status_icon: Label
var _status_detail := ""          # detalle completo (para el popup ⓘ)
var _status_info_btn: Button      # ⓘ "ver por qué" (solo si hay avisos/errores)
var _save_btn: Button
var _model_ids: Array = []
var _editing_id := ""             # non-empty when editing -> save overwrites it
var _edit_original := {}          # figura tal como se cargó (economía: cobrar solo el delta)
var _orig_keys := {}              # piezas ya invertidas en la original (cuentan como propias)

func _ready() -> void:
	# ANTES de construir los controles: si venimos a EDITAR, las piezas ya
	# invertidas en la figura original cuentan como propias (no se re-cobran
	# ni aparecen con candado).
	if not edit_figure.is_empty():
		_edit_original = edit_figure.duplicate(true)
		for k in _inv().required_pieces(_edit_original):
			_orig_keys[k] = true
	var bg := ColorRect.new()
	bg.color = UITheme.BG_DEEP
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_build_topbar()

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 60
	scroll.offset_bottom = -112   # deja libre el footer fijo (banner + Guardar)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_scroll = scroll
	_setup_scroll(scroll)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 14)
	pad.add_theme_constant_override("margin_right", 14)
	pad.add_theme_constant_override("margin_top", 10)
	pad.add_theme_constant_override("margin_bottom", 28)
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(pad)
	var form := VBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_theme_constant_override("separation", 18)
	pad.add_child(form)

	_build_pc_meter(form)
	_build_identity(form)
	_build_combat(form)
	_build_passives(form)
	_build_resists(form)
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
	# TU inventario de piezas completas (×N) sin salir del Creador: qué puedes
	# usar ahora mismo y cuánto tienes (crear CONSUME 1 de cada pieza usada).
	var inv_btn := Button.new()
	inv_btn.text = "📦"
	UITheme.button_font(inv_btn, 16, UITheme.GOLD, false, 700)
	UITheme.style_surface(inv_btn)
	inv_btn.custom_minimum_size = Vector2(48, 40)
	inv_btn.tooltip_text = "Tus piezas completas (se consumen al crear)"
	inv_btn.pressed.connect(_show_my_pieces)
	hb.add_child(inv_btn)
	# Import/backup: paste a share code (from "Copiar código" in the Dex) to restore
	# figures after a reinstall, or copy ONE code that backs up every saved figure.
	var imp := Button.new()
	imp.text = "⇪ Importar"
	UITheme.button_font(imp, 14, UITheme.TEXT, true, 700)
	UITheme.style_surface(imp)
	imp.custom_minimum_size = Vector2(0, 40)
	imp.pressed.connect(_show_import)
	hb.add_child(imp)

## Footer FIJO abajo: banner de validación de UNA línea (el detalle va en el
## popup ⓘ, para que NUNCA crezca y tape el botón) + botón Guardar siempre
## visible y pegado al borde inferior.
func _build_footer() -> void:
	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -108
	bar.add_theme_stylebox_override("panel", UITheme.panel(UITheme.BG, UITheme.BORDER, 0, 1, 8))
	add_child(bar)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	bar.add_child(vb)
	# Banner de validación: fondo/borde tintado + icono (§9.4). Texto de UNA
	# línea (clip); el "¿por qué?" completo se abre con ⓘ.
	_status_box = PanelContainer.new()
	_status_box.custom_minimum_size = Vector2(0, 40)
	_status_box.add_theme_stylebox_override("panel", UITheme.alert_box(UITheme.SUCCESS))
	vb.add_child(_status_box)
	var sbh := HBoxContainer.new()
	sbh.add_theme_constant_override("separation", 8)
	_status_box.add_child(sbh)
	_status_icon = Label.new()
	_status_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.label(_status_icon, 15, UITheme.SUCCESS, true, 800)
	sbh.add_child(_status_icon)
	_status_lbl = Label.new()
	_status_lbl.clip_text = true
	_status_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.label(_status_lbl, 12, UITheme.TEXT, false, 600)
	sbh.add_child(_status_lbl)
	_status_info_btn = Button.new()
	_status_info_btn.text = "ⓘ ¿por qué?"
	_status_info_btn.custom_minimum_size = Vector2(0, 30)
	_status_info_btn.visible = false
	UITheme.button_font(_status_info_btn, 11, UITheme.TEXT, true, 700)
	UITheme.style_surface(_status_info_btn, UITheme.SURFACE2, UITheme.BORDER, 8)
	_status_info_btn.pressed.connect(func(): _show_info("Estado de la figura", _status_detail))
	sbh.add_child(_status_info_btn)
	_save_btn = Button.new()
	_save_btn.text = "Guardar figura"
	_save_btn.custom_minimum_size = Vector2(0, 50)   # área táctil generosa, fija
	_save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.button_font(_save_btn, 16, UITheme.TEXT, true, 800)
	UITheme.style_primary(_save_btn, UITheme.SUCCESS)
	_save_btn.pressed.connect(_on_save)
	vb.add_child(_save_btn)

# ---------------------------------------------------------------- clase (F3)
## Descripción legible del buff/debuff EN PARTIDA de una clase (ver GameState.CLASS_FX).
func _class_fx_text(cls: String) -> String:
	match cls:
		"Balanced": return "⚖ Sin cambios de combate · +20 puntos de construcción."
		"Agile": return "🏃 +1 estamina ⚡ · pero Blanco/Oro −10 daño y Púrpura −1★."
		"Tank": return "🛡 Azul indestructible + resiste Debilitado · pero −1 estamina."
		"Striker": return "⚔ Blanco/Oro +15 daño · pero −1 estamina."
		"Debuffer": return "☠ Púrpura +1★ y sus estados duran +2 turnos · pero Blanco/Oro −15."
		"Buffer": return "✨ +1 energía por turno al equipo · pero Blanco/Oro −10 y −1 estamina."
		"Controller": return "🌀 Desplazamientos +1 nodo e inmune a ser desplazado · pero Blanco/Oro −10. (+5 PC)"
		"Specialist": return "🔧 Sin cambios de combate · +30 PC, pero NO hereda pasivas ocultas del modelo."
	return ""

# ---------------------------------------------------------------- PC meter (F1)
## Medidor de PUNTOS DE CONSTRUCCIÓN: barra + "usado / presupuesto" + ⓘ desglose.
## Se actualiza en cada _revalidate. El presupuesto sube con rareza/clase/evolución.
func _build_pc_meter(form: VBoxContainer) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.group_panel(16, 12))
	form.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	p.add_child(vb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vb.add_child(row)
	var t := Label.new()
	t.text = "🔧 PUNTOS DE CONSTRUCCIÓN"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UITheme.label(t, 13, UITheme.SECTION, true, 700)
	row.add_child(t)
	_pc_lbl = Label.new()
	_pc_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UITheme.label(_pc_lbl, 15, UITheme.SUCCESS, true, 800)
	row.add_child(_pc_lbl)
	var info := Button.new()
	info.text = "ⓘ"
	info.custom_minimum_size = Vector2(34, 30)
	UITheme.button_font(info, 14, UITheme.PRIMARY_EDGE, false, 700)
	UITheme.style_surface(info, UITheme.SURFACE2, UITheme.BORDER, 8)
	info.pressed.connect(func(): _show_info("Puntos de Construcción", _pc_detail))
	row.add_child(info)
	_pc_bar = ProgressBar.new()
	_pc_bar.custom_minimum_size = Vector2(0, 10)
	_pc_bar.show_percentage = false
	var pbg := StyleBoxFlat.new(); pbg.bg_color = Color(0.10, 0.13, 0.22); pbg.set_corner_radius_all(5)
	_pc_bar.add_theme_stylebox_override("background", pbg)
	vb.add_child(_pc_bar)
	var hint := Label.new()
	hint.text = "Cada stat cuesta PC. Tu presupuesto sube con la RAREZA, la CLASE y si marcas «Evoluciona». Mejores piezas → figuras más potentes."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.label(hint, 11, UITheme.MUTED, false, 500)
	vb.add_child(hint)

## Pinta el medidor y devuelve true si la build CABE en su presupuesto.
func _update_pc_meter(fig: Dictionary) -> bool:
	var c := PiecePoints.cost(fig)
	var b := PiecePoints.budget(fig)
	var fits := c <= b
	if _pc_lbl != null:
		_pc_lbl.text = "%d / %d" % [c, b]
		_pc_lbl.add_theme_color_override("font_color", UITheme.SUCCESS if fits else UITheme.DANGER)
	if _pc_bar != null:
		_pc_bar.max_value = maxf(1.0, float(maxi(b, c)))
		_pc_bar.value = c
		var fill := StyleBoxFlat.new()
		fill.bg_color = UITheme.SUCCESS if fits else UITheme.DANGER
		fill.set_corner_radius_all(5)
		_pc_bar.add_theme_stylebox_override("fill", fill)
	var lines: Array = PiecePoints.breakdown(fig)
	lines.append("——")
	lines.append("Presupuesto: %d  (rareza %s%s%s)" % [b, String(fig.get("rarity", "common")),
		("  + clase" if int(PiecePoints.CLASS_PC.get(String(fig.get("class", "")), 0)) > 0 else ""),
		("  ×1.30 evolución" if bool(fig.get("is_evolution", false)) else "")])
	lines.append("Usado: %d" % c)
	lines.append("✓ CABE — te sobran %d PC" % (b - c) if fits else "✗ TE PASAS por %d PC — sube la rareza, cambia la clase, o quita/baja stats" % (c - b))
	_pc_detail = "\n".join(lines)
	return fits

# ---------------------------------------------------------------- sections
func _section(parent: VBoxContainer, title: String) -> VBoxContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.group_panel(16, 14))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	p.add_child(vb)
	var t := Label.new()
	t.text = title
	UITheme.label(t, 16, UITheme.SECTION, true, 800)   # título de sección Sora 800 (§4.7)
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
	_style_le(_name)
	_name.text_changed.connect(func(_t): _revalidate())
	_field(s, "Nombre", _name)
	_desc = LineEdit.new()
	_desc.placeholder_text = "Descripción corta"
	_style_le(_desc)
	_field(s, "Descripción", _desc)
	_class = _opt(CLASSES)
	var clkeys: Array = []
	for c in CLASSES:
		clkeys.append("class:" + String(c))
	_lock_items(_class, clkeys)   # las clases también son piezas del inventario
	_class.item_selected.connect(func(_i):
		_class_fx_lbl.text = _class_fx_text(CLASSES[_class.selected])
		_revalidate())
	_field(s, "Clase", _class)
	# efecto de la clase EN PARTIDA (buff/debuff) — para que el trueque sea claro
	_class_fx_lbl = Label.new()
	_class_fx_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.label(_class_fx_lbl, 11, UITheme.GOLD, false, 600)
	_class_fx_lbl.text = _class_fx_text(CLASSES[_class.selected])
	s.add_child(_class_fx_lbl)
	_rarity = _opt(RARITY_ES)
	_rarity.select(2)   # Épica by default
	var rkeys: Array = []
	for r in RARITIES:
		rkeys.append("rarity:" + String(r))
	_lock_items(_rarity, rkeys)
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
	var tkeys: Array = []
	for t in TYPES:
		tkeys.append("atype:" + String(t))
	_lock_items(_type, tkeys)
	_field(s, "Tipo ataque", _type)
	# placeholder model (borrow an existing figure until a real GLB is added)
	_model_ids = []
	var names: Array = []
	for f in Roster.FIGURES:
		if not bool(f.get("custom", false)):
			_model_ids.append(String(f.get("id", "")))
			names.append(String(f.get("name", "?")))
	_model = _opt(names)
	var mkeys: Array = []
	for mid in _model_ids:
		mkeys.append("model:" + String(mid))
	_lock_items(_model, mkeys)
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
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	s.add_child(grid)
	for pid in Roster.PASSIVES.keys():
		if pid in HIDDEN_PASSIVES:
			continue
		var pname := String(Roster.PASSIVES[pid].get("name", pid))
		var pdesc := String(Roster.PASSIVES[pid].get("desc", ""))
		var item := HBoxContainer.new()
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL   # la celda llena su columna
		item.add_theme_constant_override("separation", 4)
		# A toggle button reads clearly as "selectable" (fills with accent when ON).
		var tg := Button.new()
		tg.toggle_mode = true
		tg.text = pname
		tg.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tg.clip_text = true
		tg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tg.custom_minimum_size = Vector2(96, 38)   # ancho mínimo para que se lea el nombre
		tg.tooltip_text = pdesc
		_style_toggle(tg)
		tg.toggled.connect(func(_p): _revalidate())
		if not _inv().is_admin() and not _piece_ok("passive:" + String(pid)):
			tg.disabled = true
			tg.text = "🔒 " + pname
		item.add_child(tg)
		item.add_child(_info_btn(func(): _show_info(pname, pdesc)))
		grid.add_child(item)
		_passive_boxes[pid] = tg

## Resistencias a estados (GDD): la figura es INMUNE a los elegidos (máx. 2).
func _build_resists(form: VBoxContainer) -> void:
	var s := _section(form, "Resistencias a estados (máx. 2)")
	var hint := Label.new()
	hint.text = "Los estados elegidos NUNCA se le aplican a esta figura."
	UITheme.label(hint, 11, UITheme.MUTED, false, 500)
	s.add_child(hint)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	s.add_child(grid)
	for label in GameState.FX_STATUS.keys():
		var sid := String(GameState.FX_STATUS[label])
		var lbl_txt := String(label)
		var desc := _fx_desc(lbl_txt)   # descripción REAL del estado (§9.2)
		var item := HBoxContainer.new()
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL   # la celda llena su columna
		item.add_theme_constant_override("separation", 4)
		var tg := Button.new()
		tg.toggle_mode = true
		tg.text = lbl_txt
		tg.clip_text = true
		tg.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tg.custom_minimum_size = Vector2(88, 36)   # ancho mínimo para que se lea el estado
		tg.tooltip_text = desc
		_style_toggle(tg)
		tg.toggled.connect(func(_p): _revalidate())
		if not _inv().is_admin() and not _piece_ok("resist:" + sid):
			tg.disabled = true
			tg.text = "🔒 " + lbl_txt
		item.add_child(tg)
		item.add_child(_info_btn(func(): _show_info("Resiste: " + lbl_txt, desc)))
		grid.add_child(item)
		_resist_boxes[sid] = tg

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
	p.add_theme_stylebox_override("panel", UITheme.panel(UITheme.SURFACE2, UITheme.BORDER, 12, 1, 10))
	_rows_box.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 7)
	p.add_child(vb)

	var line1 := HBoxContainer.new()
	line1.add_theme_constant_override("separation", 6)
	vb.add_child(line1)
	var col := _opt(COL_ES)
	col.select(COL_IDS.find(String(seg.get("col", "white"))))
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.item_selected.connect(func(_i): _revalidate())
	var ckeys: Array = []
	for cid in COL_IDS:
		ckeys.append("color:" + String(cid))
	_lock_items(col, ckeys)
	line1.add_child(col)
	var nm := LineEdit.new()
	nm.placeholder_text = "Nombre ataque"
	nm.text = String(seg.get("name", ""))
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_le(nm)
	line1.add_child(nm)

	var line2 := HBoxContainer.new()
	line2.add_theme_constant_override("separation", 6)
	vb.add_child(line2)
	# DAÑO 0–100 de 5 en 5 (pieza pow:N, solo la consumen Blanco/Oro) y
	# PROBABILIDAD 5–70% de 5 en 5 (pieza prob:N, la consume todo segmento).
	var pw := _spin(0, 100, 5, int(seg.get("pow", 0)), "Daño")
	var st := _spin(1, 3, 1, int(seg.get("stars", 1)), "★")
	var fx := _opt(_fx_labels())
	fx.select(_fx_index(seg))
	fx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fkeys: Array = []
	for o in FX_OPTS:
		var f := String(o.get("fx", ""))
		fkeys.append(("fx:" + f) if f != "" else "")   # "Ninguno" siempre permitido
	var prob := _spin(5, 70, 5, int(seg.get("w", 10)), "%")
	_lock_items(fx, fkeys)
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
	var resists: Array = []
	for sid in _resist_boxes.keys():
		if _resist_boxes[sid].button_pressed:
			resists.append(sid)
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
		"passives": passives, "resists": resists, "model_ref": model_ref,
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
	var ekeys: Array = []
	for eid in _evo_fig_ids:
		# custom = sin pieza (permitida); integrada = requiere su pieza de figura
		ekeys.append(("model:" + String(eid)) if _inv()._is_builtin(String(eid)) else "")
	for i in n:
		var opt := _opt(_evo_names)
		opt.item_selected.connect(func(_i): _revalidate())
		_lock_items(opt, ekeys)
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
	var rl: Array = fig.get("resists", [])
	for sid in _resist_boxes.keys():
		_resist_boxes[sid].button_pressed = sid in rl
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
		"resists": p.get("resists", []),
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
	# MODO USUARIO: solo puede guardar con piezas de su inventario (regla dura).
	var missing: Array = _inv().missing_pieces_for(fig, _edit_original)
	if not missing.is_empty():
		var names: Array = []
		for key in missing:
			names.append(_inv().piece_name(String(key)))
		msgs.push_front("🔒 Te falta: " + ", ".join(names) + " — consíguelo en 🎁 Cajas")
	# AVISO de evolución: si el personaje al que EVOLUCIONA ya trae una
	# resistencia/pasiva que elegiste, se la estás poniendo de más (la tendrá
	# igual al evolucionar). Solo INFORMA — el jugador decide si continúa.
	if _evolve.button_pressed:
		for opt in _phase_opts:
			var sel := int(opt.selected)
			if sel < 0 or sel >= _evo_fig_ids.size():
				continue
			var tgt: Dictionary = _figure_by_id(String(_evo_fig_ids[sel]))
			if tgt.is_empty():
				continue
			var tn := String(tgt.get("name", "?"))
			for sid in fig.get("resists", []):
				if String(sid) in (tgt.get("resists", []) as Array):
					msgs.append("⚠ «%s» ya tiene la resistencia «%s» — la tendrá al evolucionar" % [tn, _inv().piece_name("resist:" + String(sid)).trim_prefix("Resistencia ")])
			for pid in fig.get("passives", []):
				if String(pid) in (tgt.get("passives", []) as Array):
					msgs.append("⚠ «%s» ya tiene la pasiva «%s»" % [tn, String(Roster.PASSIVES.get(pid, {}).get("name", pid))])

	# PUNTOS DE CONSTRUCCIÓN (F1 medidor + F2 candado): pasarse de presupuesto
	# BLOQUEA el guardado en modo usuario (admin puede, es herramienta de dev).
	var pc_fits := _update_pc_meter(fig)
	var pc_blocks: bool = not pc_fits and not bool(_inv().is_admin())
	if pc_blocks:
		msgs.push_front("🔧 Te pasas de Puntos de Construcción (%d/%d). Sube la rareza, cambia la clase o baja stats." % [PiecePoints.cost(fig), PiecePoints.budget(fig)])

	var bad := state == "INVALID" or not missing.is_empty() or pc_blocks
	# RESUMEN de UNA línea para el banner (nunca crece → no tapa Guardar).
	var head := ""
	if pc_blocks:
		head = "🔧 PC %d/%d — te pasas" % [PiecePoints.cost(fig), PiecePoints.budget(fig)]
	elif not missing.is_empty():
		head = "🔒 Te faltan %d pieza(s)" % missing.size()
	elif state == "INVALID":
		head = "✗ Inválido: %d error(es)" % (r["errors"] as Array).size()
	elif not msgs.is_empty():
		head = "⚠ Válido con %d aviso(s) — PC %d/%d" % [msgs.size(), PiecePoints.cost(fig), PiecePoints.budget(fig)]
	else:
		head = "✓ Válido — PC %d/%d" % [PiecePoints.cost(fig), PiecePoints.budget(fig)]
	_status_lbl.text = head
	# DETALLE completo (para el popup ⓘ, y solo si hay algo que explicar).
	_status_detail = ("\n".join(msgs)) if not msgs.is_empty() else "Todo en orden. Puedes guardar la figura."
	if _status_info_btn != null:
		_status_info_btn.visible = not msgs.is_empty()
	# Banner tintado por estado (§9.4): rojo inválido/faltante · oro avisos · verde ok.
	var tint: Color = UITheme.DANGER if bad else (UITheme.SUCCESS if state == "VALID" else UITheme.GOLD)
	_status_box.add_theme_stylebox_override("panel", UITheme.alert_box(tint))
	_status_icon.text = "⚠" if bad else ("✓" if state == "VALID" else "⚠")
	_status_icon.add_theme_color_override("font_color", tint)
	_status_lbl.add_theme_color_override("font_color", tint if bad else UITheme.TEXT)
	# CANDADO DURO: jamás se puede guardar una build inválida o sin piezas.
	_save_btn.disabled = bad
	_save_btn.text = "Guardar figura" if not bad else "🔒 Corrige para guardar"

func _on_save() -> void:
	var fig: Dictionary = build_figure()
	var r: Dictionary = FigureValidator.validate(fig)
	var pc_blocks: bool = not PiecePoints.fits(fig) and not bool(_inv().is_admin())
	if String(r["state"]) == "INVALID" or not _inv().missing_pieces_for(fig, _edit_original).is_empty() or pc_blocks:
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
	# ECONOMÍA (modo usuario): crear GASTA las piezas; editar cobra solo las
	# nuevas y devuelve las retiradas. La base para diffs pasa a ser lo guardado.
	if _edit_original.is_empty():
		_inv().consume_for(fig)
	else:
		_inv().adjust_for_edit(_edit_original, fig)
	_edit_original = fig.duplicate(true)
	_orig_keys.clear()
	for k in _inv().required_pieces(_edit_original):
		_orig_keys[k] = true
	if _editing_id == "":
		_editing_id = String(fig["id"])   # siguientes guardados = edición de ESTA figura
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

# ---------------------------------------------------------------- inventario
## Autoload Inventory resuelto por nodo: Inventory.gd usa las constantes de esta
## clase, así que nombrarlo aquí como identificador crearía un ciclo de compilación.
func _inv() -> Node:
	return get_node("/root/Inventory")

## ¿La pieza está disponible? (en inventario, o ya invertida en la figura original)
func _piece_ok(key: String) -> bool:
	return _inv().has_piece(key) or _orig_keys.has(key)

## 🔒 modo usuario: deshabilita las opciones cuya pieza no está en el inventario
## (keys[i] = pieza de la opción i; "" = siempre permitida).
func _lock_items(opt: OptionButton, keys: Array) -> void:
	if _inv().is_admin():
		return
	for i in mini(opt.item_count, keys.size()):
		var key := String(keys[i])
		if key != "" and not _piece_ok(key):
			opt.set_item_disabled(i, true)
			opt.set_item_text(i, "🔒 " + opt.get_item_text(i))

# ---------------------------------------------------------------- widgets
func _opt(items: Array) -> OptionButton:
	var o := OptionButton.new()
	for it in items:
		o.add_item(String(it))
	UITheme.button_font(o, 13, UITheme.TEXT, false, 600)
	o.add_theme_stylebox_override("normal", UITheme.input())
	o.add_theme_stylebox_override("hover", UITheme.input(UITheme.INPUT_BG, UITheme.PRIMARY))
	o.add_theme_stylebox_override("pressed", UITheme.input(UITheme.INPUT_BG, UITheme.PRIMARY))
	o.add_theme_stylebox_override("disabled", UITheme.input(UITheme.INPUT_BG.darkened(0.2), UITheme.BORDER.darkened(0.2)))
	return o

## Estilo de campo de texto (input bg, borde, foco azul, fuente Manrope).
func _style_le(e: LineEdit) -> void:
	e.custom_minimum_size = Vector2(0, 40)
	e.add_theme_stylebox_override("normal", UITheme.input())
	e.add_theme_stylebox_override("focus", UITheme.input(UITheme.INPUT_BG, UITheme.PRIMARY))
	e.add_theme_color_override("font_color", UITheme.TEXT)
	e.add_theme_color_override("font_placeholder_color", UITheme.MUTED)
	e.add_theme_color_override("caret_color", UITheme.PRIMARY_EDGE)
	var mf := UITheme.body(600)
	if mf != null:
		e.add_theme_font_override("font", mf)

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
## Solo secuestra arrastres VERTICALES dominantes: los gestos horizontales (sliders,
## spinboxes) siguen llegando a sus controles y el scroll ya no "pelea" con ellos.
func _input(event: InputEvent) -> void:
	if _scroll != null and event is InputEventScreenDrag:
		var d := (event as InputEventScreenDrag).relative
		if absf(d.y) > absf(d.x):
			_scroll.scroll_vertical -= int(d.y)
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

## Import/backup modal: paste a code and import it, or copy a full-backup code.
func _show_import() -> void:
	var old := get_node_or_null("ImportModal")
	if old:
		old.queue_free()
	var modal := Control.new()
	modal.name = "ImportModal"
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.add_child(cc)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 0)
	panel.add_theme_stylebox_override("panel", UITheme.panel(UITheme.SURFACE, UITheme.PRIMARY_EDGE, 18, 2, 18))
	cc.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	var t := Label.new()
	t.text = "Importar / Respaldo de personajes"
	UITheme.label(t, 18, UITheme.GOLD, true, 800)
	vb.add_child(t)
	var hint := Label.new()
	hint.text = "Pega aquí un código (NCFIG1… de un personaje, o NCPACK1… de un respaldo completo) y toca IMPORTAR."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(440, 0)
	UITheme.label(hint, 12, UITheme.TEXT2, false, 600)
	vb.add_child(hint)
	var code_in := TextEdit.new()
	code_in.placeholder_text = "NCFIG1.…  /  NCPACK1.…"
	code_in.custom_minimum_size = Vector2(440, 110)
	code_in.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	vb.add_child(code_in)
	var result := Label.new()
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.custom_minimum_size = Vector2(440, 0)
	UITheme.label(result, 13, UITheme.TEXT2, false, 700)
	vb.add_child(result)
	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	vb.add_child(row1)
	var paste := Button.new()
	paste.text = "Pegar"
	paste.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.button_font(paste, 14, UITheme.TEXT, false, 700)
	UITheme.style_surface(paste)
	paste.pressed.connect(func(): code_in.text = DisplayServer.clipboard_get())
	row1.add_child(paste)
	var do_imp := Button.new()
	do_imp.text = "IMPORTAR"
	do_imp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.button_font(do_imp, 14, UITheme.TEXT, true, 800)
	UITheme.style_primary(do_imp, UITheme.SUCCESS)
	do_imp.pressed.connect(func():
		var r: Dictionary = CustomFigures.import_code(code_in.text)
		if bool(r["ok"]):
			var extra: String = ("  (%d inválidos omitidos)" % int(r["skipped"])) if int(r["skipped"]) > 0 else ""
			result.text = "✓ Importado: " + ", ".join(r["names"]) + extra + ". Ya aparecen en Colección y Mazos."
			result.add_theme_color_override("font_color", UITheme.SUCCESS)
		else:
			result.text = "✗ " + String(r["error"])
			result.add_theme_color_override("font_color", UITheme.DANGER))
	row1.add_child(do_imp)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 8)
	vb.add_child(row2)
	var backup := Button.new()
	backup.text = "⧉ Copiar TODOS (respaldo)"
	backup.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.button_font(backup, 14, UITheme.TEXT, false, 700)
	UITheme.style_surface(backup)
	backup.pressed.connect(func():
		if CustomFigures.load_all().is_empty():
			result.text = "No hay personajes guardados que respaldar."
			result.add_theme_color_override("font_color", UITheme.GOLD)
		else:
			DisplayServer.clipboard_set(CustomFigures.export_all_code())
			result.text = "✓ Respaldo copiado al portapapeles. Guárdalo (notas, chat) y cuando reinstales pégalo aquí."
			result.add_theme_color_override("font_color", UITheme.SUCCESS))
	row2.add_child(backup)
	var close := Button.new()
	close.text = "Cerrar"
	UITheme.button_font(close, 14, UITheme.TEXT, false, 700)
	UITheme.style_surface(close)
	close.pressed.connect(func(): modal.queue_free())
	row2.add_child(close)

## TU INVENTARIO dentro del Creador: piezas completas que posees (×N), agrupadas.
## Solo lectura — para convertir fragmentos ve a la pantalla Inventario.
func _show_my_pieces() -> void:
	var old := get_node_or_null("MyPiecesModal")
	if old:
		old.queue_free()
	var modal := Control.new()
	modal.name = "MyPiecesModal"
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.66)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			modal.queue_free())
	modal.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.add_child(cc)
	var panel := PanelContainer.new()
	var pw: float = minf(470.0, get_viewport().get_visible_rect().size.x - 24.0)
	panel.custom_minimum_size = Vector2(pw, 0)
	panel.add_theme_stylebox_override("panel", UITheme.info_popup_box())
	cc.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	var t := Label.new()
	t.text = "📦 Tus piezas completas"
	UITheme.label(t, 18, UITheme.GOLD, true, 800)
	vb.add_child(t)
	var hint := Label.new()
	hint.text = ("Modo ADMIN: todo ilimitado." if _inv().is_admin() else
		"Crear un personaje CONSUME 1 de cada pieza usada. Editar cobra solo lo nuevo y devuelve lo retirado.")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(pw - 40.0, 0)
	UITheme.label(hint, 12, UITheme.TEXT2, false, 600)
	vb.add_child(hint)
	# lista scrolleable de piezas POSEÍDAS con su conteo
	var scr := ScrollContainer.new()
	scr.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scr.custom_minimum_size = Vector2(pw - 40.0, minf(get_viewport().get_visible_rect().size.y * 0.5, 460.0))
	vb.add_child(scr)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scr.add_child(list)
	var groups := [["model:", "FIGURAS"], ["rarity:", "RAREZAS"], ["class:", "CLASES"],
		["atype:", "TIPOS DE ATAQUE"], ["color:", "ATAQUES (COLORES)"],
		["pow:", "DAÑOS (blanco/oro)"], ["stars:", "ESTRELLAS (púrpura)"],
		["prob:", "PROBABILIDADES"], ["fx:", "ESTADOS"], ["passive:", "PASIVAS"],
		["stamina:", "ESTAMINA"], ["resist:", "RESISTENCIAS"]]
	var any := false
	for g in groups:
		var rows: Array = []
		for key in _inv().catalog():
			if not String(key).begins_with(String(g[0])):
				continue
			var n: int = int(_inv().pieces.get(String(key), 0))
			if _inv().is_admin() or n > 0:
				rows.append([String(key), n])
		if rows.is_empty():
			continue
		any = true
		var gh := Label.new()
		UITheme.section(gh, String(g[1]))
		list.add_child(gh)
		for r in rows:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var nm := Label.new()
			nm.text = String(_inv().piece_name(String(r[0])))
			nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			UITheme.label(nm, 13, UITheme.TEXT, false, 600)
			row.add_child(nm)
			var ct := Label.new()
			ct.text = "∞" if _inv().is_admin() else "×%d" % int(r[1])
			UITheme.label(ct, 13, UITheme.SUCCESS, true, 700)
			row.add_child(ct)
			list.add_child(row)
	if not any:
		var empty := Label.new()
		empty.text = "Aún no tienes piezas completas.\nConvierte fragmentos (10 = 1 pieza) en el Inventario, o abre cofres en el menú."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size = Vector2(pw - 40.0, 0)
		UITheme.label(empty, 13, UITheme.MUTED, false, 600)
		list.add_child(empty)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 8)
	vb.add_child(row2)
	var goinv := Button.new()
	goinv.text = "📦 Ir al Inventario"
	goinv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goinv.custom_minimum_size = Vector2(0, 44)
	UITheme.button_font(goinv, 14, UITheme.TEXT, true, 700)
	UITheme.style_surface(goinv)
	goinv.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/inventory.tscn"))
	row2.add_child(goinv)
	var close := Button.new()
	close.text = "Cerrar"
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close.custom_minimum_size = Vector2(0, 44)
	UITheme.button_font(close, 14, UITheme.TEXT, true, 700)
	UITheme.style_primary(close, UITheme.PRIMARY)
	close.pressed.connect(func(): modal.queue_free())
	row2.add_child(close)

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
