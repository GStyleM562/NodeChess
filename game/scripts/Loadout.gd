extends RefCounted
class_name Loadout
## Holds the player's chosen team between the Deck Builder and the match.
## A team is a list of roster indices (rindex into Roster.FIGURES); duplicates
## allowed. Static so it survives scene changes without an autoload.

const DECK_SIZE := 5

static var player_team: Array = [0, 1, 2, 3, 4]   # default until the player picks
# A fixed, reasonable opponent deck (the smarter-CPU task can vary this later).
static var enemy_team: Array = [1, 0, 2, 4, 5]

# Equipped modifier cards (ids into GameState.MODIFIERS), up to 3.
static var player_modifiers: Array = ["power_surge", "cleanse", "adrenaline"]

# Chosen map (index into MapData layouts).
static var map_index := 0

static func valid(team: Array) -> bool:
	return team.size() == DECK_SIZE

# --- persistence ------------------------------------------------------------
# Saved by FIGURE ID (not roster index), so it survives custom figures being
# added/removed between sessions. Loaded at startup (GameBoot), after custom
# figures are merged into the roster.
const PATH := "user://loadout.json"

static func save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"team": _ids_of(player_team),
		"mods": player_modifiers,
		"map": map_index,
	}, "\t"))
	f.close()

static func load() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return
	var team := _indices_of(data.get("team", []))
	if team.size() == DECK_SIZE:
		player_team = team
	var mods: Array = data.get("mods", [])
	var vm: Array = []
	for m in mods:
		if GameState.MODIFIERS.has(String(m)) and vm.size() < 3:
			vm.append(String(m))
	if not vm.is_empty():
		player_modifiers = vm
	map_index = clampi(int(data.get("map", 0)), 0, MapData.count() - 1)

static func _ids_of(team: Array) -> Array:
	var out: Array = []
	for ri in team:
		if ri >= 0 and ri < Roster.FIGURES.size():
			out.append(String(Roster.FIGURES[ri].get("id", "")))
	return out

static func _indices_of(ids: Array) -> Array:
	var out: Array = []
	for id in ids:
		for i in Roster.FIGURES.size():
			if String(Roster.FIGURES[i].get("id", "")) == String(id):
				out.append(i)
				break
	return out
