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

## Ventana total de reintentos para el arranque en frio de Render free (~30-60s).
## Son "var" (no const) para que los tests puedan acortarlas.
var wake_window := 180.0
var retry_delay := 4.0     # espera entre reintentos mientras el servidor enciende
var ws_timeout := 20.0     # timeout de UN intento de WS (tras el wake el server ya responde)
var wake_timeout := 70.0   # timeout del GET de despertar (Render puede retenerlo ~50s)

var _ws := WebSocketPeer.new()
var _open := false
var _connecting := false
var _ws_url := ""
var _connect_t := 0.0
var _ws_retries := 0
var _retry_wait := 0.0     # >0: esperando para volver a intentar (servidor encendiendo)
var _start_ms := 0         # inicio del connect_to() actual (ventana total)
var _remote := false       # wss:// (Render: puede dormir) vs ws:// local
var _active := false       # hay un intento de conexion en curso (wake + WS + reintentos)
var _http: HTTPRequest

func _ensure_http() -> void:
	if _http != null:
		return
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_wake_done)

func connect_to(url: String) -> void:
	_ensure_http()
	_ws_url = url
	_open = false
	_connecting = false
	_ws_retries = 0
	_retry_wait = 0.0
	_active = true
	_start_ms = Time.get_ticks_msec()
	_remote = _ws_url.begins_with("wss://") or _ws_url.begins_with("https://")
	# Render free DUERME; un WS directo a un server dormido se cae. Un GET normal SI lo
	# despierta (~50s). Por eso: primero un GET; solo abrimos el WS cuando responde OK.
	if _remote:
		connecting_status.emit("Despertando servidor… espera ~1 min sin cerrar (reintenta solo)")
		_wake()
	else:
		_open_ws()   # servidor local (ws://): no duerme

## GET al server: lo despierta si duerme y a la vez confirma si ya esta encendido.
func _wake() -> void:
	if not is_inside_tree():
		_retry_wait = 0.1   # aun no entramos al arbol; reintentar en el primer frame
		return
	_http.cancel_request()
	_http.timeout = wake_timeout
	var http_url := _ws_url.replace("wss://", "https://")
	if _http.request(http_url) != OK:
		_open_ws()   # no se pudo lanzar el GET; probamos el WS directo

func _on_wake_done(result: int, code: int, _h: PackedStringArray, _b: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and code >= 200 and code < 400:
		connecting_status.emit("Servidor listo. Conectando a la sala…")
		_open_ws()
	else:
		# Aun no responde (sigue encendiendo, 5xx del proxy, o timeout): reintentar.
		_retry_or_fail("despertando servidor")

func _elapsed() -> float:
	return float(Time.get_ticks_msec() - _start_ms) / 1000.0

func _open_ws() -> void:
	_ws = WebSocketPeer.new()
	_connecting = true
	_connect_t = 0.0
	if _ws.connect_to_url(_ws_url) != OK:
		_connecting = false
		error_msg.emit("No se pudo iniciar la conexión")

func is_open() -> bool:
	return _open

## True mientras un intento de conexion sigue vivo (despertando, abriendo WS o
## esperando el siguiente reintento). La UI lo usa para no reiniciar el intento
## en cada toque: reiniciar cancela el GET que esta despertando a Render.
func is_connecting() -> bool:
	return _active and not _open

func close() -> void:
	if _http != null:
		_http.cancel_request()
	_ws.close()
	_open = false
	_connecting = false
	_active = false
	_retry_wait = 0.0

func _process(delta: float) -> void:
	if _retry_wait > 0.0:
		_retry_wait -= delta
		if _retry_wait <= 0.0:
			# Volver a preguntar si ya encendio (el GET tambien lo despierta).
			if _remote:
				_wake()
			else:
				_open_ws()
		return
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
				_active = false
				connected.emit()
			while _ws.get_available_packet_count() > 0:
				_handle(_ws.get_packet().get_string_from_utf8())
		WebSocketPeer.STATE_CONNECTING:
			if _connecting and _connect_t > ws_timeout:
				_retry_or_fail("tardó demasiado")
		WebSocketPeer.STATE_CLOSED:
			if _open:
				_open = false
				disconnected.emit()
			elif _connecting:
				_retry_or_fail("cerrado cod %d" % _ws.get_close_code())

## Un intento fallo. Con Render el server puede estar ENCENDIENDO (30-60s): en vez de
## rendirnos, esperamos unos segundos y volvemos a intentar durante toda la ventana.
func _retry_or_fail(reason: String) -> void:
	_connecting = false
	if _remote and _elapsed() < wake_window:
		_ws_retries += 1
		_retry_wait = retry_delay
		connecting_status.emit("Servidor encendiendo… reintento %d (llevo %ds)" % [_ws_retries, int(_elapsed())])
	elif not _remote and _ws_retries < 3:
		_ws_retries += 1
		connecting_status.emit("Reintentando… (%d)" % _ws_retries)
		_open_ws()
	else:
		_active = false
		error_msg.emit("Sin conexión al servidor [" + reason + "]. Vuelve a pulsar para reintentar.")

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
