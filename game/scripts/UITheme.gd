extends RefCounted
class_name UITheme
## Central design tokens (Claude Design handoff). Colors, fonts (Sora display +
## Manrope body) and StyleBox factories. Used across every UI script so the look is
## consistent. Pure presentation — no game logic.

# --- palette ---------------------------------------------------------------
const BG := Color(0.043, 0.055, 0.102)        # #0B0E1A
const BG_DEEP := Color(0.027, 0.035, 0.07)    # #070912
const SURFACE := Color(0.086, 0.106, 0.18)    # #161B2E
const SURFACE2 := Color(0.118, 0.145, 0.251)  # #1E2540
const BORDER := Color(0.18, 0.212, 0.345)     # #2E3658
const PRIMARY := Color(0.18, 0.42, 1.0)       # #2E6BFF
const PRIMARY_EDGE := Color(0.353, 0.627, 1.0)# #5AA0FF
const ORANGE := Color(1.0, 0.541, 0.239)      # #FF8A3D
const GOLD := Color(1.0, 0.773, 0.239)        # #FFC53D
const SUCCESS := Color(0.212, 0.82, 0.498)    # #36D17F
const DANGER := Color(1.0, 0.322, 0.278)      # #FF5247
const ENERGY := Color(0.31, 0.765, 0.969)     # #4FC3F7
const TEXT := Color(0.957, 0.965, 1.0)        # #F4F6FF
const TEXT2 := Color(0.663, 0.698, 0.816)     # #A9B2D0
const MUTED := Color(0.42, 0.459, 0.588)      # #6B7596

const R_COMMON := Color(0.541, 0.576, 0.678)  # #8A93AD
const R_RARE := Color(0.239, 0.49, 1.0)       # #3D7DFF
const R_EPIC := Color(0.722, 0.451, 1.0)      # #B873FF
const R_LEGEND := Color(1.0, 0.773, 0.239)    # #FFC53D

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
	var f := display(weight) if title else body(weight)
	if f != null:
		b.add_theme_font_override("font", f)

# --- styleboxes ------------------------------------------------------------
static func panel(bg := SURFACE, border := BORDER, radius := 16, bw := 2, pad := 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(bw)
	sb.border_color = border
	sb.set_content_margin_all(pad)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 6)
	return sb

static func pill(bg := SURFACE2, border := BORDER, pad := 8) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(999)
	sb.set_border_width_all(1)
	sb.border_color = border
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb

## A "juicy" primary button stylebox (accent fill, lighter top edge, drop shadow).
static func primary(accent := PRIMARY, radius := 16) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = accent
	sb.set_corner_radius_all(radius)
	sb.border_width_top = 2
	sb.border_color = accent.lightened(0.35)
	sb.set_content_margin_all(8)
	sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.45)
	sb.shadow_size = 12
	sb.shadow_offset = Vector2(0, 8)
	return sb

## Apply the juicy look (normal/hover/pressed) to a button.
static func style_primary(b: Button, accent := PRIMARY, radius := 16) -> void:
	b.add_theme_stylebox_override("normal", primary(accent, radius))
	var hov := primary(accent.lightened(0.06), radius)
	b.add_theme_stylebox_override("hover", hov)
	var pr := primary(accent.darkened(0.18), radius)
	pr.shadow_size = 4
	pr.shadow_offset = Vector2(0, 3)
	b.add_theme_stylebox_override("pressed", pr)

## Apply a flat surface look (normal/hover/pressed) to a secondary button.
static func style_surface(b: Button, bg := SURFACE, border := BORDER, radius := 14) -> void:
	b.add_theme_stylebox_override("normal", panel(bg, border, radius, 1, 8))
	b.add_theme_stylebox_override("hover", panel(bg.lightened(0.05), PRIMARY, radius, 1, 8))
	b.add_theme_stylebox_override("pressed", panel(bg.darkened(0.1), border, radius, 1, 8))
	b.add_theme_stylebox_override("disabled", panel(bg.darkened(0.2), border.darkened(0.2), radius, 1, 8))
