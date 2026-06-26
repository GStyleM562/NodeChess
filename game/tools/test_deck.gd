extends SceneTree
## Smoke test for the Deck Builder + Loadout. No 3D, so it finishes fast headless.

func _initialize() -> void:
	var db = load("res://scripts/DeckBuilder.gd").new()
	get_root().add_child(db)
	await create_timer(0.1).timeout
	print("UI_OK")
	print("DECK_SIZE=", Loadout.DECK_SIZE, " valid5=", Loadout.valid([0, 1, 2, 3, 4]), " valid3=", Loadout.valid([0, 1, 2]))
	db._team = []
	db._add(2)
	db._add(3)
	db._add(2)
	print("team_after_adds=", db._team)
	db._remove(0)
	print("team_after_remove=", db._team)
	print("DECK_OK")
	quit()
