extends Control
## Online lobby: connect to the relay, CREATE a room (get a 4-letter code) or JOIN one.
## The host picks the map + presses START; the guest waits. On start we hand the shared
## decks to NetSession and go to the board. The deck sent is the player's SAVED team
## (Loadout) as full figure dicts (+ evolution closure) so the opponent can render/sim
## them. Perspective: no board flip — each client just uses its own-side camera.

const URL_PATH := "user://server_url.txt"
const DEFAULT_URL := "wss://nodechess-server.onrender.com"

var _url: LineEdit
var _name: LineEdit
var _code_in: LineEdit
var _status: Label
var _panel_connect: VBoxContainer
var _panel_room: VBoxContainer
var _code_lbl: Label
var _players_lbl: Label
var _map_box: HBoxContainer
var _start_btn: Button
var _pending := ""      # "create" | "join"
var _map := 0
var _in_room := false

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_map = Loadout.map_index

	var bg := ColorRect.new()
	bg.color = UITheme.BG_DEEP
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 18
	root.offset_right = -18
	root.offset_top = 20
	root.offset_bottom = -16
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var title := Label.new()
	title.text = "Jugar en línea"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(title, 28, UITheme.GOLD, true, 800)
	root.add_child(title)

	# Versión de RED visible: si en un teléfono dice v24 y en el otro no, los
	# builds no coinciden y la partida NO puede funcionar — primer sospechoso.
	var ver := Label.new()
	ver.text = "red v%d" % NetSession.NET_BUILD
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(ver, 11, UITheme.MUTED, false, 600)
	root.add_child(ver)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.label(_status, 13, UITheme.TEXT2, false, 600)
	root.add_child(_status)

	# --- connect panel ---
	_panel_connect = VBoxContainer.new()
	_panel_connect.add_theme_constant_override("separation", 8)
	root.add_child(_panel_connect)
	_name = _field(_panel_connect, "Tu nombre", "Jugador")
	# Servidor: campo OCULTO (el usuario no debe verlo/tocarlo). Sigue funcional
	# con la URL guardada o la del relay por defecto.
	_url = LineEdit.new()
	_url.text = _load_url()
	_url.visible = false
	_panel_connect.add_child(_url)
	_panel_connect.add_child(_deck_card())
	var create := _button("CREAR SALA", UITheme.SUCCESS)
	create.pressed.connect(_on_create)
	_panel_connect.add_child(create)
	var jr := HBoxContainer.new()
	jr.add_theme_constant_override("separation", 8)
	_panel_connect.add_child(jr)
	_code_in = LineEdit.new()
	_code_in.placeholder_text = "CÓDIGO"
	_code_in.max_length = 4
	_code_in.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_code_in.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_code_in.custom_minimum_size = Vector2(0, 52)
	_style_le(_code_in)
	_code_in.text_changed.connect(func(t): _code_in.text = t.to_upper(); _code_in.caret_column = _code_in.text.length())
	jr.add_child(_code_in)
	var join := _button("UNIRSE", UITheme.PRIMARY)
	join.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join.pressed.connect(_on_join)
	jr.add_child(join)

	# --- room panel (hidden until in a room) ---
	_panel_room = VBoxContainer.new()
	_panel_room.add_theme_constant_override("separation", 10)
	_panel_room.visible = false
	root.add_child(_panel_room)
	_code_lbl = Label.new()
	_code_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(_code_lbl, 40, UITheme.GOLD, true, 800)
	_panel_room.add_child(_code_lbl)
	_players_lbl = Label.new()
	_players_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(_players_lbl, 15, UITheme.TEXT, true, 700)
	_panel_room.add_child(_players_lbl)
	_panel_room.add_child(_hdr("MAPA (lo elige el anfitrión)"))
	_map_box = HBoxContainer.new()
	_map_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_map_box.add_theme_constant_override("separation", 6)
	_panel_room.add_child(_map_box)
	_start_btn = _button("EMPEZAR PARTIDA", UITheme.SUCCESS)
	_start_btn.pressed.connect(func(): NetSession.client.start_match())
	_start_btn.disabled = true
	_panel_room.add_child(_start_btn)

	root.add_child(_spacer())
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 8)
	root.add_child(foot)
	var back := _button("← Menú", UITheme.SURFACE)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(_leave)
	foot.add_child(back)
	# 📶 bitácora online: ver/copiar user://logs/online_debug.txt desde el
	# teléfono para poder reportar EXACTAMENTE qué pasó si algo falla.
	var logs := _button("📶", UITheme.SURFACE)
	logs.custom_minimum_size = Vector2(64, 52)
	logs.pressed.connect(_show_log)
	foot.add_child(logs)

	_wire(NetSession.client)

