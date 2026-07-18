extends Node
## Autoload. Holds the live NetClient and the online-match parameters across scenes.
## Perspective is handled WITHOUT mirroring the logic: both clients run the IDENTICAL
## canonical GameState (same shared roster order -> same uids/nodes), and each client
## just puts the CAMERA on its own side so it sees itself at the bottom. Actions
## therefore reference canonical uids/nodes and mean the same on both ends.

signal net_paused(paused: bool)   # true = perdimos el socket en partida (reconectando)

## Versión del PROTOCOLO de red del cliente. Se muestra en el lobby online para
## poder confirmar A SIMPLE VISTA que ambos teléfonos corren el mismo build
## (un cliente viejo emparejado con uno nuevo rompe la partida al empezar).
## Subirla cada vez que cambie el formato de los mensajes.
const NET_BUILD := 24

const DEBUG_LOG := "user://logs/online_debug.txt"

var client                       # NetClient
var online := false
var abort_reason := ""           # partida online abortada: el POR QUÉ (lo muestra el menú)
var seat := 0                    # 0 = host (canonical "player"), 1 = guest ("enemy")
var seed := 0
var map := 0
var match_roster: Array = []     # deck0 figures then deck1 figures (as dicts)
var team_p0: Array = []          # indices into match_roster (canonical player team)
var team_p1: Array = []          # (canonical enemy team)
var decks_by_seat := {0: [], 1: []}   # raw deck (figure dicts) per seat
var opp_name := "Rival"
var server_url := ""             # para RECONECTAR en medio de una partida
var room_code := ""
var _rejoin_pending := false

func _ready() -> void:
	client = NetClient.new()
	client.name = "NetClient"
	add_child(client)
	client.disconnected.connect(_on_socket_drop)
	client.connected.connect(_on_socket_up)
	client.rejoined.connect(_on_rejoined)

## RECONEXIÓN automática: si el socket cae EN PARTIDA, reintenta (con el mismo
## wake patient de Render) y al abrir manda "rejoin" con el código y asiento.
func _on_socket_drop() -> void:
	if online and room_code != "" and server_url != "":
		_rejoin_pending = true
		net_paused.emit(true)
		client.connect_to(server_url)

func _on_socket_up() -> void:
	if _rejoin_pending:
		client.rejoin(room_code, seat)

func _on_rejoined(_code: String, _you: int, _map: int) -> void:
	_rejoin_pending = false
	net_paused.emit(false)

## My canonical team name given my seat (seat 0 -> "player", seat 1 -> "enemy").
func my_team() -> String:
	return "player" if seat == 0 else "enemy"

## Build the shared match roster + teams from the START payload (both clients build
## it identically, so unit ids line up on both ends). Los mazos llegan en formato
## de RED (referencias + customs sin runtime) y aquí se REHIDRATAN contra el
## roster local — por eso debe correr ANTES de que el tablero swapee el roster.
func build_match(decks: Array, my_seat: int, s: int, m: int) -> void:
	online = true
	seat = my_seat
	seed = s
	map = m
	match_roster = []
	team_p0 = []
	team_p1 = []
	var by_seat := {0: [], 1: []}
	for d in decks:
		by_seat[int(d.get("seat", 0))] = _unpack_deck(d.get("deck", []))
		if int(d.get("seat", 0)) != my_seat:
			opp_name = String(d.get("name", "Rival"))
	decks_by_seat = by_seat
	for f in team_of(by_seat[0]):
		team_p0.append(match_roster.size())
		match_roster.append(f)
	for f in team_of(by_seat[1]):
		team_p1.append(match_roster.size())
		match_roster.append(f)
	dlog("build_match: seat=%d seed=%d map=%d team0=%d team1=%d" % [
		my_seat, s, m, team_p0.size(), team_p1.size()])

## Rehidrata un payload de mazo recibido: {"team": [...], "lib": [...]} (o Array
## legado). Cada entrada pasa por CustomFigures.wire_unpack; las irrecuperables
## se DESCARTAN y quedan en el log (el lobby valida los tamaños y avisa).
func _unpack_deck(payload) -> Dictionary:
	var team_in := team_of(payload)
	var lib_in := lib_of(payload)
	var team: Array = []
	var lib: Array = []
	for e in team_in:
		var f := CustomFigures.wire_unpack(e)
		if f.is_empty():
			dlog("figura de EQUIPO irrecuperable: %s" % JSON.stringify(e).left(120))
		else:
			team.append(f)
	for e in lib_in:
		var f := CustomFigures.wire_unpack(e)
		if f.is_empty():
			dlog("figura de LIB irrecuperable: %s" % JSON.stringify(e).left(120))
		else:
			lib.append(f)
	return {"team": team, "lib": lib}

## Bitácora online persistente (user://logs/online_debug.txt) + consola. Para
## poder ver EN EL TELÉFONO qué pasó cuando algo online sale mal.
func dlog(msg: String) -> void:
	var line := "[%s] %s" % [Time.get_datetime_string_from_system(), msg]
	print("[NET] " + line)
	DirAccess.make_dir_recursive_absolute("user://logs")
	var f := FileAccess.open(DEBUG_LOG, FileAccess.READ_WRITE if FileAccess.file_exists(DEBUG_LOG) else FileAccess.WRITE)
	if f != null:
		f.seek_end()
		f.store_line(line)
		f.close()

## Figuras JUGABLES de un payload de mazo. Formato nuevo {"team": [...], "lib":
## [...]} o legado (Array plano = todo era equipo).
static func team_of(payload) -> Array:
	if payload is Dictionary:
		return payload.get("team", [])
	return payload if payload is Array else []

## Biblioteca (cierre de evoluciones) de un payload de mazo — solo para render.
static func lib_of(payload) -> Array:
	if payload is Dictionary:
		return payload.get("lib", [])
	return []

func end_online() -> void:
	online = false
	if client != null:
		client.leave_room()
