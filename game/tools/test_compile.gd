extends SceneTree
## Compile-check: load() each script so GDScript parses + compiles it (catches
## parse/type errors) WITHOUT instantiating any 3D nodes (which stall headless).

func _initialize() -> void:
	var ok := true
	for path in [
		"res://scripts/AttackPresenter.gd", "res://scripts/CombatOverlay.gd",
		"res://scripts/AttackTester.gd", "res://scripts/Board3D.gd",
		"res://scripts/DeckBuilder.gd", "res://scripts/Loadout.gd",
		"res://scripts/GameState.gd", "res://scripts/Combat.gd", "res://scripts/Roster.gd",
	]:
		var s = load(path)
		if s == null:
			ok = false
			print("LOAD_FAIL ", path)
		else:
			print("ok ", path)
	print("COMPILE_OK=", ok)
	quit()
