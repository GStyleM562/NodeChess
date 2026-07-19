extends RefCounted
class_name UITheme
## Central design tokens (Claude Design handoff). Colors, fonts (Sora display +
## Manrope body) and StyleBox factories. Used across every UI script so the look is
## consistent. Pure presentation — no game logic.

# --- palette ---------------------------------------------------------------
# TEMA "JUICY HALL" (2026-07-19, reglas en docs/UIUX_Juicy_Hall.md): claro y
# cálido tipo TCG Pocket — fondo amarillo pálido, tarjetas CREMA con LABIO
# inferior 3D, texto TINTA y acentos vivos PROFUNDOS (legibles sobre claro).
# Los nombres de los tokens se conservan del tema oscuro anterior para no
# tocar 12 pantallas: BG/SURFACE/TEXT significan lo mismo, en clave clara.
const BG := Color(0.976, 0.937, 0.76)         # amarillo pálido (pantallas)
const BG_DEEP := Color(0.972, 0.925, 0.72)    # amarillo cálido (fondo raíz)
const SURFACE := Color(1.0, 0.985, 0.94)      # tarjeta crema
const SURFACE2 := Color(0.984, 0.955, 0.885)  # crema honda (botón secundario)
const BORDER := Color(0.85, 0.77, 0.58)       # tan cálido (bordes/labios)
const PRIMARY := Color(0.18, 0.42, 1.0)       # #2E6BFF azul de acción
const PRIMARY_EDGE := Color(0.14, 0.36, 0.86) # azul texto/acentos sobre claro
const ORANGE := Color(0.93, 0.45, 0.12)       # naranja profundo
const GOLD := Color(0.93, 0.65, 0.05)         # ámbar (legible sobre crema)
const SUCCESS := Color(0.10, 0.60, 0.33)      # verde profundo
const DANGER := Color(0.86, 0.20, 0.18)       # rojo profundo
const ENERGY := Color(0.07, 0.55, 0.80)       # cian profundo
const TEXT := Color(0.24, 0.21, 0.13)         # TINTA (texto principal)
const TEXT2 := Color(0.45, 0.41, 0.32)        # tinta suave
const MUTED := Color(0.58, 0.53, 0.43)        # gris cálido

const R_COMMON := Color(0.47, 0.49, 0.55)
const R_RARE := Color(0.16, 0.42, 0.95)
const R_EPIC := Color(0.55, 0.28, 0.85)
const R_LEGEND := Color(0.93, 0.60, 0.05)

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
const SECTION := PRIMARY_EDGE                      # azul de encabezados de sección
const PANEL_DEEP := Color(0.968, 0.93, 0.845)      # panel agrupador crema-tan
const INPUT_BG := Color(1.0, 1.0, 0.985)           # campos casi blancos
const GROUP_BORDER := Color(0.88, 0.815, 0.66)     # borde de tarjetas agrupadoras

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
