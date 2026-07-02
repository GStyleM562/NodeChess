extends SceneTree
## Share/backup codes for custom figures: export -> decode/import roundtrip,
## damaged codes rejected, full-backup pack, built-in id never shadowed.

func _initialize() -> void:
	var ok := true
	var id := "test_code_fig"
	CustomFigures.remove(id)   # clean slate

	var fig := CharacterCreator.make_figure({
		"name": "Test Code Fig", "desc": "prueba", "class": "Striker", "rarity": "epic",
		"stamina": 3, "type": "Ruleta", "passives": ["counter_stance"],
		"model_ref": "ironclad_knight", "evolve": true,
		"pool": [
			{"col": "white", "name": "Tajo", "pow": 60, "w": 50},
			{"col": "blue", "name": "Guardia", "w": 30},
			{"col": "red", "w": 20},
		],
	})
	fig["id"] = id

	# --- export: prefixed, one line, no spaces ---
	var code := CustomFigures.export_code(fig)
	ok = _expect("code has prefix", code.begins_with("NCFIG1."), true) and ok
	ok = _expect("code is one clean token", code.contains(" ") or code.contains("\n"), false) and ok

	# --- decode (pure): same content after roundtrip ---
	var d := CustomFigures.decode_code(code)
	ok = _expect("decode ok", bool(d["ok"]), true) and ok
	var back: Dictionary = d["figs"][0]
	ok = _expect("name survives", String(back.get("name", "")), "Test Code Fig") and ok
	ok = _expect("attack pool survives", (back.get("attack", []) as Array).size(), 3) and ok
	ok = _expect("passives survive", (back.get("passives", []) as Array), ["counter_stance"]) and ok
	ok = _expect("ranks survive", (back.get("ranks", []) as Array).size(), 1) and ok
	ok = _expect("runtime keys stripped", back.has("custom") or back.has("placeholder"), false) and ok

	# --- decode tolerates whitespace injected by chat apps ---
	var messy := code.substr(0, 40) + "\n " + code.substr(40)
	ok = _expect("messy code decodes", bool(CustomFigures.decode_code(messy)["ok"]), true) and ok

	# --- damaged / foreign codes rejected ---
	ok = _expect("garbage rejected", bool(CustomFigures.decode_code("hola que tal")["ok"]), false) and ok
	ok = _expect("truncated rejected", bool(CustomFigures.decode_code(code.substr(0, 30))["ok"]), false) and ok

	# --- import saves + merges (usable) ---
	var r := CustomFigures.import_code(code)
	ok = _expect("import ok", bool(r["ok"]), true) and ok
	ok = _expect("import saved to disk", CustomFigures.exists(id), true) and ok
	var in_roster := false
	for f in Roster.FIGURES:
		if String(f.get("id", "")) == id:
			in_roster = bool(f.get("custom", false)) and String(f.get("glb", "")) != ""
	ok = _expect("import live in roster+model", in_roster, true) and ok

	# --- re-import same code: overwrites, no duplicate ---
	CustomFigures.import_code(code)
	var count := 0
	for f in CustomFigures.load_all():
		if String(f.get("id", "")) == id:
			count += 1
	ok = _expect("re-import no dup", count, 1) and ok

	# --- a code with a BUILT-IN id gets suffixed, never shadows it ---
	var evil := fig.duplicate(true)
	evil["id"] = "ironclad_knight"
	var r2 := CustomFigures.import_code(CustomFigures.export_code(evil))
	ok = _expect("builtin id import ok", bool(r2["ok"]), true) and ok
	ok = _expect("builtin not shadowed", CustomFigures.exists("ironclad_knight"), false) and ok
	ok = _expect("suffixed copy saved", CustomFigures.exists("ironclad_knight_2"), true) and ok
	CustomFigures.remove("ironclad_knight_2")

	# --- full backup pack: contains every saved figure ---
	var pack := CustomFigures.export_all_code()
	ok = _expect("pack has prefix", pack.begins_with("NCPACK1."), true) and ok
	var dp := CustomFigures.decode_code(pack)
	var found := false
	for f in dp["figs"]:
		if String(f.get("id", "")) == id:
			found = true
	ok = _expect("pack includes saved fig", found, true) and ok

	CustomFigures.remove(id)   # cleanup persisted file
	print("FIGCODE_OK" if ok else "FIGCODE_FAIL")
	quit()

func _expect(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print(("  %-36s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
