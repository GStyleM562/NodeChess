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

## TIPOS DE CAJA (2026-07-20). Un solo eje "tipo" + el eje "rareza" (tier) que ya
## existía: así NO hay decenas de cajas, pero puedes buscar lo que quieres. Cada
## tipo filtra el catálogo por sus prefijos de categoría (vacío = TODO = random).
## Mejor rareza → más piezas y más "premium", SIEMPRE dentro del tipo.
const BOX_TYPES := {
	"figures": {"name": "Caja de Figuras", "icon": "🧍", "col": [0.55, 0.28, 0.85],
		"prefixes": ["model:"]},
	"attack": {"name": "Caja de Ataques", "icon": "🎲", "col": [0.30, 0.62, 0.97],
		"prefixes": ["color:", "pow:", "stars:", "prob:", "atype:", "fx:"]},
	"passive": {"name": "Caja de Pasivas", "icon": "✨", "col": [0.93, 0.65, 0.05],
		"prefixes": ["passive:", "resist:"]},
	"random": {"name": "Caja Variada", "icon": "📦", "col": [0.13, 0.62, 0.36],
		"prefixes": []},   # vacío = cualquier pieza del catálogo
}

## Precio CANÓNICO de comprar+abrir una caja de un tipo (tier fijo). La UI solo
## lo muestra; el cobro lo decide aquí (anti-trampa). Variada barata en 🪙.
const BOX_PRICE := {
	"figures": {"cur": "gems", "price": 25, "tier": 1},
	"attack": {"cur": "gems", "price": 12, "tier": 1},
	"passive": {"cur": "gems", "price": 18, "tier": 1},
	"random": {"cur": "coins", "price": 200, "tier": 1},
}

## Compra ATÓMICA de una caja por tipo: valida fondos, cobra y la abre al momento.
## -> {"ok", "box": {pieces,gems,type}} · {"ok": false, "error"} si faltan fondos.
func buy_box(type_id: String) -> Dictionary:
	_ensure_loaded()
	if not BOX_PRICE.has(type_id):
		return {"ok": false, "error": "Caja desconocida."}
	var spec: Dictionary = BOX_PRICE[type_id]
	var price := int(spec["price"])
	var cur := String(spec["cur"])
	if cur == "gems":
		if gems < price:
			return {"ok": false, "error": "Te faltan 💎 (%d/%d)." % [gems, price]}
		gems -= price
	else:
		if coins < price:
			return {"ok": false, "error": "Te faltan 🪙 (%d/%d)." % [coins, price]}
		coins -= price
	var box := open_box(type_id, int(spec["tier"]))   # open_box guarda
	_log_tx({"k": "comprar_caja", "type": type_id, "price": price, "cur": cur})
	return {"ok": true, "box": box}

## Pool del catálogo filtrado por el TIPO de caja (prefijos vacíos = todo).
func box_pool(type_id: String) -> Array:
	var spec: Dictionary = BOX_TYPES.get(type_id, BOX_TYPES["random"])
	var pfx: Array = spec["prefixes"]
	if pfx.is_empty():
		return catalog()
	var out: Array = []
	for key in catalog():
		for p in pfx:
			if String(key).begins_with(String(p)):
				out.append(key)
				break
	return out if not out.is_empty() else catalog()

## ¿La pieza es "premium" (figura/pasiva/estado/rareza alta/estamina alta/dado
## especial/daño-estrella-prob altos)? Usado para sesgar las cajas de mejor rareza.
func _is_premium(key: String) -> bool:
	var k := String(key)
	if k.begins_with("model:") or k.begins_with("passive:") or k.begins_with("fx:"):
		return true
	if k in ["rarity:legend", "rarity:mythic", "stamina:4", "stamina:5", "stamina:6"]:
		return true
	if k.begins_with("atype:") and not k.contains("Ruleta"):
		return true
	if k.begins_with("pow:") and int(k.trim_prefix("pow:")) >= 65:
		return true
	if k.begins_with("stars:") and int(k.trim_prefix("stars:")) >= 2:
		return true
	if k.begins_with("prob:") and int(k.trim_prefix("prob:")) >= 45:
		return true
	return false

