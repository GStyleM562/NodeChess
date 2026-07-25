extends SceneTree
## Tutoriales de GAMEPLAY EN VIVO: carga Board3D en cada lección guionada y
## RECORRE todos sus pasos (_tut_advance -> _tut_show -> marcador 👉), que es
## donde vivió el crash del 👉 invisible a los tests de datos. Si un paso crea un
## tween huérfano en bucle, el motor lanza "Infinite loop detected" y esto se
## colgaría (el timeout externo = fallo). Verifica: carga sin abortar, recorre
## los pasos y completa sin invalidar el tablero.

const LESSONS := ["deploy", "combat", "modifier", "jump", "surround", "block", "buff", "goal"]

func _initialize() -> void:
	get_root().set_content_scale_size(Vector2i(540, 960))
	var ok := true
	for id in LESSONS:
		ok = await _run_lesson(id) and ok
	print("LESSONS_LIVE_OK" if ok else "LESSONS_LIVE_FAIL")
	quit()

func _run_lesson(id: String) -> bool:
	var ok := true
	Loadout.lesson = id
	Loadout.tutorial = false
	var b = (load("res://scenes/board.tscn") as PackedScene).instantiate()
	get_root().add_child(b)
	# _ready (construye tablero + panel de pasos + primer 👉)
	for i in 20:
		await process_frame
	ok = _expect("%s: carga (tablero vivo)" % id, is_instance_valid(b) and b.get("_gs") != null, true) and ok
	# REGRESIÓN: las lecciones PRE-COLOCAN figuras en el tablero; si no se crea su
	# modelo 3D quedan invisibles/intocables y la lección se atora para siempre.
	# Toda unidad sobre el tablero AL CARGAR debe tener su Figure3D en _vis.
	var on_board: int = (b.get("_gs").board as Dictionary).size()
	var models: int = (b.get("_vis") as Dictionary).size()
	ok = _expect("%s: figuras con modelo 3D (%d/%d)" % [id, models, on_board], models, on_board) and ok
	var steps: int = (b.get("_steps_src") as Array).size()
	ok = _expect("%s: tiene pasos (%d)" % [id, steps], steps > 0, true) and ok
	# RECORRER todos los pasos: cada _tut_advance dibuja el 👉 del siguiente
	var guard := 0
	while is_instance_valid(b) and int(b.get("_tut_step")) < steps and guard < steps + 4:
		b.call("_tut_advance")
		guard += 1
		for i in 3:
			await process_frame
	ok = _expect("%s: recorrió sin colgarse" % id, is_instance_valid(b), true) and ok
	if is_instance_valid(b):
		b.queue_free()
	await process_frame
	await process_frame
	return ok

func _expect(label: String, got, want) -> bool:
	var p: bool = got == want
	print(("  %-34s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if p else "<<< FAIL")])
	return p
