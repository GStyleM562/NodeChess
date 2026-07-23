extends RefCounted
class_name UITheme
## Central design tokens (Claude Design handoff). Colors, fonts (Sora display +
## Manrope body) and StyleBox factories. Used across every UI script so the look is
## consistent. Pure presentation — no game logic.

# --- palette (DINÁMICA: claro "Juicy Hall" / oscuro) -----------------------
# 2026-07-21: la paleta pasa de const a `static var` para soportar DOS temas en
# runtime sin tocar las pantallas (siguen leyendo UITheme.BG/SURFACE/TEXT…).
# El tema activo lo fija `apply_theme(dark)` (lo llama Settings al arrancar y al
# togglear). Claro = TCG Pocket cálido; Oscuro = navy suave (no negro puro),
# fácil para la vista. Ver docs/UIUX_Juicy_Hall.md.
static var BG := Color(0.976, 0.937, 0.76)
static var BG_DEEP := Color(0.972, 0.925, 0.72)
static var SURFACE := Color(1.0, 0.985, 0.94)
static var SURFACE2 := Color(0.984, 0.955, 0.885)
static var BORDER := Color(0.85, 0.77, 0.58)
static var PRIMARY := Color(0.18, 0.42, 1.0)
static var PRIMARY_EDGE := Color(0.14, 0.36, 0.86)
static var ORANGE := Color(0.93, 0.45, 0.12)
static var GOLD := Color(0.93, 0.65, 0.05)
static var SUCCESS := Color(0.10, 0.60, 0.33)
static var DANGER := Color(0.86, 0.20, 0.18)
static var ENERGY := Color(0.07, 0.55, 0.80)
static var TEXT := Color(0.24, 0.21, 0.13)
static var TEXT2 := Color(0.45, 0.41, 0.32)
static var MUTED := Color(0.58, 0.53, 0.43)
## SKY = lavado de fondo de acento del Home (amarillo claro / índigo oscuro).
static var SKY := Color(1.0, 0.83, 0.30)
static var dark := false   # tema oscuro activo

## Aplica el tema (lo llama Settings). Reescribe TODOS los tokens (incluidos los
## derivados de más abajo) para que las pantallas nuevas los tomen ya cambiados.
static func apply_theme(is_dark: bool) -> void:
	dark = is_dark
	if is_dark:
		BG = Color(0.086, 0.098, 0.137)         # navy screen
		BG_DEEP = Color(0.063, 0.071, 0.106)     # navy más hondo (fondo raíz/3D)
		SURFACE = Color(0.129, 0.145, 0.196)     # tarjeta
		SURFACE2 = Color(0.169, 0.188, 0.251)    # botón secundario
		BORDER = Color(0.243, 0.278, 0.376)      # borde/labio
		PRIMARY = Color(0.30, 0.55, 1.0)
		PRIMARY_EDGE = Color(0.45, 0.66, 1.0)
		ORANGE = Color(1.0, 0.58, 0.28)
		GOLD = Color(1.0, 0.80, 0.30)
		SUCCESS = Color(0.30, 0.82, 0.52)
		DANGER = Color(1.0, 0.45, 0.42)
		ENERGY = Color(0.36, 0.78, 0.98)
		TEXT = Color(0.90, 0.92, 0.98)
		TEXT2 = Color(0.66, 0.70, 0.82)
		MUTED = Color(0.47, 0.52, 0.64)
		SKY = Color(0.20, 0.24, 0.42)
		R_COMMON = Color(0.55, 0.60, 0.70)
		R_RARE = Color(0.40, 0.62, 1.0)
		R_EPIC = Color(0.72, 0.50, 1.0)
		R_LEGEND = Color(1.0, 0.80, 0.30)
		PANEL_DEEP = Color(0.106, 0.122, 0.169)
		INPUT_BG = Color(0.075, 0.086, 0.125)
		GROUP_BORDER = Color(0.204, 0.235, 0.322)
	else:
		BG = Color(0.976, 0.937, 0.76)
		BG_DEEP = Color(0.972, 0.925, 0.72)
		SURFACE = Color(1.0, 0.985, 0.94)
		SURFACE2 = Color(0.984, 0.955, 0.885)
		BORDER = Color(0.85, 0.77, 0.58)
		PRIMARY = Color(0.18, 0.42, 1.0)
		PRIMARY_EDGE = Color(0.14, 0.36, 0.86)
		ORANGE = Color(0.93, 0.45, 0.12)
		GOLD = Color(0.93, 0.65, 0.05)
		SUCCESS = Color(0.10, 0.60, 0.33)
		DANGER = Color(0.86, 0.20, 0.18)
		ENERGY = Color(0.07, 0.55, 0.80)
		TEXT = Color(0.24, 0.21, 0.13)
		TEXT2 = Color(0.45, 0.41, 0.32)
		MUTED = Color(0.58, 0.53, 0.43)
		SKY = Color(1.0, 0.83, 0.30)
		R_COMMON = Color(0.47, 0.49, 0.55)
		R_RARE = Color(0.16, 0.42, 0.95)
		R_EPIC = Color(0.55, 0.28, 0.85)
		R_LEGEND = Color(0.93, 0.60, 0.05)
		PANEL_DEEP = Color(0.968, 0.93, 0.845)
		INPUT_BG = Color(1.0, 1.0, 0.985)
		GROUP_BORDER = Color(0.88, 0.815, 0.66)
	SECTION = PRIMARY_EDGE