## Abre una caja de un TIPO y una RAREZA (tier 0/1/2): otorga piezas COMPLETAS
## del pool de ese tipo (más y mejores a más tier) + % de 💎. Núcleo reusable
## para cofres ganados, anuncios y la tienda de cajas.
## -> {"pieces": [...], "gems": N, "type": id}
func open_box(type_id: String, tier: int) -> Dictionary:
	_ensure_loaded()
	if not BOX_TYPES.has(type_id):
		type_id = "random"
	tier = clampi(tier, 0, 2)
	var pool := box_pool(type_id)
	var prem: Array = []
	for key in pool:
		if _is_premium(key):
			prem.append(key)
	if prem.is_empty():
		prem = pool
	var count: int = [2, 3, 4][tier]
	var got: Array = []
	for i in count:
		var use_prem := tier == 2 or (tier == 1 and randi() % 2 == 0)
		var src: Array = prem if use_prem else pool
		got.append(String(src[randi() % src.size()]))
	for key in got:
		pieces[key] = int(pieces.get(key, 0)) + 1
	var gem_kind: String = ["t5", "t10", "t15"][tier]
	var g := _roll_gems(gem_kind)
	gems += g
	_log_tx({"k": "abrir_caja", "type": type_id, "tier": tier, "piezas": got.duplicate(), "gems": g})
	_save()
	return {"pieces": got, "gems": g, "type": type_id}

var mode := "admin"
var pieces := {}       # key -> int (piezas completas)
var fragments := {}    # key -> int
var next_chest := {}   # chest_id -> unix ts en que estará listo
var xp := 0            # experiencia dentro del nivel actual
var level := 1         # nivel del jugador (sube jugando; da COFRES de nivel)
var level_chests := 0  # cofres de nivel pendientes de reclamar en el lobby
var wins := 0          # estadísticas de PERFIL (persisten)
var losses := 0
var streak := 0        # racha actual de victorias
var best_streak := 0   # mejor racha histórica
var coins := 0         # 🪙 monedas de juego (suben de nivel → compras en Tienda)
var gems := 0          # 💎 diamantes (cada 5 niveles + % en cofres)
var chest_inv: Array = []   # cofres GANADOS: [{tier, state, ready_at}] máx 4
var _loaded := false
var _starter := false  # kit inicial ya entregado

const XP_WIN := 60
const XP_LOSS := 25
const XP_ONLINE_BONUS := 15
const LEVEL_REWARD_PIECES := 2   # piezas completas al azar por cada nivel
const LEVEL_COINS := 100         # 🪙 por subir de nivel: nivel nuevo × 100
const GEM_LEVEL_EVERY := 5       # cada 5 niveles: 💎 = nivel × 2
const CHEST_SLOTS := 4           # ranuras de cofres ganados (estilo móvil)
# % de DIAMANTES al abrir cada caja: [probabilidad, mín, máx] — mejor cofre, más %.
const GEM_DROP := {
	"free": [0.05, 1, 1], "t5": [0.10, 1, 2], "t10": [0.20, 2, 4],
	"t15": [0.35, 4, 8], "level": [0.25, 2, 5],
}

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

## CRAFTEO: 10 fragmentos -> 1 pieza completa. ATÓMICO (descuenta y acredita en
## la misma operación) + validado (pieza del catálogo, fragmentos suficientes)
## + queda en el 🧾 log. -> {"ok", "error"?, "key", "name", "owned", "frags"}
func convert(key: String) -> Dictionary:
	_ensure_loaded()
	if not key in catalog():
		return {"ok": false, "error": "Esa pieza no existe en el catálogo."}
	if frags(key) < FRAG_COST:
		return {"ok": false, "error": "Te faltan fragmentos (%d/%d)." % [frags(key), FRAG_COST]}
	fragments[key] = frags(key) - FRAG_COST
	pieces[key] = int(pieces.get(key, 0)) + 1
	_log_tx({"k": "crafteo", "key": key, "frags": FRAG_COST})
	_save()
	return {"ok": true, "key": key, "name": piece_name(key),
		"owned": int(pieces[key]), "frags": frags(key)}

