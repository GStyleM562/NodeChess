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
