extends Control
## Inventario de PIEZAS del Creador: cuántas posees, fragmentos y conversión
## (10 frag = 1 pieza). Los COFRES viven en el lobby (menú principal).
## Admin: botón de regalo ×3 para probar.

var _result: Label
var _mode_lbl: Label
var _inv_box: VBoxContainer
var _chest_box: VBoxContainer   # TUS COFRES (descifrar / abrir)
var _chest_hdr: Label           # "Tus cofres (N/4)"
var _chest_tick := 0.0
var _guide := ""                # guía "pícale aquí" activa (menu_craft/menu_chest)
var _guide_banner: PanelContainer
# Inventario POR PESTAÑAS (como el Creador): más limpio visualmente.
var _tab := "chests"            # "chests" | "pieces"
var _tab_chests: Button
var _tab_pieces: Button
var _page_chests: VBoxContainer
var _page_pieces: VBoxContainer

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
	root.offset_bottom = -92   # deja sitio a la barra de navegación inferior
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	# barra de navegación inferior compartida (Inventario resaltada)
	var nl := CanvasLayer.new()
	nl.add_child(UITheme.bottom_nav(self, "inv"))
	add_child(nl)

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
	# 🧾 últimos movimientos (evidencia para soporte: gastos y entregas)
	var txb := Button.new()
	txb.text = "🧾"
	txb.custom_minimum_size = Vector2(44, 42)
	txb.tooltip_text = "Últimos movimientos (compras, crafteos, cofres)"
	UITheme.button_font(txb, 16, UITheme.TEXT2, false, 600)
	UITheme.style_surface(txb, UITheme.SURFACE2, UITheme.BORDER, 11)
	txb.pressed.connect(_show_tx_log)
	top.add_child(txb)
	# píldora de modo (👤 USUARIO / 👑 ADMIN) — §6.4
	var mode_pill := PanelContainer.new()
	mode_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mode_pill.add_theme_stylebox_override("panel", UITheme.pill(UITheme.PANEL_DEEP, UITheme.PRIMARY_EDGE, 10))
	_mode_lbl = Label.new()
	UITheme.label(_mode_lbl, 12, UITheme.PRIMARY_EDGE, true, 700)
	mode_pill.add_child(_mode_lbl)
	top.add_child(mode_pill)

	_result = Label.new()
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.label(_result, 13, UITheme.SUCCESS, false, 700)
	root.add_child(_result)

	# --- PESTAÑAS: 📦 Cofres | 🧩 Piezas (división para más limpieza visual) ---
	var seg := HBoxContainer.new()
	seg.add_theme_constant_override("separation", 8)
	root.add_child(seg)
	_tab_chests = _seg_btn("📦  Cofres", "chests")
	_tab_pieces = _seg_btn("🧩  Piezas", "pieces")
	seg.add_child(_tab_chests)
	seg.add_child(_tab_pieces)

	# --- PÁGINA COFRES: la cola (descifrar / abrir) ---
	_page_chests = VBoxContainer.new()
	_page_chests.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page_chests.add_theme_constant_override("separation", 8)
	root.add_child(_page_chests)
	var chint := Label.new()
	chint.text = "Tu COLA DE CAJAS: los cofres se ganan jugando; aquí los descifras (tardan un rato) y los abres."
	chint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.label(chint, 11, UITheme.MUTED, false, 600)
	_page_chests.add_child(chint)
	_chest_hdr = Label.new()
	UITheme.section(_chest_hdr, "Tus cofres (0/%d)" % Inventory.CHEST_SLOTS)
	_page_chests.add_child(_chest_hdr)
	var chest_scroll := ScrollContainer.new()
	chest_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chest_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_page_chests.add_child(chest_scroll)
	_chest_box = VBoxContainer.new()
	_chest_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chest_box.add_theme_constant_override("separation", 6)
	chest_scroll.add_child(_chest_box)
	_rebuild_chests()

	# --- PÁGINA PIEZAS: inventario + conversión de fragmentos ---
	_page_pieces = VBoxContainer.new()
	_page_pieces.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page_pieces.add_theme_constant_override("separation", 8)
	root.add_child(_page_pieces)
	var hdr := Label.new()
	UITheme.section(hdr, "Tus piezas  ·  10 fragmentos = 1 pieza")
	_page_pieces.add_child(hdr)
	# admin: regalo de prueba
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
		_page_pieces.add_child(gift)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_page_pieces.add_child(scroll)
	_inv_box = VBoxContainer.new()
	_inv_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inv_box.add_theme_constant_override("separation", 4)
	scroll.add_child(_inv_box)

	_refresh_mode()
	_rebuild_inventory()
	_set_tab("chests")
	_guide_setup()

