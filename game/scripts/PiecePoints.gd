extends RefCounted
class_name PiecePoints
## Puntos de Construcción (PC) — ver docs/Balance_PiecePoints.md.
## cost(fig)   = cuánto PODER gasta la figura (segmentos + estamina + tipo +
##               pasivas/resistencias construidas).
## budget(fig) = cuánto PODER permite (rareza + clase + modelo innato, ×1.30 si
##               es evolución).  cost ≤ budget  ⇒ la figura CABE (válida por PC).
## Todo son constantes SEMILLA calibradas contra las 8 figuras integradas
## (tools/calib_pp.gd las mide); se ajustan en parches de balance.

# --- PRESUPUESTOS (fuentes) ------------------------------------------------
const RARITY_BUDGET := {
	"common": 100, "rare": 135, "epic": 175, "legend": 220, "mythic": 280,
}
const CLASS_PC := {
	"Balanced": 20, "Specialist": 30, "Controller": 5,
	# las demás dan su valor en stats de combate (0 PC)
	"Agile": 0, "Tank": 0, "Striker": 0, "Debuffer": 0, "Buffer": 0,
}
const EVOLUTION_MULT := 1.30

# --- COSTOS (gasto) --------------------------------------------------------
const COLOR_VAL := {"white": 0.0, "gold": 5.0, "purple": 8.0, "blue": 22.0, "red": -6.0}
const POW_MULT := 0.35                    # daño → PC (blanco/oro): 60 → 21
const STARS_VAL := {1: 10.0, 2: 22.0, 3: 40.0}
const FX_SOFT := 8.0
const FX_HARD := 20.0                     # control duro
const FX_DISP := 12.0                     # desplazamiento
const HARD_FX := ["Miedo", "Paralizado", "Congelado", "Sueño"]
const PROB_DIV := 50.0                    # M(prob) = prob / 50
const STAMINA_COST := [0, 3, 8, 16, 28, 44, 64]
const TYPE_COST := {
	"Ruleta": 0, "Dado (D4)": 4, "Dado (D6)": 4, "Dado (D8)": 10,
	"Dado (D10)": 10, "Dado (D12)": 10, "Moneda": 6, "Doble Moneda": 12, "Suma 2d6": 15,
}
const RESIST_COST := 10.0
const PASSIVE_DEFAULT := 12.0
const PASSIVE_COST := {
	"bedrock": 8, "hold_the_line": 8, "hover": 8, "fast_recovery": 8,
	"counter_stone": 12, "bulwark": 12, "parkour": 12, "blink": 12,
	"hexstep": 12, "aerial": 12, "dive": 12, "lunge": 12, "venom_hex": 12,
	"kindling_resolve": 10, "warcry": 14, "goalkeeper": 14, "scavenger": 14,
	"arcane_pull": 15, "bloodthirst": 15,
	# auras / once-per-match fuertes (normalmente OCULTAS, no se construyen)
	"venom_aura": 22, "burning_aura": 22, "loaded_dice": 20, "phase": 22,
}

# ---------------------------------------------------------------- API
static func cost(fig: Dictionary) -> int:
	var c := 0.0
	c += _pool_cost(fig.get("attack", []))
	c += float(STAMINA_COST[clampi(int(fig.get("stamina", 2)), 0, 6)])
	c += float(TYPE_COST.get(String(fig.get("type", "Ruleta")), 0))
	# pasivas/resistencias CONSTRUIDAS (las ocultas del modelo no cuestan, salvo
	# al Especialista: NO hereda las pasivas ocultas, así que las paga si las pone).
	var innate: Dictionary = _innate(fig)
	var inherits_p: bool = String(fig.get("class", "")) != "Specialist"
	var innate_p: Array = innate.get("passives", [])
	for pid in fig.get("passives", []):
		if inherits_p and String(pid) in innate_p:
			continue                      # ya la trae el modelo → gratis
		c += float(PASSIVE_COST.get(String(pid), PASSIVE_DEFAULT))
	var innate_r: Array = innate.get("resists", [])
	for sid in fig.get("resists", []):
		if String(sid) in innate_r:
			continue
		c += RESIST_COST
	return int(round(maxf(0.0, c)))

static func _pool_cost(pool: Array) -> float:
	if pool.is_empty():
		return 0.0
	var total_w := 0.0
	for s in pool:
		total_w += float(s.get("w", 1.0))
	if total_w <= 0.0:
		total_w = float(pool.size())
	var sum := 0.0
	for s in pool:
		var col := String(s.get("col", "white"))
		var v := float(COLOR_VAL.get(col, 0.0))
		if (col == "white" or col == "gold") and s.has("pow"):
			v += float(s["pow"]) * POW_MULT
		elif col == "purple":
			v += float(STARS_VAL.get(clampi(int(s.get("stars", 1)), 1, 3), 10.0))
		# efecto: desplazamiento > control duro > estado leve
		if s.has("disp"):
			v += FX_DISP
		elif s.has("fx"):
			v += FX_HARD if String(s["fx"]) in HARD_FX else FX_SOFT
		var prob := 100.0 * float(s.get("w", 1.0)) / total_w
		sum += v * (prob / PROB_DIV)
	return sum

static func budget(fig: Dictionary) -> int:
	var b := float(RARITY_BUDGET.get(String(fig.get("rarity", "common")), 100))
	b += float(CLASS_PC.get(String(fig.get("class", "")), 0))
	b += float(_innate(fig).get("pc", 0))
	if bool(fig.get("is_evolution", false)):
		b *= EVOLUTION_MULT
	return int(round(b))

## ¿La figura CABE en su presupuesto? (regla dura del validador — F2)
static func fits(fig: Dictionary) -> bool:
	return cost(fig) <= budget(fig)

## Rasgos innatos del MODELO de la figura (§4). Hoy 0 hasta poblarlos (F4).
static func _innate(fig: Dictionary) -> Dictionary:
	var ref := String(fig.get("model_ref", fig.get("id", "")))
	for f in Roster.FIGURES:
		if String(f.get("id", "")) == ref:
			return f.get("innate", {})
	return {}

## Desglose legible para el medidor del Creador (ⓘ). -> Array[String]
static func breakdown(fig: Dictionary) -> Array:
	var lines: Array = []
	lines.append("Ataques: %d" % int(round(_pool_cost(fig.get("attack", [])))))
	lines.append("Estamina %d: %d" % [int(fig.get("stamina", 2)), STAMINA_COST[clampi(int(fig.get("stamina", 2)), 0, 6)]])
	var tv := int(TYPE_COST.get(String(fig.get("type", "Ruleta")), 0))
	if tv != 0:
		lines.append("Tipo %s: %d" % [String(fig.get("type", "Ruleta")), tv])
	var innate: Dictionary = _innate(fig)
	var inherits_p: bool = String(fig.get("class", "")) != "Specialist"
	var np: Array = innate.get("passives", [])
	var pc := 0
	for pid in fig.get("passives", []):
		if not (inherits_p and String(pid) in np):
			pc += int(PASSIVE_COST.get(String(pid), PASSIVE_DEFAULT))
	if pc > 0:
		lines.append("Pasivas: %d" % pc)
	var nr: Array = innate.get("resists", [])
	var rc := 0
	for sid in fig.get("resists", []):
		if String(sid) not in nr:
			rc += int(RESIST_COST)
	if rc > 0:
		lines.append("Resistencias: %d" % rc)
	return lines
