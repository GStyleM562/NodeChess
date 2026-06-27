extends PanelContainer
class_name FigureCard
## BASE design of a character "card" (placeholder art — colored portrait + data).
## Reused in the combat overlay and on the board. Claude Design can later swap the
## portrait/frame for real art; the structure/slots are what matters here.

## Accent colour for a figure (its dominant non-Miss attack colour).
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

func setup(data: Dictionary, rank: int = 0, team_col: Color = Color(0.5, 0.6, 0.85), compact: bool = false) -> void:
	var accent := accent_of(data)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.11, 0.16)
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(3)
	sb.border_color = team_col
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	add_theme_stylebox_override("panel", sb)

	if compact:
		_build_compact(data, rank, accent)
	else:
		_build_full(data, rank, accent)

func _portrait(accent: Color, data: Dictionary, sz: Vector2) -> Control:
	# Placeholder portrait: an accent panel + the figure's initials (art goes here later).
	var p := Panel.new()
	p.custom_minimum_size = sz
	var ps := StyleBoxFlat.new()
	ps.bg_color = accent.darkened(0.15)
	ps.set_corner_radius_all(10)
	ps.border_color = accent.lightened(0.3)
	ps.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", ps)
	var ini := Label.new()
	ini.text = _initials(String(data.get("name", "?")))
	ini.set_anchors_preset(Control.PRESET_FULL_RECT)
	ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ini.add_theme_font_size_override("font_size", int(sz.y * 0.5))
	ini.modulate = Color(1, 1, 1, 0.92)
	p.add_child(ini)
	return p

func _build_full(data: Dictionary, rank: int, accent: Color) -> void:
	custom_minimum_size = Vector2(150, 212)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	add_child(vb)
	vb.add_child(_portrait(accent, data, Vector2(130, 104)))
	var nm := _lbl(_name(data, rank), 18, accent.lightened(0.4))
	vb.add_child(nm)
	vb.add_child(_lbl(String(data.get("type", "?")), 13, Color(0.75, 0.8, 0.95)))
	vb.add_child(_lbl("Stamina: %d" % int(data.get("stamina", 2)), 13, Color(0.7, 0.85, 0.7)))
	var pl := data.get("passives", [])
	if not pl.is_empty():
		var names := []
		for pid in pl:
			names.append(String(Roster.PASSIVES.get(pid, {}).get("name", pid)))
		vb.add_child(_lbl(", ".join(names), 11, Color(0.8, 0.8, 0.6)))

func _build_compact(data: Dictionary, rank: int, accent: Color) -> void:
	custom_minimum_size = Vector2(232, 64)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	add_child(hb)
	hb.add_child(_portrait(accent, data, Vector2(48, 48)))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(vb)
	var nm := _lbl(_name(data, rank), 17, accent.lightened(0.4))
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vb.add_child(nm)
	var sub := _lbl("%s · ST %d" % [String(data.get("type", "?")), int(data.get("stamina", 2))], 12, Color(0.75, 0.8, 0.95))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vb.add_child(sub)

func _lbl(t: String, sz: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", sz)
	l.modulate = col
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
