extends Node
## Música global (autoload "Music"). Cuatro pistas por carpeta:
##   assets/audio/music/menu/       — menú y pantallas fuera de partida
##   assets/audio/music/battle/     — partida normal
##   assets/audio/music/advantage/  — TU figura a ≤3 nodos de la meta rival (positiva)
##   assets/audio/music/danger/     — figura RIVAL a ≤3 nodos de tu meta (peligro)
## Se usa el PRIMER .mp3/.ogg/.wav de cada carpeta; sin archivo → silencio (no crashea).
## Crossfade entre pistas; si el peligro/ventaja desaparece vuelve a "battle", y si
## reaparece se vuelve a disparar (estado recalculado tras cada acción del tablero).

const SLOT_DIRS := {
	"menu": "res://assets/audio/music/menu",
	"battle": "res://assets/audio/music/battle",
	"advantage": "res://assets/audio/music/advantage",
	"danger": "res://assets/audio/music/danger",
}
const VOL_DB := -8.0
const FADE := 0.7

var _a: AudioStreamPlayer
var _b: AudioStreamPlayer
var _front_is_a := true
var _cur := ""          # slot sonando ("" = silencio)
var _threat := ""       # "" | "advantage" | "danger"
var _in_battle := false
var _streams := {}      # slot -> AudioStream (o null si la carpeta está vacía)
var _user_vol := 1.0    # volumen del usuario 0..1 (Settings)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_players()

## Perezoso: en tests (--script) los autoloads existen antes de su _ready; cualquier
## entrada pública debe poder crear los players por sí misma.
func _ensure_players() -> void:
	if _a != null:
		return
	_a = AudioStreamPlayer.new()
	_b = AudioStreamPlayer.new()
	for p in [_a, _b]:
		p.volume_db = -60.0
		add_child(p)

# ---------------------------------------------------------------- API
func play_menu() -> void:
	_in_battle = false
	_threat = ""
	_switch("menu")

func play_battle() -> void:
	_in_battle = true
	_threat = ""
	_switch("battle")

## El tablero reporta el estado tras CADA acción: ventaja (yo a punto de ganar) y/o
## peligro (el rival a punto). Peligro manda si ocurren ambos. Sin ninguno → battle.
func update_threat(advantage: bool, danger: bool) -> void:
	if not _in_battle:
		return
	var want := "danger" if danger else ("advantage" if advantage else "")
	if want == _threat:
		return
	_threat = want
	_switch("battle" if want == "" else want)

func stop() -> void:
	_in_battle = false
	_cur = ""
	for p in [_a, _b]:
		create_tween().tween_property(p, "volume_db", -60.0, FADE)

## Volumen del usuario (0..1). Se aplica de inmediato a la pista sonando.
func set_volume(v: float) -> void:
	_ensure_players()
	_user_vol = clampf(v, 0.0, 1.0)
	var front := _a if _front_is_a else _b
	if front.playing:
		front.volume_db = _target_db()

func _target_db() -> float:
	return -60.0 if _user_vol <= 0.01 else VOL_DB + linear_to_db(_user_vol)

# ---------------------------------------------------------------- interno
func _switch(slot: String) -> void:
	_ensure_players()
	if slot == _cur:
		return
	_cur = slot
	var st := _stream(slot)
	var front := _a if _front_is_a else _b
	var back := _b if _front_is_a else _a
	create_tween().tween_property(front, "volume_db", -60.0, FADE)
	if st == null:
		return
	_front_is_a = not _front_is_a
	back.stream = st
	back.volume_db = -60.0
	back.play()
	create_tween().tween_property(back, "volume_db", _target_db(), FADE)

## Primer archivo de audio de la carpeta del slot (cache; null si no hay).
func _stream(slot: String) -> AudioStream:
	if _streams.has(slot):
		return _streams[slot]
	var st: AudioStream = null
	var dir := String(SLOT_DIRS.get(slot, ""))
	var d := DirAccess.open(dir)
	if d != null:
		for f in d.get_files():
			var fname := f.trim_suffix(".remap").trim_suffix(".import")
			if fname.ends_with(".mp3") or fname.ends_with(".ogg") or fname.ends_with(".wav"):
				st = load(dir + "/" + fname) as AudioStream
				break
	if st != null:
		_set_loop(st)
	_streams[slot] = st
	return st

func _set_loop(st: AudioStream) -> void:
	if st is AudioStreamMP3 or st is AudioStreamOggVorbis:
		st.set("loop", true)
	elif st is AudioStreamWAV:
		(st as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
