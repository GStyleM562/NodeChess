extends SceneTree
## AUDITORIA de reglas de combate contra el GDD (Parte 1):
## 1) Matriz completa de colores vs una tabla de verdad independiente.
## 2) El caso reportado: Oro 130 vs Blanco 60 en el PRIMER combate (sin boosts).
## 3) Primer combate = numeros EXACTOS del pool (ningun boost fantasma).
## 4) Morados aplican su efecto al perdedor (y no noquean).
## 5) Boosts legitimos: Marcado (+20), Debilitado (-20), modificador Surge, buff node.

var gs: GameState
var A := -1   # attacker uid (pool controlado)
var D := -1   # defender uid (pool controlado)

func _initialize() -> void:
	var ok := true

	# --- 1) matriz de colores: Combat.resolve vs tabla de verdad del GDD ---
	var segs: Array = [
		{"col": "white", "pow": 0}, {"col": "white", "pow": 60}, {"col": "white", "pow": 130},
		{"col": "gold", "pow": 0}, {"col": "gold", "pow": 60}, {"col": "gold", "pow": 130},
		{"col": "purple", "stars": 1}, {"col": "purple", "stars": 3},
		{"col": "blue"}, {"col": "red"},
	]
	var bad := 0
	for a in segs:
		for b in segs:
			if Combat.resolve(a, b) != _gdd_expected(a, b):
				bad += 1
				print("  MISMATCH: %s vs %s got=%d want=%d" % [str(a), str(b), Combat.resolve(a, b), _gdd_expected(a, b)])
	ok = _expect("matriz 10x10 coincide con el GDD", bad, 0) and ok

	# --- unidades con pools controlados de UN segmento (deterministas) ---
	gs = GameState.new(MapData.new())
	Roster.FIGURES.append({"id": "audit_gold", "name": "Audit Gold", "stamina": 2, "type": "Ruleta",
		"passives": [], "attack": [{"col": "gold", "name": "Golpe Oro", "pow": 130, "w": 100}]})
	Roster.FIGURES.append({"id": "audit_white", "name": "Audit White", "stamina": 2, "type": "Ruleta",
		"passives": [], "attack": [{"col": "white", "name": "Golpe Blanco", "pow": 60, "w": 100}]})
	Roster.FIGURES.append({"id": "audit_purple", "name": "Audit Purple", "stamina": 2, "type": "Ruleta",
		"passives": [], "attack": [{"col": "purple", "name": "Miedo Gas", "stars": 2, "fx": "Miedo", "w": 100}]})
	var i_gold := Roster.FIGURES.size() - 3
	var i_white := Roster.FIGURES.size() - 2
	var i_purple := Roster.FIGURES.size() - 1

	# --- 2) EL BUG: oro 130 ataca a blanco 60, primer combate -> oro DEBE ganar ---
	A = gs.add_to_bench("player", i_gold)
	D = gs.add_to_bench("enemy", i_white)
	_place(A, D)
	var rec := gs.attack(A, D, 0, 0, 0)
	ok = _expect("oro130 vs blanco60: gana oro", int(rec["result"]), 1) and ok
	ok = _expect("oro130 vs blanco60: KO al blanco", int(rec["ko"]), D) and ok

	# --- 3) primer combate: numeros EXACTOS del pool (sin boosts fantasma) ---
	ok = _expect("seg atacante intacto (130)", int((rec["seg_a"] as Dictionary).get("pow", -1)), 130) and ok
	ok = _expect("seg defensor intacto (60)", int((rec["seg_b"] as Dictionary).get("pow", -1)), 60) and ok

	# --- 4) morados: aplican su estado al perdedor, sin KO ---
	var P := gs.add_to_bench("player", i_purple)
	var W2 := gs.add_to_bench("enemy", i_white)
	_place(P, W2)
	var rec2 := gs.attack(P, W2, 0, 0, 0)
	ok = _expect("purpura vence a blanco", int(rec2["result"]), 1) and ok
	ok = _expect("purpura NO noquea", int(rec2["ko"]), -1) and ok
	ok = _expect("estado aplicado: fear", String((rec2["status"] as Dictionary).get("status", "")), "fear") and ok
	ok = _expect("defensor sigue vivo con Miedo", gs.has_status(W2, "fear"), true) and ok
	# y el Miedo tiene efecto real: no puede atacar
	ok = _expect("con Miedo no puede atacar", gs.can_attack(W2), false) and ok
	# purpura vs oro: pierde (oro vence a purpura) aunque tenga ★3
	var G2 := gs.add_to_bench("enemy", i_gold)
	_place(P, G2)
	gs.units[P]["statuses"] = {}
	var rec3 := gs.attack(P, G2, 0, 0, 0)
	ok = _expect("purpura pierde vs oro", int(rec3["result"]), -1) and ok

	# --- 5) boosts LEGITIMOS y su magnitud exacta ---
	# Marcado: atacar a un Marcado da +20 de dano.
	var A2 := gs.add_to_bench("player", i_white)   # blanco 60
	var D2 := gs.add_to_bench("enemy", i_white)    # blanco 60
	_place(A2, D2)
	gs.apply_status(D2, "marked")
	var rec4 := gs.attack(A2, D2, 0, 0, 0)
	ok = _expect("Marcado: 60+20=80 atacante", int((rec4["seg_a"] as Dictionary).get("pow", -1)), 80) and ok
	ok = _expect("Marcado: gana el atacante", int(rec4["result"]), 1) and ok
	# Debilitado: -20 de dano al que lo sufre.
	var A3 := gs.add_to_bench("player", i_white)
	var D3 := gs.add_to_bench("enemy", i_white)
	_place(A3, D3)
	gs.apply_status(A3, "weakened")
	var rec5 := gs.attack(A3, D3, 0, 0, 0)
	ok = _expect("Debilitado: 60-20=40 atacante", int((rec5["seg_a"] as Dictionary).get("pow", -1)), 40) and ok
	ok = _expect("Debilitado: pierde el atacante", int(rec5["result"]), -1) and ok
	# Modificador Surge (+20) se aplica UNA vez y se consume.
	var A4 := gs.add_to_bench("player", i_white)
	var D4 := gs.add_to_bench("enemy", i_gold)   # oro 130
	_place(A4, D4)
	gs.pending_buff["player"] = {"surge": true}
	var rec6 := gs.attack(A4, D4, 0, 0, 0)
	ok = _expect("Surge: 60+20=80", int((rec6["seg_a"] as Dictionary).get("pow", -1)), 80) and ok
	ok = _expect("Surge consumido", (gs.pending_buff["player"] as Dictionary).is_empty(), true) and ok
	ok = _expect("80 blanco pierde vs 130 oro", int(rec6["result"]), -1) and ok

	# limpiar figuras de auditoria del roster
	for n in 3:
		Roster.FIGURES.pop_back()
	print("RULES_AUDIT_OK" if ok else "RULES_AUDIT_FAIL")
	quit()

