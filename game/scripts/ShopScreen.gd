extends Control
## TIENDA (esquema del handoff §10) — SOLO VER por ahora: categorías reales
## (Modelos/Ataques/Pasivas/Tipos de ataque/Partes) con tarjetas y precios de
## muestra. Comprar muestra un aviso; la monetización real llega en Vuelta 02.

const CATS := ["Modelos", "Ataques", "Pasivas", "Tipos de ataque", "Partes"]
const CAT_ICON := {"Modelos": "🧍", "Ataques": "🎯", "Pasivas": "✨", "Tipos de ataque": "🎲", "Partes": "🧩"}

var _cat := 0
var _grid: GridContainer
var _chip_row: HBoxContainer
var _toast: Label

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
	root.offset_bottom = -8
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	# --- header: título + monedas ---
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	root.add_child(top)
	var title := Label.new()
	title.text = "Tienda"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.label(title, 24, UITheme.TEXT, true, 800)
	top.add_child(title)
	top.add_child(_coin("🪙", "1,250", UITheme.GOLD))
	top.add_child(_coin("💎", "30", Color(0.5, 0.85, 1.0)))

	var note := Label.new()
	note.text = "Vista PREVIA de la tienda — las compras se activan en la siguiente vuelta."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.label(note, 11, UITheme.MUTED, false, 600)
	root.add_child(note)

	# --- chips de categoría (scroll horizontal) ---
	var chip_scroll := ScrollContainer.new()
	chip_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	chip_scroll.custom_minimum_size = Vector2(0, 52)
	root.add_child(chip_scroll)
	_chip_row = HBoxContainer.new()
	_chip_row.add_theme_constant_override("separation", 8)
	chip_scroll.add_child(_chip_row)
	_build_chips()

	# --- rejilla 2-col scrolleable ---
	var scr := ScrollContainer.new()
	scr.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scr.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scr)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 9)
	_grid.add_theme_constant_override("v_separation", 9)
	scr.add_child(_grid)
	_build_items()

	_build_nav(root)

	# toast
	var ts := PanelContainer.new()
	ts.set_anchors_preset(Control.PRESET_CENTER)
	ts.offset_left = -170
	ts.offset_right = 170
	ts.offset_top = -30
	ts.offset_bottom = 30
	ts.add_theme_stylebox_override("panel", UITheme.panel(Color(0.08, 0.09, 0.16, 0.97), UITheme.GOLD.darkened(0.2), 12, 1, 10))
	ts.visible = false
	_toast = Label.new()
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.label(_toast, 14, UITheme.GOLD, true, 700)
	ts.add_child(_toast)
	add_child(ts)
	_toast.set_meta("box", ts)

# ---------------------------------------------------------------- categorías
func _build_chips() -> void:
	for c in _chip_row.get_children():
		c.queue_free()
	for i in CATS.size():
		var b := Button.new()
		b.text = "%s %s" % [CAT_ICON[CATS[i]], CATS[i]]
		b.custom_minimum_size = Vector2(0, 44)
		UITheme.button_font(b, 13, UITheme.TEXT, true, 700)
		b.add_theme_stylebox_override("normal", UITheme.chip(i == _cat, UITheme.PRIMARY))
		b.add_theme_stylebox_override("hover", UITheme.chip(i == _cat, UITheme.PRIMARY))
		b.add_theme_stylebox_override("pressed", UITheme.chip(i == _cat, UITheme.PRIMARY))
		var idx := i
		b.pressed.connect(func():
			_cat = idx
			_build_chips()
			_build_items())
		_chip_row.add_child(b)

# ---------------------------------------------------------------- items reales
## Cada ítem: {name, rarity ("common".."mythic"), icon}. Datos del juego real.
func _items_for(cat: String) -> Array:
	var out: Array = []
	match cat:
		"Modelos":
			for f in Roster.FIGURES:
				if bool(f.get("custom", false)):
					continue
				out.append({"name": String(f.get("name", "?")),
					"rarity": FigureCard._rarity_key(f), "icon": "🧍"})
		"Ataques":
			var seen := {}
			for f in Roster.FIGURES:
				for s in f.get("attack", []):
					var nm := String(s.get("name", ""))
					if nm == "" or seen.has(nm):
						continue
					seen[nm] = true
					var p := int(s.get("pow", 0))
					out.append({"name": nm,
						"rarity": ("epic" if p >= 80 else ("rare" if p >= 50 else "common")), "icon": "🎯"})
		"Pasivas":
			for pid in Roster.PASSIVES.keys():
				if pid in CharacterCreator.HIDDEN_PASSIVES:
					continue
				out.append({"name": String(Roster.PASSIVES[pid].get("name", pid)),
					"rarity": "epic", "icon": "✨"})
		"Tipos de ataque":
			for t in CharacterCreator.TYPES:
				var r := "common"
				if String(t).contains("D8") or String(t).contains("D10") or String(t).contains("D12") or String(t).contains("Doble"):
					r = "epic"
				elif String(t).contains("D4") or String(t).contains("D6"):
					r = "rare"
				elif String(t).contains("2d6"):
					r = "legend"
				out.append({"name": String(t), "rarity": r, "icon": "🎲"})
		"Partes":
			var inv := get_node("/root/Inventory")
			var shown := 0
			for key in inv.catalog():
				var ks := String(key)
				if not (ks.begins_with("stamina:") or ks.begins_with("color:") or ks.begins_with("resist:")):
					continue
				out.append({"name": String(inv.piece_name(ks)),
					"rarity": ("rare" if ks.begins_with("resist:") else "common"), "icon": "🧩"})
				shown += 1
				if shown >= 12:
					break
	return out

