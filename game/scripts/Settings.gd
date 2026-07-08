extends Node
## Ajustes del jugador (autoload "Settings"): volúmenes de música y SFX,
## persistidos en user://settings.json y aplicados al arrancar.

const PATH := "user://settings.json"

var music_vol := 0.8
var sfx_vol := 0.8
var board_view := "3d"   # "3d" = losetas Meshy · "2d" = tablero digital (solo visual)
var favorites: Array = []   # ids de figuras marcadas ⭐ en la Colección
var cpu_level := 2       # dificultad vs CPU: 0 fácil · 1 media · 2 difícil

func _ready() -> void:
	_load()
	_apply()

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

func _save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"music": music_vol, "sfx": sfx_vol, "board": board_view, "favs": favorites, "cpu": cpu_level}))
		f.close()