# ---------------------------------------------------------------- economía
## GASTA las piezas de una figura recién creada (modo usuario; admin no gasta).
## El bloqueo previo (missing_pieces) garantiza que todas existen.
func consume_for(fig: Dictionary) -> void:
	_ensure_loaded()
	if is_admin():
		return
	for key in required_pieces(fig):
		pieces[key] = maxi(0, int(pieces.get(key, 0)) - 1)
	_log_tx({"k": "crear_figura", "fig": String(fig.get("name", "?")),
		"piezas": required_pieces(fig).size()})
	_save()

## EDICIÓN: cobra solo las piezas NUEVAS y devuelve las que se retiraron
## (las piezas ya invertidas en la figura original no se cobran dos veces).
func adjust_for_edit(old_fig: Dictionary, new_fig: Dictionary) -> void:
	_ensure_loaded()
	if is_admin():
		return
	var before := {}
	for k in required_pieces(old_fig):
		before[k] = true
	var after := {}
	for k in required_pieces(new_fig):
		after[k] = true
	for k in after.keys():
		if not before.has(k):
			pieces[k] = maxi(0, int(pieces.get(k, 0)) - 1)
	for k in before.keys():
		if not after.has(k):
			pieces[k] = int(pieces.get(k, 0)) + 1
	_save()

## Como missing_pieces, pero al EDITAR las piezas de la figura original cuentan
## como propias (ya están invertidas ahí).
func missing_pieces_for(fig: Dictionary, old_fig: Dictionary) -> Array:
	_ensure_loaded()
	if is_admin():
		return []
	var invested := {}
	if not old_fig.is_empty():
		for k in required_pieces(old_fig):
			invested[k] = true
	var out: Array = []
	for key in required_pieces(fig):
		if invested.has(key):
			continue
		if int(pieces.get(key, 0)) <= 0:
			out.append(key)
	return out

# ---------------------------------------------------------------- experiencia
func xp_needed() -> int:
	return level * 100   # curva simple: 100, 200, 300…

## Bucle de niveles COMPARTIDO: aplica xp ganada, sube niveles y acredita las
## recompensas (🪙 nivel×100 por nivel · 💎 nivel×2 cada 5 · cofre de nivel).
func _apply_xp(gained: int) -> Dictionary:
	xp += gained
	var leveled := 0
	var coin_gain := 0
	var gem_gain := 0
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		leveled += 1
		coin_gain += level * LEVEL_COINS
		if level % GEM_LEVEL_EVERY == 0:
			gem_gain += level * 2
	level_chests += leveled
	coins += coin_gain
	gems += gem_gain
	if leveled > 0:
		_log_tx({"k": "nivel", "lvl": level, "coins": coin_gain, "gems": gem_gain})
	return {"leveled": leveled, "coins": coin_gain, "gems": gem_gain}

## XP directa (tutoriales/recompensas) SIN tocar estadísticas de partidas.
## -> {gained, leveled, level, coins, gems}
func grant_xp(gained: int, why := "recompensa") -> Dictionary:
	_ensure_loaded()
	var lv := _apply_xp(gained)
	_log_tx({"k": "xp", "why": why, "xp": gained})
	_save()
	return {"gained": gained, "leveled": int(lv["leveled"]), "level": level,
		"coins": int(lv["coins"]), "gems": int(lv["gems"])}

## XP al terminar una partida. Cada nivel otorga un COFRE DE NIVEL + 🪙 monedas
## (nivel nuevo × 100); cada 5 niveles cae un puñado de 💎 (nivel × 2). GANAR
## como USUARIO además otorga un cofre al inventario de cofres (descifrable).
## -> {gained, leveled, level, chests, coins, gems, chest}
func add_match_xp(won: bool, online: bool) -> Dictionary:
	_ensure_loaded()
	# estadísticas de PERFIL
	if won:
		wins += 1
		streak += 1
		best_streak = maxi(best_streak, streak)
	else:
		losses += 1
		streak = 0
	var gained := (XP_WIN if won else XP_LOSS) + (XP_ONLINE_BONUS if online else 0)
	var lv := _apply_xp(gained)
	var leveled := int(lv["leveled"])
	var coin_gain := int(lv["coins"])
	var gem_gain := int(lv["gems"])
	# COFRE GANADO por victoria (modo usuario, si hay ranura libre). Si las
	# ranuras están LLENAS se reporta para avisarle al jugador (cofre perdido).
	var chest_tier := ""
	var chest_full := false
	if won and mode == "user":
		chest_full = chest_inv.size() >= CHEST_SLOTS
		if not chest_full:
			chest_tier = grant_won_chest()
	_save()
	return {"gained": gained, "leveled": leveled, "level": level, "chests": leveled,
		"coins": coin_gain, "gems": gem_gain, "chest": chest_tier, "chest_full": chest_full}