static var R_COMMON := Color(0.47, 0.49, 0.55)
static var R_RARE := Color(0.16, 0.42, 0.95)
static var R_EPIC := Color(0.55, 0.28, 0.85)
static var R_LEGEND := Color(0.93, 0.60, 0.05)

# --- fonts -----------------------------------------------------------------
static var _sora: Font
static var _manrope: Font
static var _cache := {}

static func _ensure() -> void:
	if _sora == null and ResourceLoader.exists("res://assets/fonts/Sora.ttf"):
		_sora = load("res://assets/fonts/Sora.ttf")
	if _manrope == null and ResourceLoader.exists("res://assets/fonts/Manrope.ttf"):
		_manrope = load("res://assets/fonts/Manrope.ttf")

static func _weighted(base: Font, weight: int) -> Font:
	if base == null:
		return null
	var key := str(base.get_instance_id()) + ":" + str(weight)
	if _cache.has(key):
		return _cache[key]
	var fv := FontVariation.new()
	fv.base_font = base
	fv.variation_opentype = {"wght": weight}
	_cache[key] = fv
	return fv

static func display(weight := 800) -> Font:
	_ensure()
	return _weighted(_sora, weight)

static func body(weight := 500) -> Font:
	_ensure()
	return _weighted(_manrope, weight)

## Style a Label: size + colour + (display=title font Sora, else body Manrope).
static func label(l: Label, size: int, col: Color, title := false, weight := -1) -> void:
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.modulate = Color.WHITE
	var w := weight if weight > 0 else (800 if title else 500)
	var f := display(w) if title else body(w)
	if f != null:
		l.add_theme_font_override("font", f)

static func button_font(b: Button, size: int, col := TEXT, title := true, weight := 700) -> void:
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", col)
	b.add_theme_color_override("font_hover_color", col)
	b.add_theme_color_override("font_pressed_color", col.darkened(0.1))
	# deshabilitado = mismo color al 45% (el default de Godot era blanco lavado:
	# ilegible sobre las tarjetas crema del tema claro)
	b.add_theme_color_override("font_disabled_color", Color(col.r, col.g, col.b, 0.45))
	var f := display(weight) if title else body(weight)
	if f != null:
		b.add_theme_font_override("font", f)
	# TODOS los botones pasan por aquí: un solo enganche da el click de UI global.
	# (resuelto por nodo, sin depender del autoload en tiempo de compilación)
	if not b.pressed.is_connected(_ui_click):
		b.pressed.connect(_ui_click)

static func _ui_click() -> void:
	var ml := Engine.get_main_loop()
	if ml is SceneTree:
		var s := (ml as SceneTree).root.get_node_or_null("Sfx")
		if s != null:
			s.call("play", "ui_click")

# --- styleboxes ------------------------------------------------------------
## Sombra CÁLIDA estándar del tema claro (nunca negra dura).
static func _warm_shadow(sb: StyleBoxFlat, size := 6, dy := 3) -> void:
	sb.shadow_color = Color(0.45, 0.34, 0.06, 0.16)
	sb.shadow_size = size
	sb.shadow_offset = Vector2(0, dy)

