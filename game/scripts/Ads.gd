extends Node
## Autoload "Ads" — anuncios RECOMPENSADOS (rewarded). En Android CON el plugin
## de AdMob instalado muestra anuncios REALES (generan ingresos en tu cuenta);
## sin plugin (editor/PC, o mientras no lo instalas) SIMULA el anuncio para que
## el juego funcione igual. Guía de activación paso a paso: docs/Ads_Setup.md.
##
## Patrón tomado del proyecto de referencia (claudegnosiapp, Flutter
## google_mobile_ads): App ID de la MISMA cuenta, IDs de prueba en debug y el ID
## real en release, y se da la recompensa SOLO si el usuario completó el anuncio.

## App ID de AdMob (tu cuenta — el mismo del proyecto de referencia).
const APP_ID := "ca-app-pub-2708000886889061~5037795173"
## Rewarded de PRUEBA oficial de Google (no genera ingresos; seguro para probar).
const UNIT_TEST := "ca-app-pub-3940256099942544/5224354917"
## Rewarded REAL de NodeChess — créalo en AdMob y pégalo aquí (queda en release).
const UNIT_RELEASE := ""

## Nombres de singleton que exponen los plugins AdMob de Godot más comunes; si
## alguno existe en este build, usamos anuncios REALES por ahí.
const PLUGIN_NAMES := ["AdMob", "AdmobPlugin", "PoingGodotAdMob", "GodotAdMob"]

var _plugin = null
var _reward_pending := false
var _earned := false

func _ready() -> void:
	for n in PLUGIN_NAMES:
		if Engine.has_singleton(n):
			_plugin = Engine.get_singleton(n)
			break
	if _plugin != null:
		# La inicialización EXACTA depende del plugin instalado (ver Ads_Setup.md):
		# típicamente _plugin.initialize() + conectar su señal de recompensa y
		# precargar un rewarded. Se deja como hook para no atarse a una API.
		if _plugin.has_signal("rewarded_user_earned_reward"):
			_plugin.connect("rewarded_user_earned_reward", func(_a = null, _b = null): _earned = true)
		if _plugin.has_method("initialize"):
			_plugin.call("initialize")

## ¿Hay anuncios REALES disponibles (plugin presente)?
func available() -> bool:
	return _plugin != null

## Ad unit a usar según el build (release usa el real si está configurado).
func _unit() -> String:
	if OS.is_debug_build() or UNIT_RELEASE == "":
		return UNIT_TEST
	return UNIT_RELEASE

## Muestra un anuncio recompensado. Devuelve true SOLO si el usuario lo completó
## (así se da la recompensa). Con plugin: espera su callback; sin plugin: simula.
func show_rewarded() -> bool:
	if _plugin == null:
		return true   # SIMULADO: sin plugin, la UI ya mostró "Viendo anuncio…"
	# --- rama REAL (cuando haya plugin) ---
	_earned = false
	if _plugin.has_method("load_rewarded"):
		_plugin.call("load_rewarded", _unit())
	if _plugin.has_method("show_rewarded"):
		_plugin.call("show_rewarded")
		# esperar a que el usuario cierre el anuncio (hasta ~60 s)
		var waited := 0.0
		while waited < 60.0 and not _earned:
			await get_tree().create_timer(0.25).timeout
			waited += 0.25
		return _earned
	return true
