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

	# --- evolution via explicit stages (evolve INTO an existing figure) ---
	var ev := CC.make_figure({
		"name": "Evolver", "type": "Ruleta", "passives": [], "model_ref": "stone_golem",
		"pool": [{"col": "red", "w": 100}],
		"stages": [{"name": "Stone Golem", "type": "Ruleta", "stamina": 1, "passives": [],
			"attack": [{"col": "blue", "w": 100}], "evolves_id": "stone_golem"}],
	})
	ok = _expect("stages -> 1 rank", (ev.get("ranks", []) as Array).size(), 1) and ok
	ok = _expect("rank keeps evolves_id", String(ev["ranks"][0].get("evolves_id", "")), "stone_golem") and ok
	var n0 := Roster.FIGURES.size()
	CF.apply_live(ev)
	var n1 := Roster.FIGURES.size()
	ok = _expect("apply_live appended new", n1 == n0 + 1, true) and ok
	ev["stamina"] = 5
	CF.apply_live(ev)
	ok = _expect("apply_live replaced (no dup)", Roster.FIGURES.size(), n1) and ok
	# rank-up calls the CONFIGURED stage (evolves into Stone Golem -> a Blue pool)
	var gs2 := GameState.new(MapData.new())
	var ui := -1
	for i in Roster.FIGURES.size():
		if String(Roster.FIGURES[i].get("id", "")) == String(ev["id"]):
			ui = i
	var unit := gs2.add_to_bench("player", ui)
	gs2._try_rank_up(unit)
	var has_blue := false
	for s in gs2.pool_for(unit):
		if String(s.get("col", "")) == "blue":
			has_blue = true
	ok = _expect("rank-up uses configured stage", has_blue, true) and ok
	ok = _expect("rank name = stage name", gs2.name_for(unit).begins_with("Stone Golem"), true) and ok

	# rank-up swaps the 3D MODEL too (the stage carries its own glb)
	var mfig := CC.make_figure({
		"name": "Morpher", "type": "Ruleta", "passives": [], "model_ref": "stone_golem",
		"pool": [{"col": "red", "w": 100}],
		"stages": [{"name": "Witchy", "type": "Ruleta", "stamina": 2, "passives": [],
			"attack": [{"col": "red", "w": 100}], "glb": "res://assets/figures/venom_witch/witch/witch.glb",
			"clips": {"idle": "Idle_9"}, "size": 1.0, "evolves_id": "venom_witch"}],
	})
	CF.apply_live(mfig)
	var gs3 := GameState.new(MapData.new())
	var mui := -1
	for i in Roster.FIGURES.size():
		if String(Roster.FIGURES[i].get("id", "")) == String(mfig["id"]):
			mui = i
	var munit := gs3.add_to_bench("player", mui)
	var base_glb := String(gs3.model_data(munit)["glb"])
	gs3._try_rank_up(munit)
	var rank_glb := String(gs3.model_data(munit)["glb"])
	ok = _expect("model changes on rank-up", base_glb != rank_glb, true) and ok
	ok = _expect("ranked model = stage glb", rank_glb.ends_with("witch.glb"), true) and ok

	# old figures: stage has NO glb but DOES have evolves_id -> resolve the model live
	var ofig := CC.make_figure({
		"name": "OldEvo", "type": "Ruleta", "passives": [], "model_ref": "stone_golem",
		"pool": [{"col": "red", "w": 100}],
		"stages": [{"name": "Witchy", "type": "Ruleta", "stamina": 2, "passives": [],
			"attack": [{"col": "red", "w": 100}], "evolves_id": "venom_witch"}],
	})
	CF.apply_live(ofig)
	var gs4 := GameState.new(MapData.new())
	var oui := -1
	for i in Roster.FIGURES.size():
		if String(Roster.FIGURES[i].get("id", "")) == String(ofig["id"]):
			oui = i
	var ounit := gs4.add_to_bench("player", oui)
	gs4._try_rank_up(ounit)
	ok = _expect("model resolves from evolves_id", String(gs4.model_data(ounit)["glb"]).ends_with("witch.glb"), true) and ok

	# UI smoke test (await a frame so the scene's _ready runs and builds controls)
	var inst = load("res://scenes/character_creator.tscn").instantiate()
	get_root().add_child(inst)
	await process_frame
	ok = _expect("scene _ready built controls", inst._model != null, true) and ok
	ok = _expect("seeded pool has 3 segs", (inst.build_figure().get("attack", []) as Array).size(), 3) and ok
	inst.queue_free()

	# --- edit round-trip: load an existing figure into a fresh creator ---
	CC.edit_figure = {
		"id": "custom_edit_me", "name": "Edit Me", "type": "Moneda", "stamina": 4,
		"class": "Agile", "rarity": "legend", "passives": ["lunge"], "model_ref": "nightblade",
		"attack": [{"col": "white", "name": "Cut", "pow": 80, "w": 60}, {"col": "red", "w": 40}],
	}
	var ed = load("res://scenes/character_creator.tscn").instantiate()
	get_root().add_child(ed)
	await process_frame
	ok = _expect("edit: name loaded", ed._name.text, "Edit Me") and ok
	ok = _expect("edit: pool loaded (2)", (ed._rows as Array).size(), 2) and ok
	ok = _expect("edit: editing id set", ed._editing_id, "custom_edit_me") and ok
	ok = _expect("edit: static cleared", CC.edit_figure.is_empty(), true) and ok
	ed.queue_free()

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
