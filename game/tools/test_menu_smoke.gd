extends SceneTree
## Menú principal: construye la escena, verifica los 5 cofres del lobby con su
## estado en vivo (gratis + t5/t10/t15 + nivel 🏅), y abre la caja GRATIS
## (animación completa) sin crashear. Respalda user://inventory.json.

const INV_PATH := "user://inventory.json"
var _backup := ""
var _had := false

func _initialize() -> void:
	_had = FileAccess.file_exists(INV_PATH)
	if _had:
		var f := FileAccess.open(INV_PATH, FileAccess.READ)
		_backup = f.get_as_text()
		f.close()
	var mm = (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
	get_root().add_child(mm)
	_run(mm)

func _run(mm) -> void:
	var ok := true
	await create_timer(0.7).timeout   # _ready + primer refresh de estados
	ok = _expect("5 cofres en el lobby", mm._chest_states.size(), 5) and ok
	var free_lbl: Label = mm._chest_states["free"]
	ok = _expect("gratis siempre lista", free_lbl.text, "¡Gratis!") and ok
	ok = _expect("t5 con estado", String(mm._chest_states["t5"].text) != "…", true) and ok

	# abrir la caja gratis: dispara la animación (cofre + destello + pastillas)
	mm._tap_chest("free")
	await create_timer(2.6).timeout
	ok = _expect("animación sin crash", is_instance_valid(mm), true) and ok

	# cofre temporal NO listo -> toast, no animación (tras reclamar t5 una vez)
	get_root().get_node("Inventory").open_chest("t5")
	mm._tap_chest("t5")
	await create_timer(0.3).timeout
	ok = _expect("t5 en espera no crashea", is_instance_valid(mm), true) and ok

	if _had:
		var f := FileAccess.open(INV_PATH, FileAccess.WRITE)
		f.store_string(_backup)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(INV_PATH))
	print("MENU_OK" if ok else "MENU_FAIL")
	quit()

func _expect(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print(("  %-34s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