## Botón de pestaña 📦/🧩.
func _seg_btn(text: String, tab: String) -> Button:
	var b := Button.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 46)
	b.pressed.connect(func(): _set_tab(tab))
	return b

func _set_tab(tab: String) -> void:
	_tab = tab
	if _page_chests != null:
		_page_chests.visible = tab == "chests"
	if _page_pieces != null:
		_page_pieces.visible = tab == "pieces"
	for pair in [[_tab_chests, "chests"], [_tab_pieces, "pieces"]]:
		var b: Button = pair[0]
		if b == null:
			continue
		var active: bool = tab == String(pair[1])
		UITheme.button_font(b, 15, UITheme.TEXT if active else UITheme.TEXT2, true, 800)
		if active:
			UITheme.style_primary(b, UITheme.PRIMARY, 12)
		else:
			UITheme.style_surface(b, UITheme.SURFACE2, UITheme.BORDER, 12)

# ---------------------------------------------------------------- guías 🎓
## Guía "PÍCALE AQUÍ" del FULL tutorial: resalta el botón objetivo y completa
## el capítulo cuando el jugador HACE la acción de verdad.
func _guide_setup() -> void:
	_guide = TutorialLib.active_guide
	if _guide == "":
		return
	# abrir la pestaña correcta según la guía (craftear = Piezas · descifrar = Cofres)
	_set_tab("pieces" if _guide == "menu_craft" else "chests")
	if _guide == "menu_craft":
		# que siempre haya algo crafteable: 10 fragmentos de regalo si faltan
		var has_ten := false
		for key in Inventory.catalog():
			if Inventory.frags(String(key)) >= Inventory.FRAG_COST:
				has_ten = true
				break
		if not has_ten:
			Inventory.add_frags("color:gold", Inventory.FRAG_COST)
		_rebuild_inventory()
	elif _guide == "menu_chest":
		# que siempre haya un cofre que descifrar
		if Inventory.chest_inv.is_empty():
			Inventory.chest_inv.append({"tier": "t5", "state": "locked", "ready_at": 0})
		var any_locked := false
		for i in Inventory.chest_inv.size():
			if String(Inventory.chest_info(i).get("state", "")) == "locked":
				any_locked = true
		if not any_locked:
			Inventory.chest_inv.append({"tier": "t5", "state": "locked", "ready_at": 0})
		_rebuild_chests()
	_guide_banner = PanelContainer.new()
	_guide_banner.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_guide_banner.offset_top = -92
	_guide_banner.offset_bottom = -12
	_guide_banner.offset_left = 12
	_guide_banner.offset_right = -12
	_guide_banner.add_theme_stylebox_override("panel", UITheme.panel(Color(0.92, 0.975, 0.92, 0.97), UITheme.SUCCESS, 14, 2, 10))
	var l := Label.new()
	l.text = ("🎓 TUTORIAL · Toca «👉 Convertir» en una pieza con fragmentos completos (10/10) para CRAFTEARLA." \
		if _guide == "menu_craft" else
		"🎓 TUTORIAL · Toca «👉 Descifrar» en uno de TUS COFRES para empezar a abrirlo.")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.label(l, 13, UITheme.TEXT, true, 700)
	_guide_banner.add_child(l)
	add_child(_guide_banner)

func _guide_complete() -> void:
	var id := _guide
	_guide = ""
	TutorialLib.active_guide = ""
	if _guide_banner != null and is_instance_valid(_guide_banner):
		_guide_banner.queue_free()
	var res: Dictionary = TutorialLib.complete(id)
	var ch: Dictionary = TutorialLib.chapter(id)
	var sub := ("✨ +%d XP ganada" % int(res["xp"])) if bool(res["first"]) else "repaso — sin XP repetida"
	RewardPopup.show(self, "🎓 ¡Capítulo superado!", UITheme.SUCCESS,
		[{"icon": String(ch.get("icon", "🎓")), "text": String(ch.get("title", "")), "sub": sub}],
		"Encuentra más capítulos en 🎓 Cómo jugar")

