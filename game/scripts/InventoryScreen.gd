extends Control
## Inventario de PIEZAS del Creador: cuántas posees, fragmentos y conversión
## (10 frag = 1 pieza). Los COFRES viven en el lobby (menú principal).
## Admin: botón de regalo ×3 para probar.

var _result: Label
var _mode_lbl: Label
var _inv_box: VBoxContainer
var _chest_box: VBoxContainer   # TUS COFRES (descifrar / abrir)
var _chest_tick := 0.0

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
	UITheme.label(title, 24, UITheme.GOLD, true, 800)
	top.add_child(title)
	# píldora de modo (👤 USUARIO / 👑 ADMIN) — §6.4
	var mode_pill := PanelContainer.new()
	mode_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mode_pill.add_theme_stylebox_override("panel", UITheme.pill(UITheme.PANEL_DEEP, UITheme.PRIMARY_EDGE, 10))
	_mode_lbl = Label.new()
	UITheme.label(_mode_lbl, 12, UITheme.PRIMARY_EDGE, true, 700)
	mode_pill.add_child(_mode_lbl)
	top.add_child(mode_pill)

	var chint := Label.new()
	chint.text = "Los COFRES se abren desde el menú principal; aquí ves tus piezas y conviertes fragmentos."
	chint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.label(chint, 11, UITheme.MUTED, false, 600)
	root.add_child(chint)

	_result = Label.new()
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.label(_result, 13, UITheme.SUCCESS, false, 700)
	root.add_child(_result)

	# --- TUS COFRES: los GANAS venciendo partidas; aquí los DESCIFRAS y abres ---
	var chdr := Label.new()
	UITheme.section(chdr, "Tus cofres  ·  gana partidas para conseguirlos")
	root.add_child(chdr)
	_chest_box = VBoxContainer.new()
	_chest_box.add_theme_constant_override("separation", 6)
	root.add_child(_chest_box)
	_rebuild_chests()

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
	UITheme.section(hdr, "Tu inventario  ·  10 fragmentos = 1 pieza")
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

# ---------------------------------------------------------------- cofres 📦
const TIER_UI := {
	"t5": {"icon": "🧰", "name": "Común", "col": Color(0.212, 0.82, 0.498)},
	"t10": {"icon": "💠", "name": "Épico", "col": Color(0.722, 0.451, 1.0)},
	"t15": {"icon": "👑", "name": "Legendario", "col": Color(1.0, 0.773, 0.239)},
}

## Refresca cuentas atrás de descifrado cada medio segundo.
func _process(delta: float) -> void:
	_chest_tick += delta
	if _chest_tick >= 0.5:
		_chest_tick = 0.0
		_rebuild_chests()

func _rebuild_chests() -> void:
	if _chest_box == null:
		return
	for c in _chest_box.get_children():
		c.queue_free()
	if Inventory.chest_inv.is_empty():
		var l := Label.new()
		l.text = "Sin cofres — gana partidas (modo usuario) para llenar tus %d ranuras." % Inventory.CHEST_SLOTS
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UITheme.label(l, 12, UITheme.MUTED, false, 600)
		_chest_box.add_child(l)
		return
	for i in Inventory.chest_inv.size():
		_chest_box.add_child(_chest_row(i))

