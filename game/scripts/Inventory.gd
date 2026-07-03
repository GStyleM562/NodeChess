extends Node
## Inventario + progresión (autoload "Inventory"). Base de la monetización:
## el jugador desbloquea PIEZAS del Creador (figuras/modelos, rarezas, tipos de
## ataque, colores de ataque, estados, pasivas y niveles de estamina) abriendo
## CAJAS. Las cajas dan FRAGMENTOS (10 fragmentos = 1 pieza completa) o, con
## suerte, piezas completas.
##
## Modos (Configuración ⚙): "admin" = todo desbloqueado e ilimitado (desarrollo);
## "user" = solo puede usar en el Creador las piezas que posee (regla dura).
## Persistencia total en user://inventory.json.
##
## Cajas:
##  - GRATIS: siempre abrible (por ahora) → fragmentos aleatorios.
##  - COFRES TEMPORALES (5/10/15 min POR RELOJ REAL — unix time, el timer corre
##    aunque la app esté cerrada): dan piezas COMPLETAS; a más espera, más piezas
##    y de mejor calidad. Al reclamar uno, SU timer rearma desde cero.
## Futuro (aún NO activo): jugar dará EXPERIENCIA y cada nivel un cofre; por
## ahora los cofres siempre están disponibles para probar la economía.

const PATH := "user://inventory.json"
const FRAG_COST := 10          # fragmentos para convertir en 1 pieza completa

## Cofres temporales. tier: 0 = piezas al azar, 1 = mitad premium, 2 = todo
## premium + figura garantizada. (premium = figuras/pasivas/estados/rarezas
## altas/estaminas altas/tipos de dado especiales)
const CHESTS := {
	"t5": {"name": "Cofre Común", "interval": 300, "pieces": 2, "tier": 0},
	"t10": {"name": "Cofre Épico", "interval": 600, "pieces": 3, "tier": 1},
	"t15": {"name": "Cofre Legendario", "interval": 900, "pieces": 4, "tier": 2},
}

var mode := "admin"
var pieces := {}       # key -> int (piezas completas)
var fragments := {}    # key -> int
var next_chest := {}   # chest_id -> unix ts en que estará listo
var _loaded := false
var _starter := false  # kit inicial ya entregado

# ---------------------------------------------------------------- modo
func is_admin() -> bool:
	_ensure_loaded()
	return mode == "admin"

func set_mode(m: String) -> void:
	_ensure_loaded()
	mode = "admin" if m == "admin" else "user"
	if mode == "user" and not _starter:
		_grant_starter()
	_save()

# ---------------------------------------------------------------- piezas
func owned(key: String) -> int:
	_ensure_loaded()
	return 999 if is_admin() else int(pieces.get(key, 0))

func has_piece(key: String) -> bool:
	return owned(key) > 0

func add_piece(key: String, n := 1) -> void:
	_ensure_loaded()
	pieces[key] = int(pieces.get(key, 0)) + n
	_save()

func frags(key: String) -> int:
	_ensure_loaded()
	return int(fragments.get(key, 0))

func add_frags(key: String, n: int) -> void:
	_ensure_loaded()
	fragments[key] = int(fragments.get(key, 0)) + n
	_save()

## 10 fragmentos -> 1 pieza completa.
func convert(key: String) -> bool:
	_ensure_loaded()
	if frags(key) < FRAG_COST:
		return false
	fragments[key] = frags(key) - FRAG_COST
	pieces[key] = int(pieces.get(key, 0)) + 1
	_save()
	return true

## ADMIN (prueba): regala n piezas completas de CADA pieza del catálogo.
func gift_all(n := 3) -> int:
	_ensure_loaded()
	var cat := catalog()
	for key in cat:
		pieces[key] = int(pieces.get(key, 0)) + n
	_save()
	return cat.size()

# ---------------------------------------------------------------- cajas
## Caja GRATIS: fragmentos aleatorios (3 piezas distintas, 2–4 frag c/u).
func open_free() -> Dictionary:
	_ensure_loaded()
	var cat := catalog()
	var got := {}
	for i in 3:
		var key: String = cat[randi() % cat.size()]
		var n := 2 + randi() % 3
		fragments[key] = int(fragments.get(key, 0)) + n
		got[key] = int(got.get(key, 0)) + n
	_save()
	return got

func chest_ready(id: String) -> bool:
	_ensure_loaded()
	return _now() >= int(next_chest.get(id, 0))

func chest_left(id: String) -> int:
	_ensure_loaded()
	return maxi(0, int(next_chest.get(id, 0)) - _now())

## Cofre temporal: si su timer terminó, da piezas COMPLETAS según su nivel y
## SU timer rearma desde cero (5/10/15 min por reloj real).
func open_chest(id: String) -> Array:
	_ensure_loaded()
	if not CHESTS.has(id) or not chest_ready(id):
		return []
	var c: Dictionary = CHESTS[id]
	var tier := int(c["tier"])
	var got: Array = []
	for i in int(c["pieces"]):
		# tier 0: cualquiera · tier 1: 50% premium · tier 2: todo premium
		var premium := tier == 2 or (tier == 1 and randi() % 2 == 0)
		got.append(_random_piece(premium))
	if tier == 2:
		got[0] = _random_from_prefix("model:")   # legendario: figura garantizada
	for key in got:
		pieces[key] = int(pieces.get(key, 0)) + 1
	next_chest[id] = _now() + int(c["interval"])
	_save()
	return got

func _random_piece(premium: bool) -> String:
	var pool := _premium_catalog() if premium else catalog()
	return pool[randi() % pool.size()]

