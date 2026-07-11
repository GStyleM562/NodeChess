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

	# --- MULTI-MAZOS: cambiar muestra el equipo REAL; borrar no pisa el destino ---
	Loadout.player_team = [0, 1, 2, 3, 4, 6]
	Loadout.stash_active()                        # mazo 0 completo (6)
	Loadout.decks.append({"name": "Vacío", "team": [], "mods": [], "map": 0})
	Loadout.switch_deck(1)
	ok = _expect("mazo vacío se VE vacío", Loadout.player_team.size(), 0) and ok
	ok = _expect("mazo vacío NO está listo", Loadout.active_ready(), false) and ok
	Loadout.switch_deck(0)
	ok = _expect("volver: mazo 0 completo", Loadout.player_team.size(), 6) and ok
	ok = _expect("mazo 0 SÍ está listo", Loadout.active_ready(), true) and ok
	# borrar el mazo 1 SIN volcar su estado sobre el 0 (bug viejo del builder)
	Loadout.switch_deck(1)
	Loadout.decks.remove_at(Loadout.active_deck)
	Loadout.switch_deck(0, false)
	ok = _expect("tras borrar: mazo 0 intacto", Loadout.player_team.size(), 6) and ok
	ok = _expect("nombre en uso", Loadout.active_name() != "", true) and ok

	if FileAccess.file_exists(Loadout.PATH):
		DirAccess.remove_absolute(Loadout.PATH)
	print("LOADOUT_OK" if ok else "LOADOUT_FAIL")
	quit()

func _expect(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print(("  %-16s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
