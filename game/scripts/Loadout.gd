extends RefCounted
class_name Loadout
## Holds the player's chosen team between the Deck Builder and the match.
## A team is a list of roster indices (rindex into Roster.FIGURES); duplicates
## allowed. Static so it survives scene changes without an autoload.

const DECK_SIZE := 6   # GDD: exactamente 6 figuras por jugador

static var player_team: Array = [0, 1, 2, 3, 4, 6]   # default until the player picks
# A fixed, reasonable opponent deck (the smarter-CPU task can vary this later).
# Sin storm_valkyrie (índice 5): su modelo "ave" está buggeado y tapa la pantalla.
static var enemy_team: Array = [1, 0, 2, 4, 3, 6]

# Equipped modifier cards (ids into GameState.MODIFIERS), up to 3.
static var player_modifiers: Array = ["power_surge", "cleanse", "adrenaline"]

# Chosen map (index into MapData layouts).
static var map_index := 0

# TUTORIAL guiado: la próxima partida arranca en modo tutorial (CPU pasiva).
static var tutorial := false
# LECCIÓN guionada del FULL tutorial ("" = ninguna): id de TutorialLib.lesson().
static var lesson := ""

static func valid(team: Array) -> bool:
	return team.size() == DECK_SIZE

# --- MULTI-MAZOS (GDD: hasta 20 con pestañas) --------------------------------
const MAX_DECKS := 20
## Cada mazo guardado: {"name": String, "team": [ids], "mods": [ids], "map": int}.
static var decks: Array = []
static var active_deck := 0

## Vuelca el mazo ACTIVO (player_team/mods/map actuales) a su ranura.
static func stash_active() -> void:
	while decks.size() <= active_deck:
		decks.append({"name": "Mazo %d" % (decks.size() + 1), "team": [], "mods": [], "map": 0})
	decks[active_deck] = {
		"name": String((decks[active_deck] as Dictionary).get("name", "Mazo %d" % (active_deck + 1))),
		"team": _ids_of(player_team), "mods": player_modifiers.duplicate(), "map": map_index,
	}

## Activa la ranura i (cargando su equipo/mods/mapa a las vars vivas). El mazo
## activo es EL MAZO EN USO: el que juega ONLINE y vs CPU. `stash=false` permite
## activar sin volcar antes el estado actual (p. ej. tras BORRAR un mazo, para
## no pisar la ranura destino con el contenido del mazo muerto).
static func switch_deck(i: int, stash := true) -> void:
	if stash:
		stash_active()
	active_deck = clampi(i, 0, maxi(0, decks.size() - 1))
	if decks.is_empty():
		save()
		return
	var d: Dictionary = decks[active_deck]
	# Cargar el equipo REAL del mazo (aunque esté incompleto): lo que ves es lo
	# que hay; jugar se bloquea en el builder y en el lobby si no está 6/6.
	player_team = _indices_of(d.get("team", []))
	player_modifiers = (d.get("mods", player_modifiers) as Array).duplicate()
	map_index = clampi(int(d.get("map", 0)), 0, MapData.count() - 1)
	save()

## ¿El mazo EN USO está listo para jugar? (exactamente DECK_SIZE figuras)
static func active_ready() -> bool:
	return valid(player_team)

## Nombre del mazo EN USO (para mostrarlo en el lobby online).
static func active_name() -> String:
	if not decks.is_empty() and active_deck < decks.size():
		return String((decks[active_deck] as Dictionary).get("name", "Mazo %d" % (active_deck + 1)))
	return "Mazo 1"

## Código NCDECK1 para compartir el mazo activo.
static func deck_code() -> String:
	stash_active()
	var bytes := JSON.stringify(decks[active_deck]).to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP)
	return "NCDECK1." + Marshalls.raw_to_base64(bytes)

## Importa un código NCDECK1 como mazo NUEVO. Figuras desconocidas se omiten.
## -> {"ok": bool, "name": String, "missing": int}
static func import_deck_code(code: String) -> Dictionary:
	var c := code.strip_edges().replace("\n", "").replace("\r", "").replace(" ", "")
	if not c.begins_with("NCDECK1."):
		return {"ok": false, "name": "", "missing": 0}
	var bytes := Marshalls.base64_to_raw(c.substr(8))
	if bytes.is_empty():
		return {"ok": false, "name": "", "missing": 0}
	var raw := bytes.decompress_dynamic(1 << 20, FileAccess.COMPRESSION_GZIP)
	var data = JSON.parse_string(raw.get_string_from_utf8()) if not raw.is_empty() else null
	if not (data is Dictionary) or decks.size() >= MAX_DECKS:
		return {"ok": false, "name": "", "missing": 0}
	var ids: Array = data.get("team", [])
	var found := _indices_of(ids)
	stash_active()
	decks.append({
		"name": String(data.get("name", "Importado")),
		"team": _ids_of(found), "mods": data.get("mods", []), "map": int(data.get("map", 0)),
	})
	save()
	return {"ok": true, "name": String(data.get("name", "Importado")), "missing": ids.size() - found.size()}

# --- persistence ------------------------------------------------------------
# Saved by FIGURE ID (not roster index), so it survives custom figures being
# added/removed between sessions. Loaded at startup (GameBoot), after custom
# figures are merged into the roster. v2 = multi-mazos (migra v1 en silencio).
const PATH := "user://loadout.json"

static func save() -> void:
	stash_active()
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"v": 2, "active": active_deck, "decks": decks,
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
	if int(data.get("v", 1)) >= 2:
		decks = data.get("decks", [])
		active_deck = clampi(int(data.get("active", 0)), 0, maxi(0, decks.size() - 1))
		if decks.is_empty():
			return
		var d: Dictionary = decks[active_deck]
		var team := _indices_of(d.get("team", []))
		if not team.is_empty():
			player_team = team   # equipos de otro tamaño se restauran igual (el builder los completa)
		_load_mods(d.get("mods", []))
		map_index = clampi(int(d.get("map", 0)), 0, MapData.count() - 1)
		return
	# v1 (un solo mazo) -> migrar a la ranura 0
	var team1 := _indices_of(data.get("team", []))
	if not team1.is_empty():
		player_team = team1
	_load_mods(data.get("mods", []))
	map_index = clampi(int(data.get("map", 0)), 0, MapData.count() - 1)
	stash_active()

static func _load_mods(mods: Array) -> void:
	var vm: Array = []
	for m in mods:
		if GameState.MODIFIERS.has(String(m)) and vm.size() < 3:
			vm.append(String(m))
	if not vm.is_empty():
		player_modifiers = vm

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
