extends Node
## Ajustes del jugador (autoload "Settings"): volúmenes de música y SFX,
## persistidos en user://settings.json y aplicados al arrancar.

const PATH := "user://settings.json"

var music_vol := 0.8
var sfx_vol := 0.8

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

func _save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"music": music_vol, "sfx": sfx_vol}))
		f.close()