## Cofre de NIVEL: 3 piezas (1 premium garantizada) + % de 💎. Consume un cofre
## pendiente. -> {"pieces": [...], "gems": N} (vacío si no hay cofres).
func open_level_chest() -> Dictionary:
	_ensure_loaded()
	if level_chests <= 0:
		return {}
	level_chests -= 1
	var got: Array = [_random_piece(true), _random_piece(false), _random_piece(false)]
	for key in got:
		pieces[key] = int(pieces.get(key, 0)) + 1
	var g := _roll_gems("level")
	gems += g
	_log_tx({"k": "abrir_cofre", "tier": "nivel", "piezas": got.duplicate(), "gems": g})
	_save()
	return {"pieces": got, "gems": g}

# ------------------------------------------------------- cofres GANADOS 📦
## Cofre ganado al VENCER (modo usuario): entra al inventario de cofres cerrado.
## Peor→mejor: 60% común · 30% épico · 10% legendario. "" si no hay ranura.
## `box_type` fija el tipo (figures/attack/passive/random); "" = tipo al azar
## (ponderado hacia "random"). Peor→mejor tier: 60% común · 30% épico · 10% leg.
func grant_won_chest(box_type := "") -> String:
	_ensure_loaded()
	if chest_inv.size() >= CHEST_SLOTS:
		return ""
	var r := randf()
	var tier := "t5" if r < 0.6 else ("t10" if r < 0.9 else "t15")
	var typ := box_type
	if typ == "" or not BOX_TYPES.has(typ):
		# al azar, con sesgo a "Variada"; a veces una caja específica (sorpresa)
		var tr := randf()
		typ = "random" if tr < 0.55 else ["figures", "attack", "passive"][randi() % 3]
	chest_inv.append({"tier": tier, "type": typ, "state": "locked", "ready_at": 0})
	_log_tx({"k": "cofre_ganado", "tier": tier, "type": typ})
	_save()
	return tier

## Estado calculado de un cofre ganado: "locked" | "unlocking" | "ready".
func chest_info(i: int) -> Dictionary:
	_ensure_loaded()
	if i < 0 or i >= chest_inv.size():
		return {}
	var c: Dictionary = chest_inv[i]
	var state := String(c.get("state", "locked"))
	if state == "unlocking" and _now() >= int(c.get("ready_at", 0)):
		state = "ready"
	return {"tier": String(c["tier"]), "state": state,
		"type": String(c.get("type", "random")),   # cofres viejos = Variada
		"left": maxi(0, int(c.get("ready_at", 0)) - _now()),
		"secs": int((CHESTS[String(c["tier"])] as Dictionary)["interval"])}

## "DESCIFRAR": arranca el progreso de apertura del cofre QUE TÚ ELIJAS
## (sin orden forzado ni límite: puedes descifrar varios a la vez).
func start_unlock(i: int) -> bool:
	_ensure_loaded()
	if i < 0 or i >= chest_inv.size():
		return false
	var c: Dictionary = chest_inv[i]
	if String(c.get("state", "locked")) != "locked":
		return false
	c["state"] = "unlocking"
	c["ready_at"] = _now() + int((CHESTS[String(c["tier"])] as Dictionary)["interval"])
	_log_tx({"k": "descifrar", "tier": String(c["tier"])})
	_save()
	return true

func any_unlocking() -> bool:
	_ensure_loaded()
	for i in chest_inv.size():
		if String(chest_info(i).get("state", "")) == "unlocking":
			return true
	return false

