extends RefCounted
class_name Combat
## Pure combat logic (no nodes). An "attack pool" is a list of weighted segments;
## every attack type (wheel/dice/coin) is represented as weighted segments so the
## UI can always show one spinning wheel. Each segment:
##   { "col": "white"|"purple"|"gold"|"blue"|"red", "pow": int, "stars": int, "w": float }

## Pick one segment from a pool (weighted random).
static func roll(pool: Array) -> Dictionary:
	var total := 0.0
	for s in pool:
		total += float(s.get("w", 1.0))
	var pick := randf() * total
	for s in pool:
		pick -= float(s.get("w", 1.0))
		if pick <= 0.0:
			return s
	return pool[pool.size() - 1]

## Compare two rolled segments. Returns 1 if A wins, -1 if B wins, 0 tie.
## Hierarchy (GDD Parte 1): Blue beats White/Purple/Gold; Gold beats Purple;
## Purple beats White; **White vs Gold is decided BY DAMAGE** (both are damage
## colours — the bigger `pow` wins, equal = tie). Same colour compares
## power/stars; Red always loses.
static func resolve(a: Dictionary, b: Dictionary) -> int:
	var ca := String(a.get("col", "red"))
	var cb := String(b.get("col", "red"))
	if ca == "red" and cb == "red":
		return 0
	if ca == "red":
		return -1
	if cb == "red":
		return 1
	if ca == "blue" and cb == "blue":
		return 0
	if ca == "blue":
		return 1
	if cb == "blue":
		return -1
	if ca == cb:
		if ca == "purple":
			return signi(int(a.get("stars", 0)) - int(b.get("stars", 0)))
		return signi(int(a.get("pow", 0)) - int(b.get("pow", 0)))
	# GDD: "White beats Gold (by damage)" — NOT automatically. Both are damage
	# colours, so the bigger hit lands first; equal damage = tie.
	if (ca == "white" and cb == "gold") or (ca == "gold" and cb == "white"):
		return signi(int(a.get("pow", 0)) - int(b.get("pow", 0)))
	var beats := {"gold": "purple", "purple": "white"}
	return 1 if beats.get(ca, "") == cb else -1

## Full combat outcome: who wins AND whether it is a KO.
## Winning with White/Gold (damage) -> KO. Winning with Purple -> applies its
## effect/status, NOT a KO (unless the segment's effect is itself a KO). Winning
## with Blue -> defensive block, NOT a KO. Ties -> nothing.
## Returns { result: 1/-1/0, ko: bool, win_col: String, effect: String }.
static func outcome(a: Dictionary, b: Dictionary) -> Dictionary:
	var r := resolve(a, b)
	var out := {"result": r, "ko": false, "win_col": "", "effect": "", "win_seg": {}}
	if r == 0:
		return out
	var w: Dictionary = a if r > 0 else b
	var wc := String(w.get("col", ""))
	out["win_col"] = wc
	out["win_seg"] = w
	if wc == "white" or wc == "gold":
		out["ko"] = bool(w.get("ko", true))   # damage kills (unless overridden)
		out["effect"] = "KO"
	elif wc == "purple":
		out["ko"] = bool(w.get("ko", false))  # purple applies a status, not a KO
		out["effect"] = String(w.get("fx", "Estado"))
	elif wc == "blue":
		out["ko"] = false
		out["effect"] = "Bloqueo"
	return out

## Display name of the attack shown on coins / dice / reels. Each segment carries
## a fictional "name" (e.g. "Fear Gas"). Display rules by colour:
##   White / Gold (damage)  -> NAME + damage number   ("Boulder Fist 80")
##   Purple (status)        -> NAME + ★ rating         ("Fear Gas ★★")
##   Blue (block)           -> NAME only               ("Shield Wall")
##   Red (miss)             -> "Fallo"
## The colour (hierarchy) is conveyed by the cell/coin colour, not the text.
static func label(s: Dictionary) -> String:
	var col := String(s.get("col", "red"))
	var sym := symbol_of(s)   # modo daltónico: símbolo del color al frente
	if col == "red":
		return sym + String(s.get("name", "Fallo"))
	if col == "blue":
		return sym + String(s.get("name", "Bloqueo"))
	if col == "purple":
		var base := String(s.get("name", String(s.get("fx", "Especial"))))
		return sym + base + " " + "★".repeat(int(s.get("stars", 1)))
	# white or gold: name + damage value
	var dmg := str(int(s.get("pow", 0)))
	if col == "gold":
		return sym + String(s.get("name", "Oro")) + " " + dmg
	return sym + String(s.get("name", "Daño")) + " " + dmg

## Human reason WHY this resolved the way it did (for combat transparency).
## Damage/★ only decide SAME colour; otherwise the colour hierarchy decides.
static func win_reason(a: Dictionary, b: Dictionary) -> String:
	var r := resolve(a, b)
	var ca := String(a.get("col", ""))
	var cb := String(b.get("col", ""))
	var dmg_duel := (ca == "white" and cb == "gold") or (ca == "gold" and cb == "white")
	if r == 0:
		if ca == "blue" and cb == "blue":
			return "ambos bloquean"
		if ca == "red" and cb == "red":
			return "ambos fallan"
		if dmg_duel or ca == cb:
			return "mismo daño — empate" if ca != "purple" else "mismas ★ — empate"
		return "empate"
	var win: Dictionary = a if r > 0 else b
	var lose: Dictionary = b if r > 0 else a
	var wc := String(win.get("col", ""))
	var lc := String(lose.get("col", ""))
	if lc == "red":
		return "el rival falló"
	if wc == "blue":
		return "Azul bloquea todo"
	if wc == lc or dmg_duel:
		return "más ★" if wc == "purple" else "más daño"
	return _cname(wc) + " vence a " + _cname(lc)

static func _cname(c: String) -> String:
	match c:
		"white": return "Blanco"
		"gold": return "Oro"
		"purple": return "Púrpura"
		"blue": return "Azul"
		_: return "Rojo"

## Modo daltónico (Settings): paleta Okabe-Ito de alto contraste + símbolo por
## color en las etiquetas, para que el tipo de segmento nunca dependa del tono.
static func _colorblind() -> bool:
	var ml := Engine.get_main_loop()
	if ml is SceneTree:
		var s := (ml as SceneTree).root.get_node_or_null("Settings")
		if s != null:
			return bool(s.get("colorblind"))
	return false

const COL_SYMBOL := {"white": "■", "gold": "◆", "purple": "✦", "blue": "⬟", "red": "✖"}

static func symbol_of(s: Dictionary) -> String:
	if not _colorblind():
		return ""
	return String(COL_SYMBOL.get(String(s.get("col", "red")), "")) + " "

static func color_of(s: Dictionary) -> Color:
	if _colorblind():
		match String(s.get("col", "red")):
			"white": return Color(1.0, 1.0, 1.0)
			"gold": return Color(0.94, 0.89, 0.26)     # amarillo Okabe-Ito
			"purple": return Color(0.8, 0.47, 0.65)    # rosa
			"blue": return Color(0.34, 0.71, 0.91)     # celeste
			_: return Color(0.25, 0.25, 0.28)          # fallo = casi negro
	match String(s.get("col", "red")):
		"white": return Color(0.92, 0.94, 1.0)
		"gold": return Color(1.0, 0.82, 0.25)
		"purple": return Color(0.72, 0.45, 1.0)
		"blue": return Color(0.35, 0.6, 1.0)
		_: return Color(0.9, 0.3, 0.3)
