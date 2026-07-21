extends Node
## Ajustes del jugador (autoload "Settings"): volúmenes de música y SFX,
## persistidos en user://settings.json y aplicados al arrancar.

const PATH := "user://settings.json"

var music_vol := 0.8
var sfx_vol := 0.8
var board_view := "3d"   # "3d" = losetas Meshy · "2d" = tablero digital (solo visual)
var favorites: Array = []   # ids de figuras marcadas ⭐ en la Colección
var cpu_level := 2       # dificultad vs CPU: 0 fácil · 1 media · 2 difícil
var combat_speed := 1    # 1 = normal · 2 = combates al doble de velocidad
var colorblind := false  # paleta alternativa + símbolos por color de ataque
var tutorial_done := false
var tuts_done: Array = []   # capítulos del FULL tutorial superados (ids)
var player_name := "Jugador"   # nombre del jugador (Perfil/Home/online)
var dark_mode := false      # tema oscuro (Configuración); claro por defecto

func set_dark_mode(v: bool) -> void:
	dark_mode = v
	UITheme.apply_theme(v)
	_save()

## Nombre saneado (1–16 chars, sin vacíos). Fallback "Jugador".
func name_or_default() -> String:
	var n := player_name.strip_edges()
	return n if n != "" else "Jugador"

## Iniciales para el avatar (hasta 2 letras de las primeras palabras).
func name_initials() -> String:
	var parts := name_or_default().split(" ", false)
	if parts.size() >= 2:
		return (parts[0].substr(0, 1) + parts[1].substr(0, 1)).to_upper()
	return name_or_default().substr(0, 2).to_upper()

func set_player_name(v: String) -> void:
	player_name = v.strip_edges().substr(0, 16)
	_save()

func _ready() -> void:
	_load()
	_apply()
	UITheme.apply_theme(dark_mode)   # fija el tema ANTES de construir pantallas

func set_music(v: float) -> void:
	music_vol = clampf(v, 0.0, 1.0)
	_apply()
	_save()

func set_sfx(v: float) -> void:
	sfx_vol = clampf(v, 0.0, 1.0)
	_apply()
	_save()

func set_board_view(v: String) -> void:
	board_view = "2d" if v == "2d" else "3d"
	_save()

func set_cpu_level(v: int) -> void:
	cpu_level = clampi(v, 0, 2)
	_save()

func set_combat_speed(v: int) -> void:
	combat_speed = 2 if v >= 2 else 1
	_save()

func set_colorblind(v: bool) -> void:
	colorblind = v
	_save()

func set_tutorial_done(v: bool) -> void:
	tutorial_done = v
	_save()

## Marca un capítulo del FULL tutorial como superado (idempotente).
func mark_tut(id: String) -> void:
	if id not in tuts_done:
		tuts_done.append(id)
		_save()

func is_favorite(id: String) -> bool:
	return id in favorites

func toggle_favorite(id: String) -> void:
	if id in favorites:
		favorites.erase(id)
	else:
		favorites.append(id)
	_save()

func _apply() -> void:
	Music.set_volume(music_vol)
	Sfx.set_volume(sfx_vol)

func _load() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Dictionary:
		music_vol = clampf(float(data.get("music", music_vol)), 0.0, 1.0)
		sfx_vol = clampf(float(data.get("sfx", sfx_vol)), 0.0, 1.0)
		board_view = "2d" if String(data.get("board", "3d")) == "2d" else "3d"
		favorites = data.get("favs", [])
		cpu_level = clampi(int(data.get("cpu", 2)), 0, 2)
		combat_speed = 2 if int(data.get("speed", 1)) >= 2 else 1
		colorblind = bool(data.get("cb", false))
		tutorial_done = bool(data.get("tut", false))
		tuts_done = data.get("tuts", [])
		player_name = String(data.get("pname", "Jugador"))
		dark_mode = bool(data.get("dark", false))

func _save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"music": music_vol, "sfx": sfx_vol, "board": board_view,
			"favs": favorites, "cpu": cpu_level, "speed": combat_speed, "cb": colorblind,
			"tut": tutorial_done, "tuts": tuts_done, "pname": player_name,
			"dark": dark_mode}))
		f.close()