## Fila de un cofre ganado: icono + nombre + [Descifrar]/(cuenta atrás)/[¡ABRIR!]
func _chest_row(i: int) -> Control:
	var info: Dictionary = Inventory.chest_info(i)
	var ui: Dictionary = TIER_UI.get(String(info["tier"]), TIER_UI["t5"])
	var col: Color = ui["col"]
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.panel(UITheme.PANEL_DEEP, Color(col.r, col.g, col.b, 0.55), 13, 1, 8))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	p.add_child(hb)
	var tile := UITheme.icon_tile_node(String(ui["icon"]), col, 40, 20)
	hb.add_child(tile)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vb.add_theme_constant_override("separation", 0)
	hb.add_child(vb)
	var nm := Label.new()
	nm.text = "Cofre %s" % String(ui["name"])
	UITheme.label(nm, 14, col, true, 700)
	vb.add_child(nm)
	var sub := Label.new()
	var state := String(info["state"])
	match state:
		"locked":
			sub.text = "Cerrado · tarda %d min" % (int(info["secs"]) / 60)
		"unlocking":
			sub.text = "Descifrando… %d:%02d" % [int(info["left"]) / 60, int(info["left"]) % 60]
		"ready":
			sub.text = "¡Listo para abrir!"
	UITheme.label(sub, 11, UITheme.SUCCESS if state == "ready" else UITheme.TEXT2, false, 600)
	vb.add_child(sub)
	var act := Button.new()
	act.custom_minimum_size = Vector2(120, 44)
	act.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	match state:
		"locked":
			var busy: bool = Inventory.any_unlocking()
			act.text = "En espera" if busy else "Descifrar"
			act.disabled = busy
			UITheme.button_font(act, 13, UITheme.TEXT, true, 700)
			UITheme.style_surface(act, UITheme.SURFACE2, UITheme.BORDER, 10)
			act.pressed.connect(func():
				if Inventory.start_unlock(i):
					_rebuild_chests())
		"unlocking":
			act.text = "⏳"
			act.disabled = true
			UITheme.button_font(act, 15, UITheme.TEXT2, true, 700)
			UITheme.style_surface(act, UITheme.SURFACE2, UITheme.BORDER, 10)
		"ready":
			act.text = "¡ABRIR!"
			UITheme.button_font(act, 14, Color.WHITE, true, 800)
			UITheme.style_primary(act, UITheme.SUCCESS, 10)
			act.pressed.connect(func():
				var r: Dictionary = Inventory.open_won_chest(i)
				if r.is_empty():
					return
				var names: Array = []
				for key in r.get("pieces", []):
					names.append(String(Inventory.piece_name(String(key))))
				var msg := "✓ Cofre abierto: " + ", ".join(names)
				if int(r.get("gems", 0)) > 0:
					msg += "   💎 +%d ¡DIAMANTES!" % int(r["gems"])
				_result.text = msg
				_rebuild_chests()
				_rebuild_inventory())
	hb.add_child(act)
	return p

# ---------------------------------------------------------------- inventario
func _refresh_mode() -> void:
	_mode_lbl.text = "👑 ADMIN (todo ∞)" if Inventory.is_admin() else "👤 USUARIO"
	_mode_lbl.add_theme_color_override("font_color", UITheme.GOLD if Inventory.is_admin() else UITheme.PRIMARY_EDGE)

func _rebuild_inventory() -> void:
	for c in _inv_box.get_children():
		c.queue_free()
	# ESTADO VACÍO (§6.4): usuario sin ninguna pieza ni fragmento → invítalo a cofres.
	if not Inventory.is_admin() and _inventory_empty():
		_inv_box.add_child(_empty_state())
		return
	var groups := [["model:", "FIGURAS"], ["rarity:", "RAREZAS"], ["atype:", "TIPOS DE ATAQUE"],
		["color:", "ATAQUES (COLORES)"], ["fx:", "ESTADOS"], ["passive:", "PASIVAS"],
		["stamina:", "ESTAMINA"], ["resist:", "RESISTENCIAS"]]
	for g in groups:
		var hdr := Label.new()
		UITheme.section(hdr, String(g[1]))
		_inv_box.add_child(hdr)
		for key in Inventory.catalog():
			if not String(key).begins_with(String(g[0])):
				continue
			_inv_box.add_child(_inv_row(String(key)))

## ¿El usuario no posee NINGUNA pieza ni tiene fragmentos? (para el estado vacío)
func _inventory_empty() -> bool:
	for key in Inventory.catalog():
		if Inventory.owned(String(key)) > 0 or Inventory.frags(String(key)) > 0:
			return false
	return true

## Tarjeta de "aún no tienes piezas" + acceso directo a los cofres del lobby.
func _empty_state() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.group_panel(16, 22))
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	var tile := UITheme.icon_tile_node("📦", UITheme.GOLD, 64, 34)
	v.add_child(_centered(tile))
	var t := Label.new()
	t.text = "Aún no tienes piezas"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(t, 17, UITheme.TEXT, true, 800)
	v.add_child(t)
	var h := Label.new()
	h.text = "Abre cofres en el menú principal para conseguir figuras, colores, estados y más."
	h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.custom_minimum_size = Vector2(300, 0)
	UITheme.label(h, 12, UITheme.MUTED, false, 500)
	v.add_child(h)
	var go := Button.new()
	go.text = "🎁 Ir a los cofres"
	go.custom_minimum_size = Vector2(220, 46)
	UITheme.button_font(go, 15, Color.WHITE, true, 800)
	UITheme.style_primary(go, UITheme.PRIMARY, 12)
	go.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	v.add_child(_centered(go))
	return p

func _centered(c: Control) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.add_child(c)
	return cc

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
