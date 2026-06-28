extends PanelContainer
class_name FigureCard
## Character "card" — Claude Design hi-fi style (rarity frame, accent portrait,
## stamina badge, Sora/Manrope). Placeholder portrait (monogram on a radial accent)
## marks where real art will go. Reused on the board and in the combat overlay.

const RARITY := {
	"stone_golem": "rare", "ironclad_knight": "common", "nightblade": "epic",
	"rift_mage": "epic", "venom_witch": "epic", "storm_valkyrie": "rare",
	"emberborn": "legend", "coin_trickster": "legend",
}

static func accent_of(data: Dictionary) -> Color:
	var best_w := -1.0
	var best := {"col": "blue"}
	for s in data.get("attack", []):
		if String(s.get("col", "")) == "red":
			continue
		if float(s.get("w", 1.0)) > best_w:
			best_w = float(s.get("w", 1.0))
			best = s
	return Combat.color_of(best)

static func rarity_color(data: Dictionary) -> Color:
	match String(RARITY.get(String(data.get("id", "")), "common")):
		"legend": return UITheme.R_LEGEND
		"epic": return UITheme.R_EPIC
		"rare": return UITheme.R_RARE
		_: return UITheme.R_COMMON

static func rarity_name(data: Dictionary) -> String:
	match String(RARITY.get(String(data.get("id", "")), "common")):
		"legend": return "LEGENDARIA"
		"epic": return "ÉPICA"
		"rare": return "RARA"
		_: return "COMÚN"

func setup(data: Dictionary, rank: int = 0, team_col: Color = UITheme.PRIMARY, compact: bool = false) -> void:
	var accent := accent_of(data)
	var rar := rarity_color(data)
	var sb := UITheme.panel(UITheme.SURFACE, rar, 18, 2, 8)
	add_theme_stylebox_override("panel", sb)
	if compact:
		_build_compact(data, rank, accent, rar, team_col)
	else:
		_build_full(data, rank, accent, rar, team_col)

func _portrait(accent: Color, rar: Color, data: Dictionary, sz: Vector2, stamina: bool) -> Control:
	var p := Panel.new()
	p.custom_minimum_size = sz
	p.clip_contents = true
	var ps := StyleBoxFlat.new()
	ps.bg_color = UITheme.BG_DEEP
	ps.set_corner_radius_all(12)
	ps.set_border_width_all(2)
	ps.border_color = accent.lightened(0.25)
	p.add_theme_stylebox_override("panel", ps)
	# radial accent glow (art frame)
	var tex := TextureRect.new()
	tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	var g := Gradient.new()
	g.set_color(0, accent.lightened(0.12))
	g.set_color(1, Color(0.03, 0.04, 0.08))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.2)
	gt.fill_to = Vector2(1.05, 1.05)
	tex.texture = gt
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_SCALE
	p.add_child(tex)
	# top rarity bar
	var bar := ColorRect.new()
	bar.color = rar
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 4
	p.add_child(bar)
	# monogram
	var ini := Label.new()
	ini.text = _initials(String(data.get("name", "?")))
	ini.set_anchors_preset(Control.PRESET_FULL_RECT)
	ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.label(ini, int(sz.y * 0.46), Color(1, 1, 1, 0.95), true, 800)
	ini.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	ini.add_theme_constant_override("shadow_offset_y", 2)
	p.add_child(ini)
	# stamina badge
	if stamina:
		var badge := PanelContainer.new()
		badge.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		badge.offset_left = -42
		badge.offset_top = -26
		badge.offset_right = -4
		badge.offset_bottom = -4
		badge.add_theme_stylebox_override("panel", UITheme.pill(Color(0.05, 0.08, 0.14, 0.92), UITheme.ENERGY.darkened(0.2), 5))
		var bl := Label.new()
		UITheme.label(bl, 13, UITheme.ENERGY, true, 800)
		bl.text = "⚡%d" % int(data.get("stamina", 2))
		badge.add_child(bl)
		p.add_child(badge)
	return p

func _build_full(data: Dictionary, rank: int, accent: Color, rar: Color, team_col: Color) -> void:
	custom_minimum_size = Vector2(150, 214)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	add_child(vb)
	vb.add_child(_portrait(accent, rar, data, Vector2(132, 106), true))
	vb.add_child(_text(_name(data, rank), 17, UITheme.TEXT, true, 700))
	vb.add_child(_text(rarity_name(data), 10, rar, false, 700))
	vb.add_child(_text(String(data.get("type", "?")), 12, UITheme.TEXT2, false, 600))
	var pl: Array = data.get("passives", [])
	if not pl.is_empty():
		var names := []
		for pid in pl:
			names.append(String(Roster.PASSIVES.get(pid, {}).get("name", pid)))
		vb.add_child(_text(", ".join(names), 10, UITheme.GOLD.darkened(0.1), false, 600))

func _build_compact(data: Dictionary, rank: int, accent: Color, rar: Color, team_col: Color) -> void:
	custom_minimum_size = Vector2(240, 64)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	add_child(hb)
	hb.add_child(_portrait(accent, rar, data, Vector2(48, 48), false))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 1)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(vb)
	var nm := _text(_name(data, rank), 16, UITheme.TEXT, true, 700)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vb.add_child(nm)
	var sub := _text("%s · %s · ⚡%d" % [rarity_name(data), String(data.get("type", "?")), int(data.get("stamina", 2))], 11, UITheme.TEXT2, false, 600)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vb.add_child(sub)

func _text(t: String, sz: int, col: Color, title: bool, weight: int) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.label(l, sz, col, title, weight)
	return l

func _name(data: Dictionary, rank: int) -> String:
	return String(data.get("name", "?")) + ("  +%d" % rank if rank > 0 else "")

func _initials(name: String) -> String:
	var parts := name.split(" ", false)
	var s := ""
	for p in parts:
		if p.length() > 0:
			s += p[0]
		if s.length() >= 2:
			break
	return s.to_upper()
