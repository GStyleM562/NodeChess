extends SceneTree
## Inventario/monetización: modos admin-usuario, kit inicial, fragmentos→pieza,
## cajas (gratis + cofres 5/10/15 con timer de reloj real que REARMA al reclamar),
## regalo admin ×3 y bloqueo de figuras por piezas faltantes.

const INV_PATH := "user://inventory.json"
var _backup := ""
var _had_file := false

func _initialize() -> void:
	var ok := true
	var inv: Node = get_root().get_node("Inventory")

	# respaldar el inventario REAL y partir de cero
	_had_file = FileAccess.file_exists(INV_PATH)
	if _had_file:
		var bf := FileAccess.open(INV_PATH, FileAccess.READ)
		_backup = bf.get_as_text()
		bf.close()
	inv._loaded = true
	inv.mode = "admin"
	inv.pieces = {}
	inv.fragments = {}
	inv.next_chest = {}
	inv._starter = false

	# --- admin: todo ilimitado ---
	ok = _expect("admin por defecto", inv.is_admin(), true) and ok
	ok = _expect("admin posee todo", inv.has_piece("stamina:6"), true) and ok
	var fuerte := {"name": "X", "id": "x", "stamina": 3, "type": "Dado (D8)", "rarity": "mythic",
		"passives": ["lunge"], "model_ref": "ninja",
		"attack": [{"col": "gold", "pow": 100, "fx": "Miedo", "w": 1}]}
	ok = _expect("admin nunca bloquea", inv.missing_pieces(fuerte).size(), 0) and ok

	# --- usuario: kit inicial + bloqueo real ---
	inv.set_mode("user")
	ok = _expect("kit inicial: blanco", inv.has_piece("color:white"), true) and ok
	ok = _expect("kit inicial: estamina 2", inv.has_piece("stamina:2"), true) and ok
	var falta: Array = inv.missing_pieces(fuerte)
	ok = _expect("bloquea estamina 3", "stamina:3" in falta, true) and ok
	ok = _expect("bloquea tipo D8", "atype:Dado (D8)" in falta, true) and ok
	ok = _expect("bloquea estado Miedo", "fx:Miedo" in falta, true) and ok
	ok = _expect("bloquea figura ninja", "model:ninja" in falta, true) and ok
	# figura del kit inicial: NO bloqueada
	var basica := {"name": "B", "id": "b", "stamina": 2, "type": "Ruleta", "rarity": "epic",
		"passives": [], "model_ref": "ironclad_knight",
		"attack": [{"col": "white", "pow": 60, "w": 50}, {"col": "blue", "w": 30}, {"col": "red", "w": 20}]}
	ok = _expect("figura básica permitida", inv.missing_pieces(basica).size(), 0) and ok

	# --- fragmentos: 10 = 1 pieza ---
	inv.add_frags("stamina:3", 9)
	ok = _expect("9 frag: no convierte", inv.convert("stamina:3"), false) and ok
	inv.add_frags("stamina:3", 1)
	ok = _expect("10 frag: convierte", inv.convert("stamina:3"), true) and ok
	ok = _expect("pieza obtenida", inv.has_piece("stamina:3"), true) and ok
	ok = _expect("frag consumidos", inv.frags("stamina:3"), 0) and ok

	# --- caja gratis: fragmentos ---
	var got: Dictionary = inv.open_free()
	ok = _expect("caja gratis da frag", got.size() > 0, true) and ok

	# --- cofres temporales: dan piezas y REARMAN su timer ---
	ok = _expect("t5 listo de inicio", inv.chest_ready("t5"), true) and ok
	var p5: Array = inv.open_chest("t5")
	ok = _expect("t5 da 2 piezas", p5.size(), 2) and ok
	ok = _expect("t5 timer rearmado ~5min", inv.chest_left("t5") > 290, true) and ok
	ok = _expect("t5 no reabre", inv.open_chest("t5").size(), 0) and ok
	var p15: Array = inv.open_chest("t15")
	ok = _expect("t15 da 4 piezas", p15.size(), 4) and ok
	ok = _expect("t15 figura garantizada", String(p15[0]).begins_with("model:"), true) and ok
	ok = _expect("t15 timer ~15min", inv.chest_left("t15") > 880, true) and ok

	# --- regalo admin ×3 ---
	var antes := int(inv.pieces.get("passive:lunge", 0))
	inv.gift_all(3)
	ok = _expect("regalo: +3 de cada pieza", int(inv.pieces.get("passive:lunge", 0)), antes + 3) and ok
	ok = _expect("tras regalo ya no falta nada", inv.missing_pieces(fuerte).size(), 0) and ok

	# --- ECONOMÍA: crear GASTA piezas; editar cobra el delta y reembolsa ---
	var figA := {"id": "eco", "name": "Eco", "stamina": 2, "type": "Ruleta", "rarity": "epic",
		"passives": [], "model_ref": "ironclad_knight",
		"attack": [{"col": "white", "pow": 40, "w": 80}, {"col": "red", "w": 20}]}
	var w_before: int = int(inv.pieces.get("color:white", 0))
	inv.consume_for(figA)
	ok = _expect("crear gasta blanco -1", int(inv.pieces.get("color:white", 0)), w_before - 1) and ok
	# editar: cambia blanco -> oro (cobra oro, devuelve blanco)
	var figB = figA.duplicate(true)
	figB["attack"] = [{"col": "gold", "pow": 40, "w": 80}, {"col": "red", "w": 20}]
	var g_before: int = int(inv.pieces.get("color:gold", 0))
	inv.adjust_for_edit(figA, figB)
	ok = _expect("editar cobra oro -1", int(inv.pieces.get("color:gold", 0)), g_before - 1) and ok
	ok = _expect("editar devuelve blanco +1", int(inv.pieces.get("color:white", 0)), w_before) and ok
	# missing_for_edit: sin piezas sueltas, las de la figura ORIGINAL cuentan
	inv.pieces["color:gold"] = 0
	ok = _expect("edit: pieza invertida no falta", "color:gold" in inv.missing_pieces_for(figB, figB), false) and ok
	ok = _expect("crear nuevo SÍ la exige", "color:gold" in inv.missing_pieces_for(figB, {}), true) and ok

	# --- XP y NIVELES: sube jugando y otorga COFRES de nivel ---
	inv.xp = 0
	inv.level = 1
	inv.level_chests = 0
	inv.wins = 0
	inv.losses = 0
	inv.streak = 0
	inv.best_streak = 0
	var r1: Dictionary = inv.add_match_xp(true, false)
	ok = _expect("victoria da 60 XP", int(r1["gained"]), 60) and ok
	ok = _expect("aún nivel 1", inv.level, 1) and ok
	var r2: Dictionary = inv.add_match_xp(true, true)   # +75 (online) -> 135 >= 100
	ok = _expect("sube a nivel 2", int(r2["level"]), 2) and ok
	ok = _expect("otorga 1 cofre de nivel", int(r2["chests"]), 1) and ok
	ok = _expect("cofre pendiente", inv.level_chests, 1) and ok
	ok = _expect("xp sobrante correcto", inv.xp, 35) and ok
	var lp: Array = inv.open_level_chest()
	ok = _expect("cofre de nivel da 3 piezas", lp.size(), 3) and ok
	ok = _expect("cofre consumido", inv.level_chests, 0) and ok
	ok = _expect("sin cofres no abre", inv.open_level_chest().size(), 0) and ok
	var r3: Dictionary = inv.add_match_xp(false, false)   # derrota: +25
	ok = _expect("derrota da 25 XP", int(r3["gained"]), 25) and ok
	# --- estadísticas de PERFIL (2 victorias + 1 derrota arriba) ---
	ok = _expect("perfil: 2 ganadas", inv.wins, 2) and ok
	ok = _expect("perfil: 1 perdida", inv.losses, 1) and ok
	ok = _expect("perfil: mejor racha 2", inv.best_streak, 2) and ok
	ok = _expect("perfil: racha actual 0", inv.streak, 0) and ok

	# --- persistencia ---
	var f := FileAccess.open(INV_PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text()) if f != null else null
	if f != null:
		f.close()
	ok = _expect("json persistido (modo user)", data is Dictionary and String(data.get("mode", "")) == "user", true) and ok

	# restaurar el inventario real
	if _had_file:
		var rf := FileAccess.open(INV_PATH, FileAccess.WRITE)
		rf.store_string(_backup)
		rf.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(INV_PATH))

	print("INVENTORY_OK" if ok else "INVENTORY_FAIL")
	quit()

func _expect(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print(("  %-34s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
