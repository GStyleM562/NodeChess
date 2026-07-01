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
	_url = _field(_panel_connect, "Servidor", _load_url())
	var create := _button("CREAR SALA", UITheme.SUCCESS)
	create.pressed.connect(_on_create)
	_panel_connect.add_child(create)
	var jr := HBoxContainer.new()
	jr.add_theme_constant_override("separation", 8)
	_panel_connect.add_child(jr)
	_code_in = LineEdit.new()
	_code_in.placeholder_text = "CÓDIGO"
	_code_in.max_length = 4
	_code_in.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	var back := _button("← Menú", UITheme.SURFACE)
	back.pressed.connect(_leave)
	root.add_child(back)

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

# ---------------------------------------------------------------- actions
func _on_create() -> void:
	_pending = "create"
	_status.text = "Conectando…"
	_save_url(_url.text)
	if NetSession.client.is_open():
		_on_connected()
	else:
		NetSession.client.connect_to(_url.text.strip_edges())

func _on_join() -> void:
	if _code_in.text.strip_edges().length() < 4:
		_status.text = "Escribe el código de 4 letras."
		return
	_pending = "join"
	_status.text = "Conectando…"
	_save_url(_url.text)
	if NetSession.client.is_open():
		_on_connected()
	else:
		NetSession.client.connect_to(_url.text.strip_edges())

func _on_connected() -> void:
	var pn := _name.text.strip_edges()
	if pn == "":
		pn = "Jugador"
	if _pending == "create":
		NetSession.client.create_room(pn, _my_deck(), _map)
	elif _pending == "join":
		NetSession.client.join_room(_code_in.text.strip_edges(), pn, _my_deck())
	_pending = ""

func _on_room_created(code: String, you: int, players: Array) -> void:
	NetSession.seat = you
	_enter_room(code, true)
	_refresh_players(players)

func _on_room_joined(code: String, you: int, players: Array) -> void:
	NetSession.seat = you
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
	NetSession.build_match(decks, NetSession.seat, seed, map)
	Loadout.map_index = map
	get_tree().change_scene_to_file("res://scenes/board.tscn")

func _leave() -> void:
	if _in_room:
		NetSession.client.leave_room()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# ---------------------------------------------------------------- deck
## The saved team as full figure dicts + any figures referenced by evolution
## (evolves_id closure), so the opponent can render and simulate them.
func _my_deck() -> Array:
	var out: Array = []
	var seen := {}
	var queue: Array = []
	for ri in Loadout.player_team:
		if ri >= 0 and ri < Roster.FIGURES.size():
			queue.append(Roster.FIGURES[ri])
	while not queue.is_empty():
		var f: Dictionary = queue.pop_front()
		var id := String(f.get("id", ""))
		if id == "" or seen.has(id):
			continue
		seen[id] = true
		out.append(f)
		for st in f.get("ranks", []):
			var eid := String(st.get("evolves_id", ""))
			if eid != "" and not seen.has(eid):
				for g in Roster.FIGURES:
					if String(g.get("id", "")) == eid:
						queue.append(g)
	return out

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
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	parent.add_child(hb)
	var l := Label.new()
	l.text = caption
	l.custom_minimum_size = Vector2(90, 0)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.label(l, 13, UITheme.TEXT2, false, 600)
	hb.add_child(l)
	var e := LineEdit.new()
	e.text = val
	e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(e)
	return e

func _button(text: String, accent: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 52)
	UITheme.button_font(b, 18, UITheme.TEXT, true, 800)
	if accent == UITheme.SURFACE:
		UITheme.style_surface(b, UITheme.SURFACE, UITheme.BORDER, 14)
	else:
		UITheme.style_primary(b, accent, 14)
	return b

func _hdr(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(l, 12, UITheme.MUTED, true, 700)
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