func _random_from_prefix(prefix: String) -> String:
	var pool: Array = []
	for key in catalog():
		if String(key).begins_with(prefix):
			pool.append(key)
	return pool[randi() % pool.size()] if not pool.is_empty() else catalog()[0]

## Piezas "premium": figuras, pasivas, estados, rarezas altas, estamina 4+,
## y tipos de ataque especiales (todo menos lo básico).
func _premium_catalog() -> Array:
	var out: Array = []
	for key in catalog():
		var k := String(key)
		if k.begins_with("model:") or k.begins_with("passive:") or k.begins_with("fx:"):
			out.append(k)
		elif k in ["rarity:legend", "rarity:mythic", "stamina:4", "stamina:5", "stamina:6"]:
			out.append(k)
		elif k.begins_with("atype:") and not k.contains("Ruleta"):
			out.append(k)
	return out

func _now() -> int:
	return int(Time.get_unix_time_from_system())

# ---------------------------------------------------------------- catálogo
## Todas las piezas desbloqueables (key = "categoria:valor").
func catalog() -> Array:
	var out: Array = []
	for f in Roster.FIGURES:
		if not bool(f.get("custom", false)):
			out.append("model:" + String(f["id"]))
	for r in CharacterCreator.RARITIES:
		out.append("rarity:" + String(r))
	for t in CharacterCreator.TYPES:
		out.append("atype:" + String(t))
	for c in CharacterCreator.COL_IDS:
		out.append("color:" + String(c))
	var seen_fx := {}
	for o in CharacterCreator.FX_OPTS:
		var fx := String(o.get("fx", ""))
		if fx != "" and not seen_fx.has(fx):
			seen_fx[fx] = true
			out.append("fx:" + fx)
	for pid in Roster.PASSIVES.keys():
		if not (pid in CharacterCreator.HIDDEN_PASSIVES):
			out.append("passive:" + String(pid))
	for s in range(0, 7):
		out.append("stamina:%d" % s)
	return out

## Piezas que una figura NECESITA (para bloquear el guardado en modo usuario).
func required_pieces(fig: Dictionary) -> Array:
	var req := {}
	if String(fig.get("model_ref", "")) != "":
		req["model:" + String(fig["model_ref"])] = true
	if fig.has("rarity"):
		req["rarity:" + String(fig["rarity"])] = true
	req["atype:" + String(fig.get("type", "Ruleta"))] = true
	req["stamina:%d" % int(fig.get("stamina", 2))] = true
	for pid in fig.get("passives", []):
		req["passive:" + String(pid)] = true
	for seg in fig.get("attack", []):
		req["color:" + String(seg.get("col", "white"))] = true
		if String(seg.get("fx", "")) != "":
			req["fx:" + String(seg["fx"])] = true
	for st in fig.get("ranks", []):
		var eid := String(st.get("evolves_id", ""))
		# Solo exigir la figura destino si es INTEGRADA (las custom no salen en cajas).
		if eid != "" and _is_builtin(eid):
			req["model:" + eid] = true
	return req.keys()

func _is_builtin(id: String) -> bool:
	for f in Roster.FIGURES:
		if String(f.get("id", "")) == id:
			return not bool(f.get("custom", false))
	return false

## Piezas que FALTAN para esta figura ([] = puede crearla). Admin nunca bloquea.
func missing_pieces(fig: Dictionary) -> Array:
	_ensure_loaded()
	if is_admin():
		return []
	var out: Array = []
	for key in required_pieces(fig):
		if int(pieces.get(key, 0)) <= 0:
			out.append(key)
	return out

## Nombre legible de una pieza para la UI.
func piece_name(key: String) -> String:
	var p := key.split(":", true, 1)
	if p.size() < 2:
		return key
	match p[0]:
		"model":
			for f in Roster.FIGURES:
				if String(f.get("id", "")) == p[1]:
					return "Figura " + String(f.get("name", p[1]))
			return "Figura " + p[1]
		"rarity":
			var i := CharacterCreator.RARITIES.find(p[1])
			return "Rareza " + (String(CharacterCreator.RARITY_ES[i]) if i >= 0 else p[1])
		"atype":
			return "Tipo " + p[1]
		"color":
			var ci := CharacterCreator.COL_IDS.find(p[1])
			return "Ataque " + (String(CharacterCreator.COL_ES[ci]).split(" ")[0] if ci >= 0 else p[1])
		"fx":
			return "Estado " + p[1]
		"passive":
			return "Pasiva " + String(Roster.PASSIVES.get(p[1], {}).get("name", p[1]))
		"stamina":
			return "Estamina " + p[1]
	return key

# ---------------------------------------------------------------- kit inicial
## Lo mínimo para que el pool por defecto del Creador sea construible.
func _grant_starter() -> void:
	_starter = true
	for key in ["color:white", "color:blue", "color:red", "stamina:2",
			"atype:Ruleta", "model:ironclad_knight", "rarity:epic"]:
		pieces[key] = maxi(int(pieces.get(key, 0)), 1)

# ---------------------------------------------------------------- persistencia
func _ready() -> void:
	_ensure_loaded()

func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Dictionary:
		mode = String(data.get("mode", "admin"))
		pieces = data.get("pieces", {})
		fragments = data.get("fragments", {})
		next_chest = data.get("next_chest", {})
		_starter = bool(data.get("starter", false))

func _save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({
			"mode": mode, "pieces": pieces, "fragments": fragments,
			"next_chest": next_chest, "starter": _starter,
		}))
		f.close()
