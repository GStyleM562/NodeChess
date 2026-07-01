class_name NetClient
extends Node
## NodeChess network client (WebSocket over the relay server). Keeps the socket,
## parses JSON messages and re-emits them as signals. The rules engine runs LOCALLY
## on each client (deterministic); the active player resolves its attack and sends the
## result. Adapted from the NODE RACERS net client (same Godot pattern).

signal connected
signal disconnected
signal error_msg(text: String)
signal connecting_status(text: String)
signal room_created(code: String, you: int, players: Array)
signal room_joined(code: String, you: int, players: Array)
signal players_updated(players: Array)
signal room_map(map: int)
signal match_start(seed: int, map: int, decks: Array)
signal remote_action(action: Dictionary)
signal player_left(id: int)

var _ws := WebSocketPeer.new()
var _open := false
var _connecting := false
var _ws_url := ""
var _connect_t := 0.0
var _ws_retries := 0
var _http: HTTPRequest

func _ensure_http() -> void:
	if _http != null:
		return
	_http = HTTPRequest.new()
	add_child(_http)
	_http.timeout = 70.0   # el arranque en frio de Render free puede tardar ~50s
	_http.request_completed.connect(_on_wake_done)

func connect_to(url: String) -> void:
	_ensure_http()
	_ws_url = url
	_open = false
	_ws_retries = 0
	# Render free DUERME; un WS directo a un server dormido se cae. Un GET normal SI lo
	# despierta (~50s). Por eso: primero un GET para despertar, luego abrimos el WS.
	if _ws_url.begins_with("wss://") or _ws_url.begins_with("https://"):
		connecting_status.emit("Despertando servidor… (puede tardar ~50s la primera vez)")
		_http.cancel_request()
		var http_url := _ws_url.replace("wss://", "https://")
		if _http.request(http_url) != OK:
			_open_ws()
	else:
		_open_ws()   # servidor local (ws://): no duerme

func _on_wake_done(_r: int, _c: int, _h: PackedStringArray, _b: PackedByteArray) -> void:
	connecting_status.emit("Conectando a la sala…")
	_open_ws()

func _open_ws() -> void:
	_ws = WebSocketPeer.new()
	_connecting = true
	_connect_t = 0.0
	if _ws.connect_to_url(_ws_url) != OK:
		_connecting = false
		error_msg.emit("No se pudo iniciar la conexión")

func is_open() -> bool:
	return _open

func close() -> void:
	_ws.close()
	_open = false
	_connecting = false

func _process(delta: float) -> void:
	if not _connecting and not _open:
		return
	if _connecting:
		_connect_t += delta
	_ws.poll()
	match _ws.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if not _open:
				_open = true
				_connecting = false
				connected.emit()
			while _ws.get_available_packet_count() > 0:
				_handle(_ws.get_packet().get_string_from_utf8())
		WebSocketPeer.STATE_CONNECTING:
			if _connecting and _connect_t > 45.0:
				_retry_or_fail("tardó demasiado")
		WebSocketPeer.STATE_CLOSED:
			if _open:
				_open = false
				disconnected.emit()
			elif _connecting:
				_retry_or_fail("cerrado cod %d" % _ws.get_close_code())

func _retry_or_fail(reason: String) -> void:
	if _ws_retries < 3:
		_ws_retries += 1
		connecting_status.emit("Reintentando… (%d)" % _ws_retries)
		_open_ws()
	else:
		_connecting = false
		error_msg.emit("Sin conexión al servidor [" + reason + "]")

func _handle(text: String) -> void:
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return
	match String(data.get("t", "")):
		"created":
			room_created.emit(String(data["code"]), int(data["you"]), data.get("players", []))
		"joined":
			room_joined.emit(String(data["code"]), int(data["you"]), data.get("players", []))
		"players":
			players_updated.emit(data.get("players", []))
		"room":
			room_map.emit(int(data["map"]))
		"start":
			match_start.emit(int(data["seed"]), int(data["map"]), data.get("decks", []))
		"action":
			remote_action.emit(data.get("action", {}))
		"left":
			player_left.emit(int(data.get("id", -1)))
		"error":
			error_msg.emit(String(data.get("msg", "Error")))

func _send(obj: Dictionary) -> void:
	if _open:
		_ws.send_text(JSON.stringify(obj))

# --- API --------------------------------------------------------------------
func create_room(pname: String, deck: Array, map: int) -> void:
	_send({"t": "create", "name": pname, "deck": deck, "map": map})

func join_room(code: String, pname: String, deck: Array) -> void:
	_send({"t": "join", "code": code.to_upper(), "name": pname, "deck": deck})

func set_map(map: int) -> void:
	_send({"t": "setmap", "map": map})

func start_match() -> void:
	_send({"t": "start"})

func send_action(action: Dictionary) -> void:
	_send({"t": "action", "action": action})

func leave_room() -> void:
	_send({"t": "leave"})