## Abre un cofre ganado YA descifrado: piezas por su nivel + % de 💎.
## -> {"pieces": [...], "gems": N} (vacío si aún no está listo).
func open_won_chest(i: int) -> Dictionary:
	_ensure_loaded()
	var info := chest_info(i)
	if info.is_empty() or String(info["state"]) != "ready":
		return {}
	var tier_id := String(info["tier"])
	var tier := int((CHESTS[tier_id] as Dictionary)["tier"])
	var type_id := String(info.get("type", "random"))
	# el TIPO decide de qué pool salen las piezas (open_box); el legendario random
	# garantiza además una figura. Las cajas de figuras ya son todas figuras.
	var res := open_box(type_id, tier)
	if tier == 2 and type_id == "random":
		var extra := _random_from_prefix("model:")
		pieces[extra] = int(pieces.get(extra, 0)) + 1
		(res["pieces"] as Array).append(extra)
	chest_inv.remove_at(i)
	_save()
	return res

## Tirada de DIAMANTES al abrir una caja (más % y cantidad en cofres mejores).
func _roll_gems(kind: String) -> int:
	var d: Array = GEM_DROP.get(kind, [0.0, 0, 0])
	if randf() >= float(d[0]):
		return 0
	return int(d[1]) + randi() % maxi(1, int(d[2]) - int(d[1]) + 1)

# ------------------------------------------------------- tienda 🛍
## RAREZA canónica de una pieza (única fuente de verdad para precios/UI).
func piece_rarity(key: String) -> String:
	var k := String(key)
	if k.begins_with("model:"):
		var id := k.trim_prefix("model:")
		for f in Roster.FIGURES:
			if String(f.get("id", "")) == id:
				return String(f.get("rarity", FigureCard.RARITY.get(id, "common")))
		return String(FigureCard.RARITY.get(id, "common"))
	if k.begins_with("color:"):
		var c := k.trim_prefix("color:")
		return "epic" if c == "gold" else ("rare" if (c == "blue" or c == "purple") else "common")
	if k.begins_with("fx:"):
		return "epic" if k.trim_prefix("fx:") in ["Miedo", "Paralizado", "Congelado", "Sueño"] else "rare"
	if k.begins_with("passive:"):
		return "epic"
	if k.begins_with("atype:"):
		var t := k.trim_prefix("atype:")
		if t.contains("D8") or t.contains("D10") or t.contains("D12") or t.contains("Doble"):
			return "epic"
		if t.contains("D4") or t.contains("D6"):
			return "rare"
		if t.contains("2d6"):
			return "legend"
		return "common"
	if k.begins_with("stamina:"):
		var n := int(k.trim_prefix("stamina:"))
		return "legend" if n >= 5 else ("epic" if n == 4 else ("rare" if n == 3 else "common"))
	if k.begins_with("resist:"):
		return "rare"
	if k.begins_with("rarity:"):
		return k.trim_prefix("rarity:")
	if k.begins_with("pow:"):
		var d := int(k.trim_prefix("pow:"))
		return "legend" if d >= 90 else ("epic" if d >= 65 else ("rare" if d >= 35 else "common"))
	if k.begins_with("stars:"):
		var s := int(k.trim_prefix("stars:"))
		return "legend" if s >= 3 else ("epic" if s == 2 else "rare")
	if k.begins_with("prob:"):
		var w := int(k.trim_prefix("prob:"))
		return "legend" if w >= 65 else ("epic" if w >= 45 else ("rare" if w >= 25 else "common"))
	if k.begins_with("class:"):
		return "common" if k.trim_prefix("class:") == "Balanced" else "rare"
	return "common"

const PRICE_BY_RARITY := {
	"common": {"price": 200, "currency": "coins"},
	"rare": {"price": 500, "currency": "coins"},
	"epic": {"price": 30, "currency": "gems"},
	"legend": {"price": 80, "currency": "gems"},
	"mythic": {"price": 150, "currency": "gems"},
}

## Precio CANÓNICO de una pieza. La UI solo lo MUESTRA — jamás lo decide
## (anti-trampa: un cliente alterado no puede comprar a otro precio).
## -> {"price": int, "currency": "coins"/"gems"} · {} si la pieza no existe.
func price_of(key: String) -> Dictionary:
	_ensure_loaded()
	if not key in catalog():
		return {}
	return (PRICE_BY_RARITY.get(piece_rarity(key), PRICE_BY_RARITY["common"]) as Dictionary).duplicate()

