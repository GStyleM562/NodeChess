extends SceneTree
## Character Creator data layer: save -> load -> merge into Roster -> usable by engine.

func _initialize() -> void:
	var ok := true
	var id := "test_custom_x"
	CustomFigures.remove(id)   # clean slate

	var fig := {
		"id": id, "name": "Test Custom", "stamina": 3, "type": "Ruleta",
		"passives": [], "attack": [{"col": "white", "name": "Hit", "pow": 50, "w": 1}],
	}
	CustomFigures.add(fig)
	ok = _expect("exists after add", CustomFigures.exists(id), true) and ok

	var found := false
	for f in CustomFigures.load_all():
		if String(f.get("id", "")) == id:
			found = true
	ok = _expect("load_all returns it", found, true) and ok

	CustomFigures.merge_into_roster()
	var idx := -1
	for i in Roster.FIGURES.size():
		if String(Roster.FIGURES[i].get("id", "")) == id:
			idx = i
	ok = _expect("merged into roster", idx != -1, true) and ok
	ok = _expect("placeholder model assigned", String(Roster.FIGURES[idx].get("glb", "")) != "", true) and ok
	ok = _expect("marked custom", bool(Roster.FIGURES[idx].get("custom", false)), true) and ok

	CustomFigures.merge_into_roster()   # idempotent
	var count := 0
	for f in Roster.FIGURES:
		if String(f.get("id", "")) == id:
			count += 1
	ok = _expect("merge idempotent (no dup)", count, 1) and ok

	# engine can build a unit and roll from the custom pool
	var gs := GameState.new(MapData.new())
	var u := gs.add_to_bench("player", idx)
	ok = _expect("rolls custom pool (white 50)", int(gs._roll_full(u, true)["seg"].get("pow", 0)), 50) and ok

	CustomFigures.remove(id)   # cleanup persisted file
	print("CUSTOMFIG_OK" if ok else "CUSTOMFIG_FAIL")
	quit()

func _expect(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print(("  %-36s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
