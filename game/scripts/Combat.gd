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

## Human-readable label for a rolled segment (for the result UI).
static func label(s: Dictionary) -> String:
	match String(s.get("col", "red")):
		"white":
			return "White %d" % int(s.get("pow", 0))
		"gold":
			return "Gold %d" % int(s.get("pow", 0))
		"purple":
			return "Purple " + "★".repeat(int(s.get("stars", 1)))
		"blue":
			return "Blue"
		_:
			return "Miss"

static func color_of(s: Dictionary) -> Color:
	match String(s.get("col", "red")):
		"white": return Color(0.92, 0.94, 1.0)
		"gold": return Color(1.0, 0.82, 0.25)
		"purple": return Color(0.72, 0.45, 1.0)
		"blue": return Color(0.35, 0.6, 1.0)
		_: return Color(0.9, 0.3, 0.3)
