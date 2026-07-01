extends Node
## Autoload. Holds the live NetClient and the online-match parameters across scenes.
## Perspective is handled WITHOUT mirroring the logic: both clients run the IDENTICAL
## canonical GameState (same shared roster order -> same uids/nodes), and each client
## just puts the CAMERA on its own side so it sees itself at the bottom. Actions
## therefore reference canonical uids/nodes and mean the same on both ends.

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

func _ready() -> void:
	client = NetClient.new()
	client.name = "NetClient"
	add_child(client)

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
	for f in by_seat[0]:
		team_p0.append(match_roster.size())
		match_roster.append(f)
	for f in by_seat[1]:
		team_p1.append(match_roster.size())
		match_roster.append(f)

func end_online() -> void:
	online = false
	if client != null:
		client.leave_room()
