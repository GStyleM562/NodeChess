extends SceneTree
## FigureValidator audit (GDD §32).

const FV := preload("res://scripts/FigureValidator.gd")

func _wheel(segs: Array) -> Dictionary:
	return {"id": "v", "name": "V", "stamina": 3, "type": "Ruleta", "passives": [], "attack": segs}

func _initialize() -> void:
	var ok := true
	# VALID: sums to 100, has red, fine.
	ok = _state("valid wheel", _wheel([
		{"col": "white", "pow": 60, "w": 50}, {"col": "blue", "w": 30}, {"col": "red", "w": 20},
	]), "VALID") and ok
	# INVALID: sums to 90.
	ok = _state("wheel sums 90", _wheel([
		{"col": "white", "pow": 60, "w": 50}, {"col": "blue", "w": 20}, {"col": "red", "w": 20},
	]), "INVALID") and ok
	# INVALID: 4 passives.
	var f4 := _wheel([{"col": "red", "w": 100}])
	f4["passives"] = ["a", "b", "c", "d"]
	ok = _state("4 passives", f4, "INVALID") and ok
	# INVALID: stars 4.
	ok = _state("stars 4", _wheel([
		{"col": "purple", "stars": 4, "w": 60}, {"col": "red", "w": 40},
	]), "INVALID") and ok
	# INVALID: negative stamina.
	var fn := _wheel([{"col": "red", "w": 100}]); fn["stamina"] = -1
	ok = _state("neg stamina", fn, "INVALID") and ok
	# INVALID: 5 stages (4 ranks).
	var fs := _wheel([{"col": "red", "w": 100}])
	fs["ranks"] = [{"attack": [{"col": "red", "w": 100}]}, {"attack": [{"col": "red", "w": 100}]},
		{"attack": [{"col": "red", "w": 100}]}, {"attack": [{"col": "red", "w": 100}]}]
	ok = _state("5 stages", fs, "INVALID") and ok
	# INVALID: bad color.
	ok = _state("bad color", _wheel([{"col": "green", "w": 100}]), "INVALID") and ok
	# WARNING: no red.
	ok = _state("no red (warning)", _wheel([
		{"col": "white", "pow": 60, "w": 70}, {"col": "blue", "w": 30},
	]), "WARNING") and ok
	# VALID: dice (no 100% rule), 6 faces.
	ok = _state("dice 6 faces", {
		"id": "d", "name": "D", "stamina": 2, "type": "Dado (D6)", "passives": [],
		"attack": [{"col": "white", "pow": 40, "w": 1}, {"col": "white", "pow": 60, "w": 1},
			{"col": "blue", "w": 1}, {"col": "purple", "stars": 1, "w": 1},
			{"col": "gold", "pow": 30, "w": 1}, {"col": "red", "w": 1}],
	}, "VALID") and ok

	print("VALIDATOR_OK" if ok else "VALIDATOR_FAIL")
	quit()

func _state(label: String, fig: Dictionary, want: String) -> bool:
	var r := FV.validate(fig)
	var got := String(r["state"])
	var pass_: bool = got == want
	var detail := ""
	if not r["errors"].is_empty():
		detail = " err=" + str(r["errors"])
	print(("  %-22s got=%-8s want=%-8s %s%s") % [label, got, want, ("OK" if pass_ else "<<< FAIL"), detail])
	return pass_