## Compra REAL y ATÓMICA con recibo. Valida que la pieza EXISTA en el catálogo
## y calcula el precio internamente. La pieza se acredita en la misma operación
## que el cobro (o todo o nada) y queda en el 🧾 log de movimientos.
## -> {"ok", "error"?, "key", "name", "price", "currency", "coins", "gems", "owned"}
func buy(key: String) -> Dictionary:
	_ensure_loaded()
	var p := price_of(key)
	if p.is_empty():
		return {"ok": false, "error": "Esa pieza no existe en el catálogo."}
	var price := int(p["price"])
	var cur := String(p["currency"])
	if cur == "gems":
		if gems < price:
			return {"ok": false, "error": "Te faltan 💎 diamantes (%d/%d)." % [gems, price]}
		gems -= price
	else:
		if coins < price:
			return {"ok": false, "error": "Te faltan 🪙 monedas (%d/%d)." % [coins, price]}
		coins -= price
	pieces[key] = int(pieces.get(key, 0)) + 1
	_log_tx({"k": "compra", "key": key, "price": price, "cur": cur})
	_save()
	return {"ok": true, "key": key, "name": piece_name(key), "price": price,
		"currency": cur, "coins": coins, "gems": gems, "owned": int(pieces[key])}

## ADMIN: añade/quita fondos a la cuenta (clavado en ≥ 0).
## KIT del TUTORIAL de creación: piezas para construir UNA figura básica. Se
## re-entrega cada vez que se juega el tutorial (sube cada pieza a >= 1, sin
## acumular), así SIEMPRE puedes construir lo que enseña sin importar tu saldo —
## siempre es un personaje de nivel bajo, no rompe la economía.
const TUTORIAL_KIT := [
	"model:ironclad_knight", "rarity:common", "class:Balanced", "atype:Ruleta",
	"stamina:2", "color:white", "color:red",
	"pow:40", "pow:60", "prob:50", "prob:30", "prob:20",
]

func grant_tutorial_kit() -> void:
	_ensure_loaded()
	for key in TUTORIAL_KIT:
		if int(pieces.get(key, 0)) < 1:
			pieces[key] = 1
	_log_tx({"k": "kit_tutorial", "piezas": TUTORIAL_KIT.size()})
	_save()

func adjust_funds(d_coins: int, d_gems: int) -> void:
	_ensure_loaded()
	coins = maxi(0, coins + d_coins)
	gems = maxi(0, gems + d_gems)
	_log_tx({"k": "fondos_admin", "coins": d_coins, "gems": d_gems})
	_save()

# ------------------------------------------------------- 📺 anuncios (usos/día)
## Ver un anuncio da un recurso, con TOPE diario que se reinicia cada día real.
## Sin SDK de anuncios: el "ver anuncio" lo simula la UI (espera breve). 3 tipos.
const AD_TYPES := {
	"coins": {"name": "Monedas gratis", "icon": "🪙", "daily": 5, "amount": 250},
	"gems": {"name": "Diamantes gratis", "icon": "💎", "daily": 3, "amount": 8},
	"box": {"name": "Caja sorpresa", "icon": "📦", "daily": 2},   # abre una Variada al momento
}
var ads := {"day": "", "used": {}}   # used: kind -> veces hoy

func _ad_today() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]

func _ad_roll_day() -> void:
	if String(ads.get("day", "")) != _ad_today():
		ads = {"day": _ad_today(), "used": {}}

## Usos que quedan HOY de un tipo de anuncio.
func ad_left(kind: String) -> int:
	_ensure_loaded()
	_ad_roll_day()
	if not AD_TYPES.has(kind):
		return 0
	var used := int((ads["used"] as Dictionary).get(kind, 0))
	return maxi(0, int((AD_TYPES[kind] as Dictionary)["daily"]) - used)

## Reclama la recompensa de un anuncio (la UI ya "reprodujo" el anuncio).
## -> {"ok", "kind", "coins"?, "gems"?, "box"?} · {"ok": false} si no quedan usos.
func watch_ad(kind: String) -> Dictionary:
	_ensure_loaded()
	_ad_roll_day()
	if ad_left(kind) <= 0:
		return {"ok": false}
	(ads["used"] as Dictionary)[kind] = int((ads["used"] as Dictionary).get(kind, 0)) + 1
	var out := {"ok": true, "kind": kind}
	match kind:
		"coins":
			var c: int = int((AD_TYPES["coins"] as Dictionary)["amount"])
			coins += c
			out["coins"] = c
		"gems":
			var g: int = int((AD_TYPES["gems"] as Dictionary)["amount"])
			gems += g
			out["gems"] = g
		"box":
			var tier := 0 if randf() < 0.75 else 1   # casi siempre común, a veces épica
			var r := open_box("random", tier)   # open_box ya hace _save
			out["box"] = r
			_log_tx({"k": "anuncio", "kind": kind})
			return out
	_log_tx({"k": "anuncio", "kind": kind})
	_save()
	return out

