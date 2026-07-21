extends SceneTree
## FULL tutorial: integridad de los guiones (nodos/figuras/índices válidos),
## bot ESTATUA, combate con resultado forzado, rodeo guionado, XP por capítulo
## (solo la primera vez) y persistencia de capítulos superados.

const SET_PATH := "user://settings.json"
var _backup := ""
var _had := false

func _initialize() -> void:
	var ok := true
	var s := get_root().get_node("Settings")
	# respaldar settings reales
	_had = FileAccess.file_exists(SET_PATH)
	if _had:
		var bf := FileAccess.open(SET_PATH, FileAccess.READ)
		_backup = bf.get_as_text()
		bf.close()
	s.tuts_done = []
	s.tutorial_done = false

	# --- integridad de TODOS los guiones ---
	var kinds := ["info", "deploy", "move", "attack", "mod", "end"]
	for c in TutorialLib.CHAPTERS:
		var id := String(c["id"])
		# "primera"/"menu_"/"meta_" no son lecciones de tablero guionadas
		if id == "primera" or id.begins_with("menu_") or id.begins_with("meta_"):
			continue
		var spec: Dictionary = TutorialLib.lesson(id)
		ok = _expect("%s: tiene guion" % id, spec.is_empty(), false) and ok
		var m := MapData.new(int(spec.get("map", 0)))
		for side in ["player", "enemy"]:
			for p in spec.get(side, []):
				var d: Dictionary = p
				ok = _expect("%s: figura válida" % id, int(d["ri"]) >= 0 and int(d["ri"]) < Roster.FIGURES.size(), true) and ok
				var n := int(d.get("node", -1))
				if n >= 0:
					ok = _expect("%s: nodo %d existe" % [id, n], n < m.nodes.size(), true) and ok
		for st in spec.get("steps", []):
			var sd: Dictionary = st
			ok = _expect("%s: paso válido (%s)" % [id, String(sd.get("do", "?"))], String(sd.get("do", "")) in kinds, true) and ok
			if sd.has("node"):
				ok = _expect("%s: objetivo existe" % id, int(sd["node"]) < m.nodes.size(), true) and ok
			if String(sd.get("do", "")) == "deploy":
				ok = _expect("%s: deploy en entrada" % id, int(sd["node"]) in m.entrances_player, true) and ok

	# --- bot ESTATUA: jamás actúa ---
	var g := GameState.new(MapData.new(0))
	g.bot_difficulty = -2
	var e := g.add_to_bench("enemy", 0)
	g.bench["enemy"].erase(e)
	g.units[e]["node"] = 16
	g.board[16] = e
	g.turn_team = "enemy"
	ok = _expect("estatua: pasa siempre", String(g.bot_action("enemy").get("type", "")), "pass") and ok
	ok = _expect("estatua: no se movió", int(g.units[e]["node"]), 16) and ok

	# --- lección de COMBATE: resultado YA marcado (blanco 80 vs rojo) ---
	var spec_c: Dictionary = TutorialLib.lesson("combat")
	var g2 := GameState.new(MapData.new(0))
	var a2 := g2.add_to_bench("player", 1)   # ironclad
	var d2 := g2.add_to_bench("enemy", 0)    # golem
	g2.bench["player"].erase(a2)
	g2.units[a2]["node"] = 4
	g2.board[4] = a2
	g2.bench["enemy"].erase(d2)
	g2.units[d2]["node"] = 6
	g2.board[6] = d2
	var step_atk: Dictionary = (spec_c["steps"] as Array)[1]
	var rec := g2.attack(a2, d2, 0, int(step_atk["ia"]), int(step_atk["ib"]))
	ok = _expect("combate guiado: gana el alumno", int(rec["result"]), 1) and ok
	ok = _expect("combate guiado: K.O. marcado", int(rec.get("ko", -1)), d2) and ok

	# --- lección de RODEO: cerrar el cerco lo detecta el motor ---
	var g3 := GameState.new(MapData.new(0))
	g3.turn_no = 6
	var p1 := g3.add_to_bench("player", 1)
	var p2 := g3.add_to_bench("player", 2)
	var v3 := g3.add_to_bench("enemy", 0)
	for setup in [[p1, 4], [v3, 6]]:
		g3.bench["player"].erase(setup[0])
		g3.bench["enemy"].erase(setup[0])
		g3.units[setup[0]]["node"] = setup[1]
		g3.board[setup[1]] = setup[0]
	g3.bench["player"].erase(p2)
	g3.units[p2]["node"] = 12
	g3.board[12] = p2
	ok = _expect("aún no rodeado (falta el 20)", g3.is_surrounded(v3), false) and ok
	g3.move_unit(p2, 20)
	ok = _expect("cerco cerrado: rodeado", g3.is_surrounded(v3), true) and ok

	# --- XP de capítulo: SOLO la primera vez, y persiste ---
	var inv := get_root().get_node("Inventory")
	inv._loaded = true
	inv.mode = "user"
	inv.xp = 0
	inv.level = 1
	var r1: Dictionary = TutorialLib.complete("deploy")
	ok = _expect("capítulo 1ª vez: da XP", bool(r1["first"]) and int(r1["xp"]) == 40, true) and ok
	ok = _expect("XP acreditada", inv.xp, 40) and ok
	ok = _expect("queda marcado", TutorialLib.is_done("deploy"), true) and ok
	var r2: Dictionary = TutorialLib.complete("deploy")
	ok = _expect("repetir: sin XP doble", bool(r2["first"]), false) and ok
	ok = _expect("XP no cambió", inv.xp, 40) and ok
	# "primera" se sincroniza con el tutorial clásico
	s.tutorial_done = true
	ok = _expect("primera ✓ via tutorial clásico", TutorialLib.is_done("primera"), true) and ok
	# conteos para la bienvenida
	ok = _expect("pendientes de menú = 2", TutorialLib.pending_in(TutorialLib.CAT_MENU), 2) and ok
	ok = _expect("hay XP por reclamar", TutorialLib.xp_pending() > 0, true) and ok

	# --- META (Progreso): páginas informativas + kit que se regala ---
	ok = _expect("hay capítulos meta (Progreso)", TutorialLib.pending_in(TutorialLib.CAT_META) >= 0, true) and ok
	for mid in ["meta_resources", "meta_boxes", "meta_inventory", "meta_create"]:
		ok = _expect("%s: páginas no vacías" % mid, (TutorialLib.meta_pages(mid) as Array).size() > 0, true) and ok
	inv.mode = "user"
	inv.pieces = {}
	inv.grant_tutorial_kit()
	ok = _expect("kit del tutorial: modelo básico dado", int(inv.pieces.get("model:ironclad_knight", 0)) >= 1, true) and ok
	ok = _expect("kit del tutorial: varias piezas", inv.pieces.size() >= 8, true) and ok
	# re-jugar el tutorial vuelve a garantizar el kit (top-up, no acumula infinito)
	inv.grant_tutorial_kit()
	ok = _expect("kit re-entregado: sigue >= 1", int(inv.pieces.get("model:ironclad_knight", 0)), 1) and ok

	# restaurar settings reales
	if _had:
		var rf := FileAccess.open(SET_PATH, FileAccess.WRITE)
		rf.store_string(_backup)
		rf.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SET_PATH))
	print("FULL_TUTORIAL_OK" if ok else "FULL_TUTORIAL_FAIL")
	quit()

func _expect(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print(("  %-38s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
