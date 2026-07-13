extends SceneTree
## CLASES (F3): los buffs/debuffs de cada clase se aplican EN PARTIDA
## (estamina, daño, estrellas, estados, energía, desplazamiento, inmunidad).

func _mk(cls: String, extra := {}) -> int:
	var f := {"id": "cl_" + cls.to_lower() + str(randi()), "name": cls, "class": cls,
		"stamina": 3, "type": "Ruleta", "passives": [],
		"attack": [{"col": "white", "name": "Golpe", "pow": 60, "w": 100}]}
	for k in extra:
		f[k] = extra[k]
	Roster.FIGURES.append(f)
	return Roster.FIGURES.size() - 1

func _initialize() -> void:
	var ok := true

	# --- ESTAMINA: Ágil +1 · Tanque/Atacante/Potenciador −1 ---
	var g := GameState.new(MapData.new(0))
	var agile := _place(g, "Agile", 4)
	var tank := _place(g, "Tank", 6)
	ok = _expect("Ágil: estamina 3 → 4", g.effective_stamina(agile), 4) and ok
	ok = _expect("Tanque: estamina 3 → 2", g.effective_stamina(tank), 2) and ok

	# --- DAÑO: Atacante +15 · Ágil −10 (en la tirada) ---
	var gd := GameState.new(MapData.new(0))
	var strike := _place(gd, "Striker", 4)
	var seg_s: Dictionary = gd._roll_full(strike, true)["seg"]
	ok = _expect("Atacante: Blanco 60 → 75", int(seg_s["pow"]), 75) and ok
	var ag2 := _place(gd, "Agile", 6)
	var seg_a: Dictionary = gd._roll_full(ag2, true)["seg"]
	ok = _expect("Ágil: Blanco 60 → 50", int(seg_a["pow"]), 50) and ok

	# --- ESTRELLAS: Debilitador +1★ · Ágil −1★ (piso 1) ---
	var gp := GameState.new(MapData.new(0))
	var deb := _place(gp, "Debuffer", 4, {"attack": [{"col": "purple", "stars": 2, "fx": "Miedo", "w": 100}]})
	var seg_d: Dictionary = gp._roll_full(deb, true)["seg"]
	ok = _expect("Debilitador: ★2 → ★3", int(seg_d["stars"]), 3) and ok
	var ag3 := _place(gp, "Agile", 6, {"attack": [{"col": "purple", "stars": 1, "fx": "Miedo", "w": 100}]})
	var seg_a3: Dictionary = gp._roll_full(ag3, true)["seg"]
	ok = _expect("Ágil: ★1 no baja de 1", int(seg_a3["stars"]), 1) and ok

	# --- TANQUE: resiste Debilitado · Azul indestructible con Escudo Roto ---
	var gt := GameState.new(MapData.new(0))
	var tk := _place(gt, "Tank", 4, {"attack": [{"col": "blue", "name": "Muro", "w": 100}]})
	ok = _expect("Tanque resiste Debilitado", gt.apply_status(tk, "weakened"), false) and ok
	gt.units[tk]["statuses"]["shield_break"] = 999
	var seg_t: Dictionary = gt._roll_full(tk, false)["seg"]
	ok = _expect("Tanque: Azul aguanta Escudo Roto", String(seg_t["col"]), "blue") and ok
	# una figura sin clase SÍ pierde el azul con Escudo Roto
	var plain := _place(gt, "Balanced", 6, {"attack": [{"col": "blue", "name": "Muro", "w": 100}]})
	gt.units[plain]["statuses"]["shield_break"] = 999
	ok = _expect("sin clase: Azul colapsa a Rojo", String(gt._roll_full(plain, false)["seg"]["col"]), "red") and ok

	# --- CONTROLADOR: inmune a ser desplazado + desplazamiento +1 nodo ---
	var gc := GameState.new(MapData.new(0))
	var ctrl := _place(gc, "Controller", 4)
	ok = _expect("Controlador inmune a desplazamiento", gc._displacement_immune(ctrl), true) and ok

	# --- POTENCIADOR: +1 energía por turno al equipo ---
	var ge := GameState.new(MapData.new(0))
	_place(ge, "Buffer", 4)
	ge.energy["player"] = 0
	ge._grant_energy("player")
	ok = _expect("Potenciador: +1 energía extra (2/turno)", int(ge.energy["player"]), GameState.ENERGY_PER_TURN + 1) and ok

	# --- DEBILITADOR: sus estados duran +2 turnos ---
	var gs := GameState.new(MapData.new(0))
	var d2 := _place(gs, "Debuffer", 4)
	var vic := _place(gs, "Balanced", 6)
	gs.turn_no = 0
	gs.apply_status(vic, "fear", -1, gs._cfx(d2, "status_turns"))
	ok = _expect("Debilitador: estado +2 turnos", int(gs.units[vic]["statuses"]["fear"]), GameState.STATUS_DUR + 2) and ok

	# --- class_off (F5): anula todos los efectos de clase ---
	var gx := GameState.new(MapData.new(0))
	var off := _place(gx, "Agile", 4)
	gx.units[off]["class_off"] = true
	ok = _expect("class_off anula el buff de estamina", gx.effective_stamina(off), 3) and ok

	print("CLASSES_OK" if ok else "CLASSES_FAIL")
	quit()

## Coloca una figura de la clase dada en un nodo libre y devuelve su uid.
func _place(g: GameState, cls: String, node: int, extra := {}) -> int:
	var ri := _mk(cls, extra)
	var uid := g.add_to_bench("player" if node < 10 else "enemy", ri)
	g.bench["player"].erase(uid)
	g.bench["enemy"].erase(uid)
	g.units[uid]["node"] = node
	g.board[node] = uid
	return uid

func _expect(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print(("  %-42s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
