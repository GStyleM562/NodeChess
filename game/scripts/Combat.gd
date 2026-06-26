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
## Hierarchy: Blue beats White/Purple/Gold; among those a cycle
## (White>Gold, Gold>Purple, Purple>White); same color compares power/stars;
## Red always loses.
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
	var beats := {"white": "gold", "gold": "purple", "purple": "white"}
	return 1 if beats[ca] == cb else -1

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
	if col == "red":
		return String(s.get("name", "Fallo"))
	if col == "blue":
		return String(s.get("name", "Bloqueo"))
	if col == "purple":
		var base := String(s.get("name", String(s.get("fx", "Especial"))))
		return base + " " + "★".repeat(int(s.get("stars", 1)))
	# white or gold: name + damage value
	var dmg := str(int(s.get("pow", 0)))
	if col == "gold":
		return String(s.get("name", "Oro")) + " " + dmg
	return String(s.get("name", "Daño")) + " " + dmg

static func color_of(s: Dictionary) -> Color:
	match String(s.get("col", "red")):
		"white": return Color(0.92, 0.94, 1.0)
		"gold": return Color(1.0, 0.82, 0.25)
		"purple": return Color(0.72, 0.45, 1.0)
		"blue": return Color(0.35, 0.6, 1.0)
		_: return Color(0.9, 0.3, 0.3)