## Panel/tarjeta: crema con LABIO inferior 3D (borde grueso abajo, fino a los
## lados) tintado con `border` — la regla №1 del tema Juicy Hall.
static func panel(bg := SURFACE, border := BORDER, radius := 16, bw := 2, pad := 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.border_color = border
	sb.border_width_left = bw
	sb.border_width_right = bw
	sb.border_width_top = bw
	sb.border_width_bottom = bw + 4
	sb.set_content_margin_all(pad)
	sb.content_margin_bottom = pad + 3
	_warm_shadow(sb)
	return sb

static func pill(bg := SURFACE2, border := BORDER, pad := 8) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(999)
	sb.set_border_width_all(1)
	sb.border_width_bottom = 3
	sb.border_color = border
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = 4
	sb.content_margin_bottom = 5
	return sb

## Botón primario EXTRUIDO: cara de color + labio inferior oscuro grueso.
static func primary(accent := PRIMARY, radius := 16) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = accent
	sb.set_corner_radius_all(radius)
	sb.border_color = accent.darkened(0.32)
	sb.border_width_bottom = 6
	sb.set_content_margin_all(8)
	sb.content_margin_bottom = 10
	_warm_shadow(sb, 6, 3)
	return sb

## Apply the juicy look (normal/hover/pressed) to a button. Al PRESIONAR, el
## labio se encoge y la cara baja — botón físico.
static func style_primary(b: Button, accent := PRIMARY, radius := 16) -> void:
	b.add_theme_stylebox_override("normal", primary(accent, radius))
	b.add_theme_stylebox_override("hover", primary(accent.lightened(0.05), radius))
	var pr := primary(accent.darkened(0.10), radius)
	pr.border_width_bottom = 2
	pr.content_margin_top = 12
	pr.content_margin_bottom = 4
	pr.shadow_size = 2
	pr.shadow_offset = Vector2(0, 1)
	b.add_theme_stylebox_override("pressed", pr)

## Apply a flat surface look (normal/hover/pressed) to a secondary button.
static func style_surface(b: Button, bg := SURFACE, border := BORDER, radius := 14) -> void:
	b.add_theme_stylebox_override("normal", panel(bg, border, radius, 1, 8))
	b.add_theme_stylebox_override("hover", panel(bg, PRIMARY, radius, 1, 8))
	var pr := panel(bg.darkened(0.05), border, radius, 1, 8)
	pr.border_width_bottom = 1
	pr.content_margin_top = 11
	pr.content_margin_bottom = 5
	b.add_theme_stylebox_override("pressed", pr)
	b.add_theme_stylebox_override("disabled", panel(bg.darkened(0.08), border.lightened(0.1), radius, 1, 8))

# ---- NUEVO (rediseño menús · handoff Part 6, en clave JUICY HALL) ---------
static var SECTION := PRIMARY_EDGE                  # azul de encabezados de sección
static var PANEL_DEEP := Color(0.968, 0.93, 0.845) # panel agrupador
static var INPUT_BG := Color(1.0, 1.0, 0.985)      # campos de formulario
static var GROUP_BORDER := Color(0.88, 0.815, 0.66)# borde de tarjetas agrupadoras

## Encabezado de sección: azul, 12px, MAYÚSCULAS, Manrope 700.
static func section(l: Label, text := "") -> void:
	if text != "":
		l.text = text.to_upper()
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", SECTION)
	l.modulate = Color.WHITE
	var f := body(700)
	if f != null:
		l.add_theme_font_override("font", f)

## Cuadro redondeado tintado para enmarcar un emoji/icono (18–20px de glifo dentro).
static func icon_tile(accent := PRIMARY, radius := 11) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(accent.r, accent.g, accent.b, 0.16)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(6)
	return sb

## Campo de entrada (nombre, servidor, código, dropdowns cerrados).
static func input(bg := INPUT_BG, border := BORDER, radius := 12) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(1)
	sb.border_color = border
	sb.set_content_margin_all(12)
	return sb

## Chip conmutable (mapa / modificador / estado / dificultad).
## selected=false → crema con borde tan; selected=true → relleno accent con
## labio inferior oscuro (extruido, como los botones primarios).
static func chip(selected: bool, accent := PRIMARY, radius := 12) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(radius)
	if selected:
		sb.bg_color = accent
		sb.border_width_bottom = 4
		sb.border_color = accent.darkened(0.32)
	else:
		sb.bg_color = PANEL_DEEP
		sb.set_border_width_all(1)
		sb.border_width_bottom = 3
		sb.border_color = BORDER
	sb.set_content_margin_all(11)
	return sb

## Tarjeta agrupadora estándar (envuelve varias secciones de una pantalla).
static func group_panel(radius := 18, pad := 14) -> StyleBoxFlat:
	return panel(PANEL_DEEP, GROUP_BORDER, radius, 1, pad)

## BARRA DE NAVEGACIÓN INFERIOR compartida (2026-07-23). Misma en Inicio /
## Colección / Tienda / Inventario, con la sección ACTUAL resaltada (así queda
## claro dónde estás sin flecha de "atrás"). `host` es la pantalla (para navegar
## con su get_tree()); `current` = "home"|"dex"|"shop"|"inv". Devuelve el panel
## anclado abajo, listo para añadir a un CanvasLayer.
static func bottom_nav(host: Node, current: String) -> PanelContainer:
	var items := [
		{"id": "home", "icon": "🏠", "label": "Inicio", "scene": "res://scenes/main_menu.tscn"},
		{"id": "dex", "icon": "📖", "label": "Colección", "scene": "res://scenes/dex.tscn"},
		{"id": "shop", "icon": "🛍", "label": "Tienda", "scene": "res://scenes/shop.tscn"},
		{"id": "inv", "icon": "📦", "label": "Inventario", "scene": "res://scenes/inventory.tscn"},
	]
	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -84
	bar.add_theme_stylebox_override("panel", panel(SURFACE, BORDER, 0, 1, 4))
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 0)
	bar.add_child(hb)
	for it in items:
		var active: bool = String(it["id"]) == current
		var col: Color = PRIMARY_EDGE if active else MUTED
		var b := Button.new()
		b.flat = true
		b.custom_minimum_size = Vector2(78, 72)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := VBoxContainer.new()
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_theme_constant_override("separation", 1)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(v)
		# barrita superior indicadora de la sección ACTIVA
		var mark := ColorRect.new()
		mark.color = PRIMARY_EDGE if active else Color(0, 0, 0, 0)
		mark.custom_minimum_size = Vector2(30, 4)
		mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(mark)
		var ic := Label.new()
		ic.text = String(it["icon"])
		ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ic.add_theme_font_size_override("font_size", 28)
		ic.modulate = Color.WHITE if active else Color(1, 1, 1, 0.65)
		v.add_child(ic)
		var lb := Label.new()
		lb.text = String(it["label"])
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.clip_text = true
		label(lb, 12, col, active, 800 if active else 700)
		v.add_child(lb)
		if active:
			var sel := StyleBoxFlat.new()
			sel.bg_color = Color(PRIMARY_EDGE.r, PRIMARY_EDGE.g, PRIMARY_EDGE.b, 0.12)
			sel.set_corner_radius_all(12)
			b.add_theme_stylebox_override("normal", sel)
		else:
			var scene := String(it["scene"])
			b.pressed.connect(func(): host.get_tree().change_scene_to_file(scene))
		hb.add_child(b)
	return bar

## Marco cuadrado (38×38) con un emoji centrado adentro. Sube la calidad de los
## iconos-emoji sin sustituirlos por texturas (§5 del handoff).
static func icon_tile_node(emoji: String, accent := PRIMARY, size := 38, glyph := 19) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(size, size)
	pc.add_theme_stylebox_override("panel", icon_tile(accent))
	var l := Label.new()
	l.text = emoji
	l.add_theme_font_size_override("font_size", glyph)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pc.add_child(l)
	return pc

## Popup de información (ⓘ de modificadores/estados). Reusa panel() para el marco.
static func info_popup_box() -> StyleBoxFlat:
	return panel(SURFACE, GROUP_BORDER, 18, 1, 16)

## Banner de alerta (validación / error). tint = DANGER por defecto.
static func alert_box(tint := DANGER) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(tint.r, tint.g, tint.b, 0.12)
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(1)
	sb.border_color = Color(tint.r, tint.g, tint.b, 0.42)
	sb.set_content_margin_all(12)
	return sb