func _wire(c) -> void:
	c.connected.connect(_on_connected)
	c.connecting_status.connect(func(t): _status.text = t)
	c.error_msg.connect(func(t): _status.text = "⚠ " + t; _pending = "")
	c.room_created.connect(_on_room_created)
	c.room_joined.connect(_on_room_joined)
	c.players_updated.connect(_on_players)
	c.room_map.connect(func(m): _map = m; _build_maps(); _refresh_players([]))
	c.match_start.connect(_on_match_start)
	c.player_left.connect(func(_id): _players_lbl.text = "El rival salió…"; _start_btn.disabled = true)
	# ANTES una caída del socket en el lobby era MUDA (la pantalla se quedaba
	# igual y parecía que "no pasaba nada" al pulsar EMPEZAR). Ahora se ve.
	c.disconnected.connect(func():
		_status.text = "⚠ Se perdió la conexión con el servidor. Vuelve a intentar."
		NetSession.dlog("lobby: socket caído (código %d)" % NetSession.client.last_close_code()))

# ---------------------------------------------------------------- mazo en uso
## LA regla de oro: JAMÁS ir online sin un mazo completo. Devuelve el problema
## del mazo EN USO ("" = listo para jugar).
func _deck_problem() -> String:
	if not Loadout.active_ready():
		return "Tu mazo «%s» tiene %d/%d figuras. Complétalo en 🃏 Mazos." % [
			Loadout.active_name(), Loadout.player_team.size(), Loadout.DECK_SIZE]
	for ri in Loadout.player_team:
		if ri < 0 or ri >= Roster.FIGURES.size():
			return "Tu mazo «%s» tiene figuras inválidas. Revísalo en 🃏 Mazos." % Loadout.active_name()
		var d: Dictionary = Roster.FIGURES[ri]
		if not (Inventory.is_admin() or bool(d.get("custom", false)) or Inventory.has_piece("model:" + String(d.get("id", "")))):
			return "Tu mazo «%s» usa figuras que no posees. Revísalo en 🃏 Mazos." % Loadout.active_name()
	return ""

## Tarjeta "MAZO EN USO": nombre + 6/6 + estado, con acceso directo a Mazos.
func _deck_card() -> Control:
	var ok := _deck_problem() == ""
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.panel(UITheme.PANEL_DEEP,
		(UITheme.SUCCESS if ok else UITheme.DANGER).darkened(0.2), 14, 1, 10))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	p.add_child(hb)
	var tile := UITheme.icon_tile_node("🃏", UITheme.SUCCESS if ok else UITheme.DANGER, 38, 19)
	hb.add_child(tile)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vb.add_theme_constant_override("separation", 0)
	hb.add_child(vb)
	var nm := Label.new()
	nm.text = "Mazo en uso: %s" % Loadout.active_name()
	UITheme.label(nm, 14, UITheme.TEXT, true, 700)
	vb.add_child(nm)
	var st := Label.new()
	st.text = ("%d/%d ✓ listo para jugar" % [Loadout.player_team.size(), Loadout.DECK_SIZE]) if ok \
		else ("%d/%d — incompleto" % [Loadout.player_team.size(), Loadout.DECK_SIZE])
	UITheme.label(st, 12, UITheme.SUCCESS if ok else UITheme.DANGER, false, 700)
	vb.add_child(st)
	var ch := Button.new()
	ch.text = "Cambiar"
	ch.custom_minimum_size = Vector2(96, 44)
	ch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UITheme.button_font(ch, 13, UITheme.TEXT, true, 700)
	UITheme.style_surface(ch, UITheme.SURFACE2, UITheme.BORDER, 10)
	ch.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/deck_builder.tscn"))
	hb.add_child(ch)
	return p

