extends SceneTree
## Loadout persistence: team + modifiers + map survive a save/load by figure id.

func _initialize() -> void:
	var ok := true
	Loadout.player_team = [0, 1, 2, 3, 4]
	Loadout.player_modifiers = ["fury", "cleanse"]
	Loadout.map_index = 2
	Loadout.save()

	Loadout.player_team = [4, 4, 4, 4, 4]
	Loadout.player_modifiers = []
	Loadout.map_index = 0
	Loadout.load()

	ok = _expect("team restored", Loadout.player_team, [0, 1, 2, 3, 4]) and ok
	ok = _expect("mods restored", Loadout.player_modifiers, ["fury", "cleanse"]) and ok
	ok = _expect("map restored", Loadout.map_index, 2) and ok

	if FileAccess.file_exists(Loadout.PATH):
		DirAccess.remove_absolute(Loadout.PATH)
	print("LOADOUT_OK" if ok else "LOADOUT_FAIL")
	quit()

func _expect(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print(("  %-16s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