func _exit_tree() -> void:
	if _guide != "":
		TutorialLib.active_guide = ""   # salió sin completar: no re-disparar luego

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
	# contador de RANURAS siempre visible (llenas = las victorias no dan cofre)
	if _chest_hdr != null:
		var n: int = Inventory.chest_inv.size()
		var full := n >= Inventory.CHEST_SLOTS
		UITheme.section(_chest_hdr, "Tus cofres (%d/%d)%s" % [n, Inventory.CHEST_SLOTS,
			"  ·  ¡LLENAS! abre para ganar más" if full else ""])
		if full:
			_chest_hdr.add_theme_color_override("font_color", UITheme.DANGER)
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
	# icono/nombre del TIPO de caja (Figuras/Ataques/Pasivas/Variada) + su rareza
	var tid := String(info.get("type", "random"))
	var bspec: Dictionary = Inventory.BOX_TYPES.get(tid, Inventory.BOX_TYPES["random"])
	var tile := UITheme.icon_tile_node(String(bspec["icon"]), col, 40, 20)
	hb.add_child(tile)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vb.add_theme_constant_override("separation", 1)
	hb.add_child(vb)
	var nm := Label.new()
	nm.text = "%s · %s" % [String(bspec["name"]), String(ui["name"])]
	UITheme.label(nm, 14, col, true, 700)
	vb.add_child(nm)
	var sub := Label.new()
	var state := String(info["state"])
	match state:
		"locked":
			sub.text = "Cerrada · tarda %d min en descifrarse" % (int(info["secs"]) / 60)
		"unlocking":
			sub.text = "⏳ Descifrando… faltan %d:%02d" % [int(info["left"]) / 60, int(info["left"]) % 60]
		"ready":
			sub.text = "✓ ¡Lista para abrir!"
	UITheme.label(sub, 11, UITheme.SUCCESS if state == "ready" else UITheme.TEXT2, false, 600)
	vb.add_child(sub)
	# barra de PROGRESO del descifrado (control visual de la cola)
	if state == "unlocking":
		var total := maxf(1.0, float(info["secs"]))
		var done := clampf((total - float(info["left"])) / total, 0.0, 1.0)
		var pb := ProgressBar.new()
		pb.custom_minimum_size = Vector2(0, 8)
		pb.show_percentage = false
		pb.max_value = 1.0
		pb.value = done
		var pbg := StyleBoxFlat.new(); pbg.bg_color = UITheme.SURFACE2; pbg.set_corner_radius_all(4)
		var pfg := StyleBoxFlat.new(); pfg.bg_color = col; pfg.set_corner_radius_all(4)
		pb.add_theme_stylebox_override("background", pbg)
		pb.add_theme_stylebox_override("fill", pfg)
		vb.add_child(pb)
	var act := Button.new()
	act.custom_minimum_size = Vector2(120, 44)
	act.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	match state:
		"locked":
			# Descifrado LIBRE: arranca el cofre QUE TÚ QUIERAS (varios a la vez).
			act.text = "Descifrar"
			UITheme.button_font(act, 13, UITheme.TEXT, true, 700)
			UITheme.style_surface(act, UITheme.SURFACE2, UITheme.BORDER, 10)
			if _guide == "menu_chest":
				act.text = "👉 Descifrar"
				UITheme.button_font(act, 12, Color(0.14, 0.12, 0.02), true, 800)
				UITheme.style_primary(act, UITheme.GOLD, 10)
			act.pressed.connect(func():
				if Inventory.start_unlock(i):
					if _guide == "menu_chest":
						_guide_complete()
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
				# RECIBO vistoso: exactamente lo ENTREGADO por el motor.
				var items: Array = []
				for key in r.get("pieces", []):
					items.append({"icon": Inventory.piece_icon(String(key)),
						"text": String(Inventory.piece_name(String(key))),
						"sub": "×1 añadido a tu inventario"})
				if int(r.get("gems", 0)) > 0:
					items.append({"icon": "💎", "text": "+%d DIAMANTES" % int(r["gems"]),
						"sub": "acreditados a tu cuenta", "col": Color(0.5, 0.85, 1.0)})
				RewardPopup.show(self, "📦 ¡Cofre %s abierto!" % String(ui["name"]), col,
					items, "Saldo: 🪙 %d · 💎 %d" % [Inventory.coins, Inventory.gems])
				_rebuild_chests()
				_rebuild_inventory())
	hb.add_child(act)
	return p