# ---------------------------------------------------------------- actions
func _on_create() -> void:
	var prob := _deck_problem()
	if prob != "":
		_status.text = "⚠ " + prob
		return
	_pending = "create"
	_save_url(_url.text)
	if NetSession.client.is_open():
		_on_connected()
	elif NetSession.client.is_connecting():
		_status.text = "Ya estoy conectando… espera, se reintenta solo."
	else:
		_status.text = "Conectando…"
		NetSession.client.connect_to(_url.text.strip_edges())

func _on_join() -> void:
	var prob := _deck_problem()
	if prob != "":
		_status.text = "⚠ " + prob
		return
	if _code_in.text.strip_edges().length() < 4:
		_status.text = "Escribe el código de 4 letras."
		return
	_pending = "join"
	_save_url(_url.text)
	if NetSession.client.is_open():
		_on_connected()
	elif NetSession.client.is_connecting():
		_status.text = "Ya estoy conectando… espera, se reintenta solo."
	else:
		_status.text = "Conectando…"
		NetSession.client.connect_to(_url.text.strip_edges())

func _on_connected() -> void:
	var pn := _name.text.strip_edges()
	if pn == "":
		pn = "Jugador"
	# VALIDAR EL MAZO EN ORIGEN: si por lo que sea no pudimos armar las 6
	# figuras, NO entramos a la sala con un mazo roto (antes viajaba vacío en
	# silencio y la partida moría al empezar, sin pista alguna).
	var deck := _my_deck()
	var n: int = (deck.get("team", []) as Array).size()
	if n != Loadout.DECK_SIZE:
		_pending = ""
		_status.text = "⚠ No pude armar tu mazo (%d/%d figuras). Revísalo en 🃏 Mazos." % [n, Loadout.DECK_SIZE]
		NetSession.dlog("mazo en origen INCOMPLETO: %d/%d (team=%s)" % [n, Loadout.DECK_SIZE, str(Loadout.player_team)])
		return
	NetSession.dlog("enviando mazo: %d figuras, %d lib, %d bytes (%s)" % [
		n, (deck.get("lib", []) as Array).size(), JSON.stringify(deck).length(), _pending])
	if _pending == "create":
		NetSession.client.create_room(pn, deck, _map)
	elif _pending == "join":
		NetSession.client.join_room(_code_in.text.strip_edges(), pn, deck)
	_pending = ""

func _on_room_created(code: String, you: int, players: Array) -> void:
	NetSession.seat = you
	NetSession.room_code = code
	NetSession.server_url = _url.text.strip_edges()
	_enter_room(code, true)
	_refresh_players(players)

func _on_room_joined(code: String, you: int, players: Array) -> void:
	NetSession.seat = you
	NetSession.room_code = code
	NetSession.server_url = _url.text.strip_edges()
	_enter_room(code, false)
	_refresh_players(players)

func _enter_room(code: String, is_host: bool) -> void:
	_in_room = true
	_panel_connect.visible = false
	_panel_room.visible = true
	_code_lbl.text = code
	_status.text = "Comparte el código. " + ("Tú eres el anfitrión." if is_host else "Esperando al anfitrión…")
	_start_btn.visible = is_host
	_build_maps(is_host)

func _on_players(players: Array) -> void:
	_refresh_players(players)

