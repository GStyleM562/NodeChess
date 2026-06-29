extends SceneTree
## Character Creator end-to-end: pure builder -> validate -> save -> merge ->
## playable, plus a smoke test that the UI scene builds without error.

const CC := preload("res://scripts/CharacterCreator.gd")
const CF := preload("res://scripts/CustomFigures.gd")
const FV := preload("res://scripts/FigureValidator.gd")

func _initialize() -> void:
	var ok := true
	var fig := CC.make_figure({
		"name": "Mi Bruja", "class": "Debuffer", "rarity": "epic", "stamina": 2,
		"type": "Ruleta", "passives": ["venom_hex"], "model_ref": "venom_witch", "evolve": true,
		"pool": [
			{"col": "purple", "name": "Veneno", "stars": 2, "fx_index": _fx("Veneno"), "w": 40},
			{"col": "white", "name": "Bolt", "pow": 50, "w": 40},
			{"col": "red", "w": 20},
		],
	})
	ok = _expect("slug id", String(fig["id"]), "custom_mi_bruja") and ok
	ok = _expect("evolves (1 rank)", (fig.get("ranks", []) as Array).size(), 1) and ok
	var pfx := ""
	for s in fig["attack"]:
		if String(s.get("col", "")) == "purple":
			pfx = String(s.get("fx", ""))
	ok = _expect("purple carries fx Veneno", pfx, "Veneno") and ok
	var evw := 0
	for s in fig["ranks"][0]["attack"]:
		if String(s.get("col", "")) == "white":
			evw = int(s.get("pow", 0))
	ok = _expect("evolved white 50 -> 70", evw, 70) and ok
	ok = _expect("not INVALID", String(FV.validate(fig)["state"]) == "INVALID", false) and ok

	CF.remove(String(fig["id"]))
	CF.add(fig)
	CF.merge_into_roster()
	var idx := -1
	for i in Roster.FIGURES.size():
		if String(Roster.FIGURES[i].get("id", "")) == String(fig["id"]):
			idx = i
	ok = _expect("merged + playable", idx != -1, true) and ok
	var gs := GameState.new(MapData.new())
	var u := gs.add_to_bench("player", idx)
	ok = _expect("rolls a valid colour", String(gs._roll_full(u, true)["seg"].get("col", "")) in ["white", "purple", "red"], true) and ok
	CF.remove(String(fig["id"]))

	# UI smoke test (await a frame so the scene's _ready runs and builds controls)
	var inst = load("res://scenes/character_creator.tscn").instantiate()
	get_root().add_child(inst)
	await process_frame
	ok = _expect("scene _ready built controls", inst._model != null, true) and ok
	ok = _expect("seeded pool has 3 segs", (inst.build_figure().get("attack", []) as Array).size(), 3) and ok
	inst.queue_free()

	print("CREATOR_OK" if ok else "CREATOR_FAIL")
	quit()

func _fx(label: String) -> int:
	for i in CC.FX_OPTS.size():
		if String(CC.FX_OPTS[i].get("fx", "")) == label:
			return i
	return 0

func _expect(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print(("  %-30s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
