extends Node
## Autoload. Holds the live NetClient and the online-match parameters across scenes.
## Perspective is handled WITHOUT mirroring the logic: both clients run the IDENTICAL
## canonical GameState (same shared roster order -> same uids/nodes), and each client
## just puts the CAMERA on its own side so it sees itself at the bottom. Actions
## therefore reference canonical uids/nodes and mean the same on both ends.

signal net_paused(paused: bool)   # true = perdimos el socket en partida (reconectando)

var client                       # NetClient
var online := false
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
## it identically, so unit ids line up on both ends).
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
		by_seat[int(d.get("seat", 0))] = d.get("deck", [])
		if int(d.get("seat", 0)) != my_seat:
			opp_name = String(d.get("name", "Rival"))
	decks_by_seat = by_seat
	for f in team_of(by_seat[0]):
		team_p0.append(match_roster.size())
		match_roster.append(f)
	for f in team_of(by_seat[1]):
		team_p1.append(match_roster.size())
		match_roster.append(f)

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