func _rarity_col(r: String) -> Color:
	match r:
		"mythic", "legend": return UITheme.R_LEGEND
		"epic": return UITheme.R_EPIC
		"rare": return UITheme.R_RARE
		_: return UITheme.R_COMMON

func _rarity_es(r: String) -> String:
	match r:
		"mythic": return "MÍTICA"
		"legend": return "LEGENDARIA"
		"epic": return "ÉPICA"
		"rare": return "RARA"
		_: return "COMÚN"

## Precio de muestra por rareza (oro para bajas, gemas para altas).
func _price_of(r: String) -> Array:
	match r:
		"mythic": return ["💎", "150"]
		"legend": return ["💎", "80"]
		"epic": return ["💎", "30"]
		"rare": return ["🪙", "500"]
		_: return ["🪙", "200"]

func _build_items() -> void:
	for c in _grid.get_children():
		c.queue_free()
	for it in _items_for(CATS[_cat]):
		_grid.add_child(_item_card(it))

func _item_card(it: Dictionary) -> Control:
	var rar := _rarity_col(String(it["rarity"]))
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", UITheme.panel(Color(0.071, 0.09, 0.18), Color(rar.r, rar.g, rar.b, 0.5), 14, 1, 10))
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 5)
	p.add_child(v)
	var tile := UITheme.icon_tile_node(String(it["icon"]), rar, 40, 21)
	var cc := CenterContainer.new()
	cc.add_child(tile)
	v.add_child(cc)
	var nm := Label.new()
	nm.text = String(it["name"])
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.label(nm, 13, UITheme.TEXT, true, 700)
	v.add_child(nm)
	var rl := Label.new()
	rl.text = _rarity_es(String(it["rarity"]))
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(rl, 10, rar, true, 700)
	v.add_child(rl)
	var price := _price_of(String(it["rarity"]))
	var buy := Button.new()
	buy.text = "%s %s" % [String(price[0]), String(price[1])]
	buy.custom_minimum_size = Vector2(0, 38)
	UITheme.button_font(buy, 13, UITheme.TEXT, true, 800)
	UITheme.style_surface(buy, UITheme.SURFACE2, UITheme.BORDER, 10)
	buy.pressed.connect(func(): _toast_msg("🛍 Tienda de PRUEBA — compras en la próxima vuelta"))
	v.add_child(buy)
	return p

func _toast_msg(text: String) -> void:
	var box = _toast.get_meta("box") if _toast != null and _toast.has_meta("box") else null
	if box == null:
		return
	_toast.text = text
	box.visible = true
	var t := get_tree().create_timer(1.5)
	t.timeout.connect(func(): if is_instance_valid(box): box.visible = false)

# ---------------------------------------------------------------- widgets
func _coin(icon: String, value: String, col: Color) -> Control:
	var p := PanelContainer.new()
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_theme_stylebox_override("panel", UITheme.pill(Color(0.07, 0.09, 0.16), UITheme.BORDER, 8))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 3)
	p.add_child(h)
	var i := Label.new()
	i.text = icon
	UITheme.label(i, 14, col, false, 600)
	h.add_child(i)
	var vl := Label.new()
	vl.text = value
	UITheme.label(vl, 13, UITheme.TEXT, true, 700)
	h.add_child(vl)
	return p

## Nav inferior Home / Tienda (activa) / Perfil.
func _build_nav(root: VBoxContainer) -> void:
	var nav := PanelContainer.new()
	nav.add_theme_stylebox_override("panel", UITheme.panel(Color(0.07, 0.08, 0.14, 0.99), UITheme.BORDER, 12, 1, 4))
	root.add_child(nav)
	var nb := HBoxContainer.new()
	nb.alignment = BoxContainer.ALIGNMENT_CENTER
	nb.add_theme_constant_override("separation", 26)
	nav.add_child(nb)
	nb.add_child(_nav_btn("🏠", "Home", false, func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn")))
	nb.add_child(_nav_btn("🛍", "Tienda", true, func(): pass))
	nb.add_child(_nav_btn("👤", "Perfil", false, func(): get_tree().change_scene_to_file("res://scenes/profile.tscn")))

func _nav_btn(icon: String, text: String, active: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.flat = true
	b.custom_minimum_size = Vector2(70, 52)
	var col := UITheme.PRIMARY_EDGE if active else UITheme.MUTED
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", -1)
	b.add_child(v)
	if active:
		var bar := ColorRect.new()
		bar.color = UITheme.PRIMARY_EDGE
		bar.custom_minimum_size = Vector2(26, 3)
		bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(bar)
	var il := Label.new()
	il.text = icon
	il.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(il, 18, col, false, 600)
	v.add_child(il)
	var tl := Label.new()
	tl.text = text
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(tl, 11, col, true, 700)
	v.add_child(tl)
	b.pressed.connect(cb)
	return b
