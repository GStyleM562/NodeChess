extends Control
## Inventario de PIEZAS del Creador: cuántas posees, fragmentos y conversión
## (10 frag = 1 pieza). Los COFRES viven en el lobby (menú principal).
## Admin: botón de regalo ×3 para probar.

var _result: Label
var _mode_lbl: Label
var _inv_box: VBoxContainer

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UITheme.BG_DEEP
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 14
	root.offset_right = -14
	root.offset_top = 12
	root.offset_bottom = -12
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	# --- top bar ---
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	root.add_child(top)
	var back := Button.new()
	back.text = "←"
	back.custom_minimum_size = Vector2(48, 42)
	UITheme.button_font(back, 22, UITheme.TEXT)
	UITheme.style_surface(back)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	top.add_child(back)
	var title := Label.new()
	title.text = "Inventario"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.label(title, 22, UITheme.GOLD, true, 800)
	top.add_child(title)
	_mode_lbl = Label.new()
	_mode_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.label(_mode_lbl, 13, UITheme.TEXT2, true, 700)
	top.add_child(_mode_lbl)

	var chint := Label.new()
	chint.text = "Los COFRES se abren desde el menú principal; aquí ves tus piezas y conviertes fragmentos."
	chint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.label(chint, 11, UITheme.MUTED, false, 600)
	root.add_child(chint)

	_result = Label.new()
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.label(_result, 13, UITheme.SUCCESS, false, 700)
	root.add_child(_result)

	# --- admin: regalo de prueba ---
	if Inventory.is_admin():
		var gift := Button.new()
		gift.text = "🎁 Regalar 3 de CADA pieza (prueba admin)"
		gift.custom_minimum_size = Vector2(0, 44)
		UITheme.button_font(gift, 14, UITheme.TEXT, true, 700)
		UITheme.style_primary(gift, UITheme.GOLD.darkened(0.25), 12)
		gift.pressed.connect(func():
			var n: int = Inventory.gift_all(3)
			_result.text = "✓ Regaladas 3 piezas de cada una (%d tipos)." % n
			_rebuild_inventory())
		root.add_child(gift)

	# --- inventario ---
	var hdr := Label.new()
	hdr.text = "TU INVENTARIO  ·  10 fragmentos = 1 pieza"
	UITheme.label(hdr, 12, UITheme.MUTED, true, 700)
	root.add_child(hdr)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_inv_box = VBoxContainer.new()
	_inv_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inv_box.add_theme_constant_override("separation", 4)
	scroll.add_child(_inv_box)

	_refresh_mode()
	_rebuild_inventory()

# ---------------------------------------------------------------- inventario
func _refresh_mode() -> void:
	_mode_lbl.text = "👑 ADMIN (todo ∞)" if Inventory.is_admin() else "👤 USUARIO"
	_mode_lbl.add_theme_color_override("font_color", UITheme.GOLD if Inventory.is_admin() else UITheme.PRIMARY_EDGE)

func _rebuild_inventory() -> void:
	for c in _inv_box.get_children():
		c.queue_free()
	var groups := [["model:", "FIGURAS"], ["rarity:", "RAREZAS"], ["atype:", "TIPOS DE ATAQUE"],
		["color:", "ATAQUES (COLORES)"], ["fx:", "ESTADOS"], ["passive:", "PASIVAS"],
		["stamina:", "ESTAMINA"], ["resist:", "RESISTENCIAS"]]
	for g in groups:
		var hdr := Label.new()
		hdr.text = String(g[1])
		UITheme.label(hdr, 11, UITheme.MUTED, true, 700)
		_inv_box.add_child(hdr)
		for key in Inventory.catalog():
			if not String(key).begins_with(String(g[0])):
				continue
			_inv_box.add_child(_inv_row(String(key)))

func _inv_row(key: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var name := Label.new()
	name.text = Inventory.piece_name(key)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var have := Inventory.is_admin() or Inventory.has_piece(key)
	UITheme.label(name, 13, UITheme.TEXT if have else UITheme.MUTED, false, 600)
	if not have:
		name.text = "🔒 " + name.text
	row.add_child(name)
	var count := Label.new()
	count.text = "∞" if Inventory.is_admin() else "×%d" % Inventory.owned(key)
	UITheme.label(count, 13, UITheme.SUCCESS if have else UITheme.MUTED, true, 700)
	row.add_child(count)
	var fr := Inventory.frags(key)
	var fl := Label.new()
	fl.text = "%d/%d" % [fr, Inventory.FRAG_COST]
	UITheme.label(fl, 12, UITheme.GOLD if fr >= Inventory.FRAG_COST else UITheme.TEXT2, false, 600)
	row.add_child(fl)
	var cv := Button.new()
	cv.text = "Convertir"
	cv.disabled = fr < Inventory.FRAG_COST
	cv.custom_minimum_size = Vector2(92, 34)
	UITheme.button_font(cv, 12, UITheme.TEXT, false, 700)
	UITheme.style_surface(cv, UITheme.SURFACE2, UITheme.BORDER, 9)
	cv.pressed.connect(func():
		if Inventory.convert(key):
			_result.text = "✓ %s convertida (+1 pieza)." % Inventory.piece_name(key)
			_rebuild_inventory())
	row.add_child(cv)
	return row