# ---------------------------------------------------------------- 🧾 movimientos
## Visor de los últimos movimientos del 🧾 log persistente (soporte técnico:
## demuestra qué se gastó y qué se entregó en cada transacción).
func _show_tx_log() -> void:
	var labels := {"compra": "🛍 Compra", "crafteo": "🔨 Crafteo", "cofre_ganado": "📦 Cofre ganado",
		"abrir_cofre": "📦 Cofre abierto", "descifrar": "⏳ Descifrado iniciado",
		"nivel": "⬆ Subida de nivel", "caja_gratis": "🎁 Caja gratis",
		"fondos_admin": "💰 Ajuste de fondos", "crear_figura": "🛠 Figura creada",
		"borrar_inventario": "🗑 Inventario borrado"}
	var items: Array = []
	var log: Array = Inventory.tx_log.duplicate()
	log.reverse()
	for e in log.slice(0, 10):
		var d: Dictionary = e
		var k := String(d.get("k", "?"))
		var mins := maxi(0, (int(Time.get_unix_time_from_system()) - int(d.get("t", 0))) / 60)
		var sub := "hace %d min" % mins if mins < 120 else "hace %d h" % (mins / 60)
		var detail := ""
		match k:
			"compra":
				detail = "%s · %s %d" % [Inventory.piece_name(String(d.get("key", ""))),
					"💎" if String(d.get("cur", "")) == "gems" else "🪙", int(d.get("price", 0))]
			"crafteo":
				detail = "%s (10 frag → 1 pieza)" % Inventory.piece_name(String(d.get("key", "")))
			"cofre_ganado", "descifrar":
				detail = String((Inventory.CHESTS.get(String(d.get("tier", "")), {}) as Dictionary).get("name", d.get("tier", "")))
			"abrir_cofre":
				detail = "%d piezas%s" % [(d.get("piezas", []) as Array).size(),
					("  +%d💎" % int(d.get("gems", 0))) if int(d.get("gems", 0)) > 0 else ""]
			"nivel":
				detail = "nivel %d · +%d🪙%s" % [int(d.get("lvl", 0)), int(d.get("coins", 0)),
					("  +%d💎" % int(d.get("gems", 0))) if int(d.get("gems", 0)) > 0 else ""]
			"fondos_admin":
				detail = "%+d🪙 · %+d💎" % [int(d.get("coins", 0)), int(d.get("gems", 0))]
			"crear_figura":
				detail = "%s (%d piezas)" % [String(d.get("fig", "?")), int(d.get("piezas", 0))]
		items.append({"icon": "🧾", "text": String(labels.get(k, k)) + ((" — " + detail) if detail != "" else ""),
			"sub": sub, "col": UITheme.PRIMARY_EDGE})
	if items.is_empty():
		items.append({"icon": "🧾", "text": "Sin movimientos todavía",
			"sub": "Aquí quedan tus compras, crafteos y cofres", "col": UITheme.MUTED})
	RewardPopup.show(self, "🧾 Últimos movimientos", UITheme.PRIMARY_EDGE, items,
		"Saldo actual: 🪙 %d · 💎 %d" % [Inventory.coins, Inventory.gems])

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
	var groups := [["model:", "FIGURAS"], ["rarity:", "RAREZAS"], ["class:", "CLASES"],
		["atype:", "TIPOS DE ATAQUE"], ["color:", "ATAQUES (COLORES)"],
		["pow:", "DAÑOS (blanco/oro)"], ["stars:", "ESTRELLAS (púrpura)"],
		["prob:", "PROBABILIDADES"], ["fx:", "ESTADOS"], ["passive:", "PASIVAS"],
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
	# guía de crafteo: resaltar el botón exacto que hay que picar 👉
	if _guide == "menu_craft" and fr >= Inventory.FRAG_COST:
		cv.text = "👉 Convertir"
		UITheme.button_font(cv, 12, Color(0.14, 0.12, 0.02), false, 800)
		UITheme.style_primary(cv, UITheme.GOLD, 9)
	cv.pressed.connect(func():
		var r: Dictionary = Inventory.convert(key)
		if bool(r.get("ok", false)):
			if _guide == "menu_craft":
				_guide_complete()   # el capítulo ES el recibo (no duplicar popups)
			else:
				# RECIBO del crafteo: lo que entregó el motor, con saldo de frags.
				RewardPopup.show(self, "🔨 ¡Crafteo completado!", UITheme.GOLD,
					[{"icon": Inventory.piece_icon(key), "text": String(r["name"]),
						"sub": "%d fragmentos → 1 pieza completa · ahora tienes ×%d" % [Inventory.FRAG_COST, int(r["owned"])]}],
					"Fragmentos restantes de esta pieza: %d/%d" % [int(r["frags"]), Inventory.FRAG_COST])
			_rebuild_inventory()
		else:
			_result.text = "✗ " + String(r.get("error", "No se pudo convertir")))
	row.add_child(cv)
	return row