func _refresh_players(players: Array) -> void:
	if not players.is_empty():
		var names := []
		for p in players:
			names.append(String(p.get("name", "?")) + ("  (anfitrión)" if bool(p.get("host", false)) else ""))
		_players_lbl.text = " vs ".join(names) if names.size() > 1 else (names[0] + "  ·  esperando rival…")
		# host can start when 2 players are present
		if _start_btn.visible:
			_start_btn.disabled = players.size() < 2

func _on_match_start(seed: int, map: int, decks: Array) -> void:
	NetSession.dlog("start recibido: %d bytes, decks=%d" % [
		NetSession.client.last_start_bytes(), decks.size()])
	NetSession.build_match(decks, NetSession.seat, seed, map)
	# VALIDAR EN DESTINO: si algún mazo llegó vacío/roto, quedarse AQUÍ con el
	# motivo visible (antes: ir al tablero → rebote mudo al menú, sin pista).
	var n0 := NetSession.team_p0.size()
	var n1 := NetSession.team_p1.size()
	if n0 < Loadout.DECK_SIZE or n1 < Loadout.DECK_SIZE:
		NetSession.end_online()
		_status.text = "⚠ La partida no pudo empezar: llegó un mazo roto (anfitrión %d/6, invitado %d/6). Revisen que AMBOS teléfonos tengan la versión red v%d." % [n0, n1, NetSession.NET_BUILD]
		NetSession.dlog("start ABORTADO en lobby: team0=%d team1=%d" % [n0, n1])
		return
	Loadout.map_index = map
	get_tree().change_scene_to_file("res://scenes/board.tscn")

func _leave() -> void:
	if _in_room:
		NetSession.client.leave_room()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

## Modal con la cola de la bitácora online + botón copiar (para reportes).
func _show_log() -> void:
	var txt := "(sin bitácora aún)"
	if FileAccess.file_exists(NetSession.DEBUG_LOG):
		var f := FileAccess.open(NetSession.DEBUG_LOG, FileAccess.READ)
		if f != null:
			var lines := f.get_as_text().split("\n")
			f.close()
			var tail := lines.slice(maxi(0, lines.size() - 40))
			txt = "\n".join(tail)
	var dlg := AcceptDialog.new()
	dlg.title = "📶 Bitácora online (red v%d)" % NetSession.NET_BUILD
	dlg.ok_button_text = "Cerrar"
	var te := TextEdit.new()
	te.text = txt
	te.editable = false
	te.custom_minimum_size = Vector2(minf(430.0, size.x - 40.0), 340)
	dlg.add_child(te)
	dlg.add_button("Copiar", false, "copy")
	dlg.custom_action.connect(func(_a):
		DisplayServer.clipboard_set(txt)
		dlg.title = "📋 Copiada")
	add_child(dlg)
	dlg.popup_centered()

# ---------------------------------------------------------------- deck
## El mazo viaja SEPARADO: "team" = exactamente las figuras jugables (en orden,
## duplicados incluidos) y "lib" = el cierre de evoluciones (evolves_id), solo
## para renderizar/simular rank-ups. ANTES todo iba en UNA lista y el cierre la
## inflaba distinto en cada cliente -> uids/modelos desalineados (el caos online:
## controlar piezas del rival, modelos cambiados, pantallas distintas).
## FORMATO DE RED (v24): cada figura se EMPAQUETA (CustomFigures.wire_pack) —
## integradas como referencia, customs sin runtime — y el receptor rehidrata en
## NetSession.build_match. El payload pasa de decenas de KB a unos pocos KB.
func _my_deck() -> Dictionary:
	var team: Array = []
	var seen := {}
	for ri in Loadout.player_team:
		if ri >= 0 and ri < Roster.FIGURES.size():
			team.append(Roster.FIGURES[ri])
			seen[String(Roster.FIGURES[ri].get("id", ""))] = true
	var lib: Array = []
	var queue := team.duplicate()
	while not queue.is_empty():
		var f: Dictionary = queue.pop_front()
		for st in f.get("ranks", []):
			var eid := String(st.get("evolves_id", ""))
			if eid != "" and not seen.has(eid):
				seen[eid] = true
				for g in Roster.FIGURES:
					if String(g.get("id", "")) == eid:
						lib.append(g)
						queue.append(g)
						break
	var team_w: Array = []
	for f in team:
		team_w.append(CustomFigures.wire_pack(f))
	var lib_w: Array = []
	for f in lib:
		lib_w.append(CustomFigures.wire_pack(f))
	return {"team": team_w, "lib": lib_w}