# ------------------------------------------------------- 🧾 log de movimientos
## Recibo persistente de CADA transacción de consumibles (compras, crafteos,
## cofres, recompensas). Evidencia para Soporte: qué se gastó y qué se entregó.
const TX_MAX := 50
var tx_log: Array = []

func _log_tx(entry: Dictionary) -> void:
	entry["t"] = _now()
	tx_log.append(entry)
	if tx_log.size() > TX_MAX:
		tx_log = tx_log.slice(tx_log.size() - TX_MAX)

## BORRA piezas y fragmentos — SOLO eso (los personajes creados, XP, nivel,
## cofres y estadísticas se conservan). Estado de cuenta nueva: en modo usuario
## el kit inicial se vuelve a entregar para que siempre puedas jugar.
func wipe_pieces() -> void:
	_ensure_loaded()
	pieces = {}
	fragments = {}
	_starter = false
	if mode == "user":
		_grant_starter()
	_log_tx({"k": "borrar_inventario"})
	_save()

## ADMIN (prueba): regala n piezas completas de CADA pieza del catálogo.
func gift_all(n := 3) -> int:
	_ensure_loaded()
	var cat := catalog()
	for key in cat:
		pieces[key] = int(pieces.get(key, 0)) + n
	_save()
	return cat.size()

# ---------------------------------------------------------------- cajas
## Caja GRATIS: fragmentos aleatorios (3 piezas distintas, 2–4 frag c/u) + % 💎.
## -> {"frags": {key: n}, "gems": N}
func open_free() -> Dictionary:
	_ensure_loaded()
	var cat := catalog()
	var got := {}
	for i in 3:
		var key: String = cat[randi() % cat.size()]
		var n := 2 + randi() % 3
		fragments[key] = int(fragments.get(key, 0)) + n
		got[key] = int(got.get(key, 0)) + n
	var g := _roll_gems("free")
	gems += g
	_log_tx({"k": "caja_gratis", "gems": g})
	_save()
	return {"frags": got, "gems": g}

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
	var seen_r := {}
	for label in GameState.FX_STATUS.keys():
		var sid := String(GameState.FX_STATUS[label])
		if not seen_r.has(sid):
			seen_r[sid] = true
			out.append("resist:" + sid)
	# DAÑOS de 5 en 5 (solo los consumen ataques Blanco/Oro)
	for d in range(5, 105, 5):
		out.append("pow:%d" % d)
	# ESTRELLAS 1–3 (solo las consumen ataques Púrpura)
	for st in range(1, 4):
		out.append("stars:%d" % st)
	# PROBABILIDADES de 5 en 5 hasta 70% (cada segmento consume la suya)
	for w in range(5, 75, 5):
		out.append("prob:%d" % w)
	# CLASES (de momento sin pasivas ocultas; ya inventariadas para el futuro)
	for c in CharacterCreator.CLASSES:
		out.append("class:" + String(c))
	return out