## Coloca atacante y defensor en nodos adyacentes NEUTRALES (sin buff node).
func _place(a: int, d: int) -> void:
	for u in [a, d]:
		gs.units[u]["alive"] = true
		var old := int(gs.units[u]["node"])
		if gs.board.get(old, -1) == u:
			gs.board.erase(old)
	var pair := _neutral_pair()
	gs.units[a]["node"] = pair[0]
	gs.units[d]["node"] = pair[1]
	gs.board[pair[0]] = a
	gs.board[pair[1]] = d

func _neutral_pair() -> Array:
	for n in gs.map.nodes:
		var id := int(n["id"])
		if id in gs.map.buffs or id in gs.map.obstacles or gs.board.has(id):
			continue
		for nb in gs.map.adj[id]:
			if nb in gs.map.buffs or nb in gs.map.obstacles or gs.board.has(nb):
				continue
			return [id, nb]
	return [0, 1]

## Tabla de verdad INDEPENDIENTE segun el GDD Parte 1.
func _gdd_expected(a: Dictionary, b: Dictionary) -> int:
	var ca := String(a.get("col", ""))
	var cb := String(b.get("col", ""))
	if ca == "red" and cb == "red": return 0
	if ca == "red": return -1
	if cb == "red": return 1
	if ca == "blue" and cb == "blue": return 0
	if ca == "blue": return 1
	if cb == "blue": return -1
	if ca == cb:
		if ca == "purple":
			return signi(int(a.get("stars", 0)) - int(b.get("stars", 0)))
		return signi(int(a.get("pow", 0)) - int(b.get("pow", 0)))
	# cruces: purpura>blanco, oro>purpura, blanco-oro = por dano
	if ca == "purple" and cb == "white": return 1
	if ca == "white" and cb == "purple": return -1
	if ca == "gold" and cb == "purple": return 1
	if ca == "purple" and cb == "gold": return -1
	return signi(int(a.get("pow", 0)) - int(b.get("pow", 0)))   # white vs gold

func _expect(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print(("  %-38s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