# ---------------------------------------------------------------- maps / widgets
func _build_maps(is_host := true) -> void:
	for c in _map_box.get_children():
		c.queue_free()
	for i in MapData.count():
		var b := Button.new()
		b.text = MapData.display_name(i)
		b.toggle_mode = true
		b.button_pressed = (i == _map)
		b.disabled = not is_host
		b.custom_minimum_size = Vector2(0, 42)
		UITheme.button_font(b, 14, UITheme.TEXT, true, 700)
		if i == _map:
			UITheme.style_primary(b, UITheme.PRIMARY, 10)
		else:
			UITheme.style_surface(b, UITheme.SURFACE, UITheme.BORDER, 10)
		if is_host:
			b.pressed.connect(func():
				_map = i
				_build_maps(true)
				NetSession.client.set_map(i))
		_map_box.add_child(b)

func _field(parent: VBoxContainer, caption: String, val: String) -> LineEdit:
	# Campo con la etiqueta ENCIMA (§6.5), no al lado.
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	parent.add_child(box)
	var l := Label.new()
	l.text = caption
	UITheme.label(l, 12, UITheme.TEXT2, false, 600)
	box.add_child(l)
	var e := LineEdit.new()
	e.text = val
	e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	e.custom_minimum_size = Vector2(0, 44)
	_style_le(e)
	box.add_child(e)
	return e

## Estilo de campo de entrada (input bg, borde, foco azul, fuente Manrope).
func _style_le(e: LineEdit) -> void:
	e.add_theme_stylebox_override("normal", UITheme.input())
	e.add_theme_stylebox_override("focus", UITheme.input(UITheme.INPUT_BG, UITheme.PRIMARY))
	e.add_theme_color_override("font_color", UITheme.TEXT)
	e.add_theme_color_override("font_placeholder_color", UITheme.MUTED)
	e.add_theme_color_override("caret_color", UITheme.PRIMARY_EDGE)
	var mf := UITheme.body(600)
	if mf != null:
		e.add_theme_font_override("font", mf)

func _button(text: String, accent: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 52)
	if accent == UITheme.SURFACE:
		UITheme.button_font(b, 18, UITheme.TEXT, true, 800)
		UITheme.style_surface(b, UITheme.SURFACE, UITheme.BORDER, 14)
	else:
		# Texto oscuro sobre acentos claros (verde/oro) para mejor contraste (§6.5).
		var fg: Color = Color(0.03, 0.14, 0.06) if accent == UITheme.SUCCESS else (Color(0.16, 0.12, 0.02) if accent == UITheme.GOLD else Color.WHITE)
		UITheme.button_font(b, 18, fg, true, 800)
		UITheme.style_primary(b, accent, 14)
	return b

func _hdr(text: String) -> Label:
	var l := Label.new()
	UITheme.section(l, text)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _spacer() -> Control:
	var s := Control.new()
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return s

func _load_url() -> String:
	if FileAccess.file_exists(URL_PATH):
		var f := FileAccess.open(URL_PATH, FileAccess.READ)
		if f != null:
			var u := f.get_as_text().strip_edges()
			f.close()
			if u != "":
				return u
	return DEFAULT_URL

func _save_url(u: String) -> void:
	var f := FileAccess.open(URL_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(u.strip_edges())
		f.close()
