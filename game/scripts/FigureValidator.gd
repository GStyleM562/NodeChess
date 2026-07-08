extends RefCounted
class_name FigureValidator
## Validates a figure dict against the GDD Character Validator (Part 2A §32).
## Returns { state: "VALID"|"WARNING"|"INVALID", errors: [String], warnings: [String] }.
##   INVALID  → cannot be saved as-is (hard rule broken).
##   WARNING  → allowed (human designer may override), but flagged.
## Probabilities are stored as segment weights ("w"); for a Ruleta they must sum to
## 100 (the Creator enters them as percentages). Dice/Coin faces need not sum to 100.

const COLORS := ["white", "gold", "purple", "blue", "red"]
const MAX_PASSIVES := 3
const MAX_RESISTS := 2
const MAX_STAGES := 4          # base stage + up to 3 ranks
const TYPE_PREFIXES := ["Ruleta", "Dado", "Moneda", "Doble Moneda", "Suma"]

static func validate(fig: Dictionary) -> Dictionary:
	var errors: Array = []
	var warnings: Array = []

	# --- identity ---
	if String(fig.get("name", "")).strip_edges() == "":
		errors.append("Falta el nombre.")
	if String(fig.get("id", "")).strip_edges() == "":
		errors.append("Falta el id.")

	# --- stamina ---
	var stam := int(fig.get("stamina", 0))
	if stam < 0:
		errors.append("Estamina negativa (%d)." % stam)
	elif stam == 0:
		warnings.append("Estamina 0: la figura no podrá moverse.")
	elif stam > 5:
		warnings.append("Estamina %d supera el máximo recomendado (5)." % stam)

	# --- attack type ---
	var typ := String(fig.get("type", ""))
	if not _type_ok(typ):
		errors.append("Tipo de ataque inválido: '%s'." % typ)

	# --- passives ---
	var passives: Array = fig.get("passives", [])
	if passives.size() > MAX_PASSIVES:
		errors.append("Demasiadas pasivas (%d > %d)." % [passives.size(), MAX_PASSIVES])
	for pid in passives:
		if not Roster.PASSIVES.has(String(pid)):
			warnings.append("Pasiva desconocida: '%s'." % str(pid))

	# --- resistencias a estados (máx. 2) ---
	var resists: Array = fig.get("resists", [])
	if resists.size() > MAX_RESISTS:
		errors.append("Demasiadas resistencias (%d > %d)." % [resists.size(), MAX_RESISTS])

	# --- base attack pool ---
	_check_pool(fig.get("attack", []), typ, "Pool base", errors, warnings)

	# --- evolution stages ---
	var ranks: Array = fig.get("ranks", [])
	if 1 + ranks.size() > MAX_STAGES:
		errors.append("Demasiadas etapas de evolución (%d > %d)." % [1 + ranks.size(), MAX_STAGES])
	for i in ranks.size():
		var st: Dictionary = ranks[i]
		var sp: Array = st.get("passives", [])
		if sp.size() > MAX_PASSIVES:
			errors.append("Etapa %d: demasiadas pasivas (%d)." % [i + 2, sp.size()])
		_check_pool(st.get("attack", fig.get("attack", [])), String(st.get("type", typ)), "Etapa %d" % (i + 2), errors, warnings)

	_gdd_advisories(fig, stam, warnings)

	var state := "INVALID" if not errors.is_empty() else ("WARNING" if not warnings.is_empty() else "VALID")
	return {"state": state, "errors": errors, "warnings": warnings}

## Avisos de DISEÑO según el GDD (Parte 2). Nunca bloquean el guardado — el
## diseñador decide — pero marcan combinaciones fuera de la guía de balance.
static func _gdd_advisories(fig: Dictionary, stam: int, warnings: Array) -> void:
	var pool: Array = fig.get("attack", [])
	var max_pow := 0
	for seg in pool:
		max_pow = maxi(max_pow, int(seg.get("pow", 0)))
	var evolves := not (fig.get("ranks", []) as Array).is_empty()
	# Golpes enormes en la forma BASE: el GDD los reserva para evoluciones.
	if max_pow >= 110:
		warnings.append("Golpe base de %d es MUY alto — el GDD reserva daños así para formas evolucionadas%s." %
			[max_pow, "" if evolves else ", y este personaje ni siquiera evoluciona"])
	elif max_pow >= 90 and not evolves:
		warnings.append("Daño alto (%d) sin evolución — fuerte para CUALQUIER rareza (GDD: la rareza nunca da más poder)." % max_pow)
	# Pegada fuerte + mucha movilidad: la guía cobra la movilidad con menos daño.
	if max_pow >= 80 and stam >= 3:
		warnings.append("Ataque muy poderoso (%d) y estamina %d — combinación muy fuerte según el GDD (la movilidad alta debería costar pegada)." % [max_pow, stam])
	# Guía de estamina por clase (GDD Parte 2: Tank 1–2, Balanced 2, Agile 3–4).
	var guide := {"Tank": Vector2i(1, 2), "Balanced": Vector2i(2, 2), "Agile": Vector2i(3, 4)}
	var cls := String(fig.get("class", ""))
	if guide.has(cls):
		var g: Vector2i = guide[cls]
		if stam < g.x or stam > g.y:
			var rango := ("%d" % g.x) if g.x == g.y else ("%d–%d" % [g.x, g.y])
			warnings.append("Clase %s con estamina %d — la guía del GDD sugiere %s." % [cls, stam, rango])

static func _type_ok(typ: String) -> bool:
	for p in TYPE_PREFIXES:
		if typ.begins_with(p):
			return true
	return false

static func _check_pool(pool: Array, typ: String, label: String, errors: Array, warnings: Array) -> void:
	if pool.is_empty():
		errors.append("%s: el pool de ataque está vacío." % label)
		return
	var has_red := false
	var red_w := 0.0
	var total := 0.0
	for seg in pool:
		var col := String(seg.get("col", ""))
		if not col in COLORS:
			errors.append("%s: color inválido '%s'." % [label, col])
		if col == "red":
			has_red = true
			red_w += float(seg.get("w", 1.0))
		if col == "purple" and String(seg.get("fx", "")) == "" and not seg.has("disp"):
			warnings.append("%s: Púrpura sin efecto elegido — ganaría el duelo pero no aplicaría NADA." % label)
		if int(seg.get("pow", 0)) < 0:
			errors.append("%s: daño negativo." % label)
		if seg.has("stars"):
			var stars := int(seg["stars"])
			if stars < 1 or stars > 3:
				errors.append("%s: estrellas fuera de rango (★%d)." % [label, stars])
		var w := float(seg.get("w", 1.0))
		if w < 0.0:
			errors.append("%s: probabilidad/peso negativo." % label)
		total += w
	# Ruleta probabilities must sum to 100 (entered as percentages).
	if typ.begins_with("Ruleta") and absf(total - 100.0) > 0.5:
		errors.append("%s: las probabilidades suman %.0f%%, deben sumar 100%%." % [label, total])
	if not has_red:
		warnings.append("%s: sin segmento Rojo (Fallo) — el GDD lo recomienda." % label)
	elif typ.begins_with("Ruleta") and total > 0.0 and red_w / total < 0.1:
		warnings.append("%s: el Fallo es solo %.0f%% — el GDD recomienda un riesgo de fallo real (≥10%%)." % [label, 100.0 * red_w / total])
