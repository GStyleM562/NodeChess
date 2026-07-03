extends Node
## Efectos de sonido (autoload "Sfx"). Un slot = una carpeta en assets/audio/sfx/;
## se reproduce el PRIMER .mp3/.ogg/.wav de la carpeta. Carpeta vacía → silencio
## (todo queda cableado desde ya; al soltar los archivos suenan solos).
##   ui_click       — cualquier botón de la interfaz
##   end_turn       — al terminar turno
##   deploy         — al desplegar una figura
##   attack_hit     — golpe ganador Blanco/Oro
##   attack_block   — bloqueo Azul
##   attack_effect  — efecto Púrpura aplicado
##   attack_miss    — empate / fallo
##   ko             — figura noqueada
##   rankup         — evolución en partida
##   victory        — ganaste la partida
##   defeat         — perdiste la partida

const BASE := "res://assets/audio/sfx"
const VOL_DB := -4.0
const POOL := 6

var _cache := {}                       # slot -> AudioStream (o null)
var _pool: Array[AudioStreamPlayer] = []
var _next := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_pool()

## Perezoso: en tests (--script) los autoloads existen antes de su _ready.
func _ensure_pool() -> void:
	if not _pool.is_empty():
		return
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.volume_db = VOL_DB
		add_child(p)
		_pool.append(p)

func play(slot: String) -> void:
	_ensure_pool()
	var st := _stream(slot)
	if st == null:
		return
	var p := _pool[_next]
	_next = (_next + 1) % POOL
	p.stream = st
	p.play()

## Volumen del usuario (0..1) aplicado a todo el pool.
func set_volume(v: float) -> void:
	_ensure_pool()
	var db := -60.0 if v <= 0.01 else VOL_DB + linear_to_db(clampf(v, 0.0, 1.0))
	for p in _pool:
		p.volume_db = db

func _stream(slot: String) -> AudioStream:
	if _cache.has(slot):
		return _cache[slot]
	var st: AudioStream = null
	var dir := BASE + "/" + slot
	var d := DirAccess.open(dir)
	if d != null:
		for f in d.get_files():
			var fname := f.trim_suffix(".remap").trim_suffix(".import")
			if fname.ends_with(".mp3") or fname.ends_with(".ogg") or fname.ends_with(".wav"):
				st = load(dir + "/" + fname) as AudioStream
				break
	_cache[slot] = st
	return st
