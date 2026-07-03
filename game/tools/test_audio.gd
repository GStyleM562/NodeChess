extends SceneTree
## Música/SFX: transiciones de estado (menu/battle/ventaja/peligro con RETORNO)
## y reproducción sin archivos (carpetas vacías) sin crashear.

func _initialize() -> void:
	var ok := true
	var m: Node = get_root().get_node("Music")
	var s: Node = get_root().get_node("Sfx")
	ok = _expect("autoload Music", m != null, true) and ok
	ok = _expect("autoload Sfx", s != null, true) and ok

	m.play_menu()
	ok = _expect("menu", m._cur, "menu") and ok
	# update_threat fuera de partida NO cambia nada
	m.update_threat(true, true)
	ok = _expect("threat ignorado en menú", m._cur, "menu") and ok

	m.play_battle()
	ok = _expect("battle", m._cur, "battle") and ok
	m.update_threat(true, false)
	ok = _expect("ventaja suena", m._cur, "advantage") and ok
	m.update_threat(false, false)
	ok = _expect("ventaja desaparece -> battle", m._cur, "battle") and ok
	m.update_threat(false, true)
	ok = _expect("peligro suena", m._cur, "danger") and ok
	m.update_threat(true, true)
	ok = _expect("peligro manda sobre ventaja", m._cur, "danger") and ok
	m.update_threat(true, false)
	ok = _expect("pasa a ventaja", m._cur, "advantage") and ok
	m.update_threat(false, false)
	ok = _expect("regresa a battle", m._cur, "battle") and ok

	# SFX sin archivos: no debe tronar
	for slot in ["ui_click", "attack_hit", "ko", "victory", "no_existe"]:
		s.play(slot)
	ok = _expect("sfx sin archivos no crashea", true, true) and ok

	# distancia de peligro/ventaja (BFS del mapa)
	var map := MapData.new()
	ok = _expect("dist goal->goal > 3", map.graph_dist(map.goal_player, map.goal_enemy) > 3, true) and ok
	ok = _expect("dist nodo a sí mismo", map.graph_dist(0, 0), 0) and ok
	var nb: int = map.adj[map.goal_player][0]
	ok = _expect("vecino de la meta = 1", map.graph_dist(nb, map.goal_player), 1) and ok

	print("AUDIO_OK" if ok else "AUDIO_FAIL")
	quit()

func _expect(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print(("  %-34s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