## Piezas que una figura NECESITA (para bloquear el guardado en modo usuario).
## REGLAS DE CONSUMO POR COLOR (GDD "construye tus piezas"):
##  · DAÑO (pow:N): solo lo consumen Blanco y Oro — Púrpura/Azul/Rojo van sin daño.
##  · ESTRELLAS (stars:N): solo las consume Púrpura — el resto va con 0 estrellas.
##  · PROBABILIDAD (prob:N): la consume TODO segmento (su % de la ruleta),
##    solo en pasos de 5 dentro de 5–70 (los pesos legados tipo w=1 no cobran).
func required_pieces(fig: Dictionary) -> Array:
	var req := {}
	if String(fig.get("model_ref", "")) != "":
		req["model:" + String(fig["model_ref"])] = true
	if fig.has("rarity"):
		req["rarity:" + String(fig["rarity"])] = true
	if fig.has("class"):
		req["class:" + String(fig["class"])] = true
	req["atype:" + String(fig.get("type", "Ruleta"))] = true
	req["stamina:%d" % int(fig.get("stamina", 2))] = true
	for pid in fig.get("passives", []):
		req["passive:" + String(pid)] = true
	for sid in fig.get("resists", []):
		req["resist:" + String(sid)] = true
	for seg in fig.get("attack", []):
		var col := String(seg.get("col", "white"))
		req["color:" + col] = true
		if String(seg.get("fx", "")) != "":
			req["fx:" + String(seg["fx"])] = true
		# DAÑO: solo Blanco/Oro (y solo valores del catálogo: múltiplos de 5, 5–100)
		if col in ["white", "gold"]:
			var pw := int(seg.get("pow", 0))
			if pw >= 5 and pw <= 100 and pw % 5 == 0:
				req["pow:%d" % pw] = true
		# ESTRELLAS: solo Púrpura (1–3)
		if col == "purple":
			req["stars:%d" % clampi(int(seg.get("stars", 1)), 1, 3)] = true
		# PROBABILIDAD: todo segmento con peso del catálogo (5–70, paso 5)
		var w := int(seg.get("w", 0))
		if w >= 5 and w <= 70 and w % 5 == 0:
			req["prob:%d" % w] = true
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

## Icono del TIPO de pieza (recibos, listas, cofres).
func piece_icon(key: String) -> String:
	var k := String(key)
	if k.begins_with("model:"):
		return "🧍"
	if k.begins_with("rarity:"):
		return "⭐"
	if k.begins_with("atype:"):
		return "🎲"
	if k.begins_with("color:"):
		return "🎯"
	if k.begins_with("fx:"):
		return "🌀"
	if k.begins_with("passive:"):
		return "✨"
	if k.begins_with("resist:"):
		return "🛡"
	if k.begins_with("pow:"):
		return "💥"
	if k.begins_with("stars:"):
		return "✴"
	if k.begins_with("prob:"):
		return "📊"
	if k.begins_with("class:"):
		return "🎖"
	return "👟"   # stamina

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
		"resist":
			for label in GameState.FX_STATUS.keys():
				if String(GameState.FX_STATUS[label]) == p[1]:
					return "Resistencia " + String(label)
			return "Resistencia " + p[1]
		"pow":
			return "Daño " + p[1]
		"stars":
			return "★" + p[1] + (" Estrella" if p[1] == "1" else " Estrellas")
		"prob":
			return "Probabilidad " + p[1] + "%"
		"class":
			return "Clase " + p[1]
	return key

# ---------------------------------------------------------------- kit inicial
## Lo mínimo para que el pool por defecto del Creador sea construible
## (Golpe blanco 60 al 50% + Guardia azul 30% + Fallo 20%, clase Balanced).
func _grant_starter() -> void:
	_starter = true
	for key in ["color:white", "color:blue", "color:red", "stamina:2",
			"atype:Ruleta", "model:ironclad_knight", "rarity:epic",
			"class:Balanced", "pow:60", "prob:50", "prob:30", "prob:20"]:
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
		xp = int(data.get("xp", 0))
		level = maxi(1, int(data.get("level", 1)))
		level_chests = int(data.get("lvl_chests", 0))
		wins = int(data.get("wins", 0))
		losses = int(data.get("losses", 0))
		streak = int(data.get("streak", 0))
		best_streak = int(data.get("best_streak", 0))
		coins = int(data.get("coins", 0))
		gems = int(data.get("gems", 0))
		chest_inv = data.get("chest_inv", [])
		tx_log = data.get("tx", [])
		_starter = bool(data.get("starter", false))
		ads = data.get("ads", {"day": "", "used": {}})

func _save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({
			"mode": mode, "pieces": pieces, "fragments": fragments,
			"next_chest": next_chest, "xp": xp, "level": level,
			"lvl_chests": level_chests, "starter": _starter,
			"wins": wins, "losses": losses, "streak": streak, "best_streak": best_streak,
			"coins": coins, "gems": gems, "chest_inv": chest_inv, "tx": tx_log,
			"ads": ads,
		}))
		f.close()
