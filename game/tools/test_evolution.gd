extends SceneTree
## EVOLUCIÓN (F5): el checkbox "Es Evolución" sube el presupuesto ×1.30, y una
## figura-evolución DESPLEGADA sin evolucionar juega a la mitad (estamina/daño,
## −1★), sin pasivas y con la clase anulada, TODA la partida. Las resistencias
## construidas SOBREVIVEN; las ocultas del modelo se pierden.

func _initialize() -> void:
	var ok := true

	# --- presupuesto ×1.30 ---
	var base := {"rarity": "epic", "class": "Balanced", "stamina": 2, "type": "Ruleta", "attack": []}
	var b0 := PiecePoints.budget(base)
	var be := PiecePoints.budget(_with(base, "is_evolution", true))
	ok = _expect("Es Evolución: presupuesto ×1.30", be, int(round(b0 * 1.30))) and ok

	# --- una figura-evolución construida sobre un modelo con innatas ---
	# modelo con: pasiva oculta Bedrock + resistencia oculta Congelado.
	Roster.FIGURES.append({"id": "ev_model", "name": "Modelo", "stamina": 2, "type": "Ruleta",
		"innate": {"pc": 0, "passives": ["bedrock"], "resists": ["freeze"]},
		"attack": [{"col": "white", "pow": 40, "w": 100}]})
	Roster.FIGURES.append({
		"id": "ev_fig", "name": "Titán", "class": "Striker", "rarity": "legend",
		"stamina": 4, "type": "Ruleta", "model_ref": "ev_model",
		"is_evolution": true,
		"passives": ["lunge"],           # pasiva CONSTRUIDA
		"resists": ["fear"],             # resistencia CONSTRUIDA (sobrevive)
		"attack": [{"col": "white", "name": "Golpe", "pow": 100, "w": 60},
			{"col": "purple", "name": "Hechizo", "stars": 2, "fx": "Miedo", "w": 40}]})
	var ri := Roster.FIGURES.size() - 1

	var g := GameState.new(MapData.new(0))
	var uid := g.add_to_bench("player", ri)
	ok = _expect("marcada como sin evolucionar", bool(g.units[uid].get("unevolved", false)), true) and ok
	# colocarla en el tablero (effective_stamina mira sus vecinos)
	g.bench["player"].erase(uid)
	g.units[uid]["node"] = 4
	g.board[4] = uid

	# ESTAMINA a la mitad (4 → 2) — y la clase Striker (−1) está anulada
	ok = _expect("estamina 4 → 2 (mitad, clase anulada)", g.effective_stamina(uid), 2) and ok

	# DAÑO a la mitad, ★ −1 (la clase Striker +15 NO aplica)
	var white_seg := {}
	var purple_seg := {}
	for i in 40:
		var seg: Dictionary = g._roll_full(uid, true)["seg"]
		if String(seg.get("col", "")) == "white":
			white_seg = seg
		elif String(seg.get("col", "")) == "purple":
			purple_seg = seg
	ok = _expect("Blanco 100 → 50 (mitad, sin +15 de clase)", int(white_seg.get("pow", -1)), 50) and ok
	ok = _expect("Púrpura ★2 → ★1 (−1)", int(purple_seg.get("stars", -1)), 1) and ok

	# SIN pasivas (ni construida ni oculta del modelo)
	ok = _expect("pierde la pasiva CONSTRUIDA (Lunge)", g.has_passive(uid, "lunge"), false) and ok
	ok = _expect("pierde la pasiva OCULTA (Bedrock)", g.has_passive(uid, "bedrock"), false) and ok

	# RESISTENCIAS: la construida sobrevive, la oculta del modelo se pierde
	ok = _expect("conserva la resistencia CONSTRUIDA (Miedo)", g.resists_status(uid, "fear"), true) and ok
	ok = _expect("pierde la resistencia OCULTA (Congelado)", g.resists_status(uid, "freeze"), false) and ok

	# --- una figura NORMAL (no evolución) del mismo estilo NO se penaliza ---
	Roster.FIGURES.append({
		"id": "ev_norm", "name": "Normal", "class": "Striker", "rarity": "legend",
		"stamina": 4, "type": "Ruleta", "model_ref": "ev_model", "passives": ["lunge"],
		"attack": [{"col": "white", "name": "Golpe", "pow": 100, "w": 100}]})
	var g2 := GameState.new(MapData.new(0))
	var u2 := g2.add_to_bench("player", Roster.FIGURES.size() - 1)
	g2.bench["player"].erase(u2)
	g2.units[u2]["node"] = 4
	g2.board[4] = u2
	ok = _expect("figura normal: sin penalización", bool(g2.units[u2].get("unevolved", false)), false) and ok
	ok = _expect("normal: estamina 4 + clase −1 = 3", g2.effective_stamina(u2), 3) and ok
	ok = _expect("normal: conserva Lunge", g2.has_passive(u2, "lunge"), true) and ok

	print("EVOLUTION_OK" if ok else "EVOLUTION_FAIL")
	quit()

func _with(d: Dictionary, k: String, v) -> Dictionary:
	var out := d.duplicate(true)
	out[k] = v
	return out

func _expect(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print(("  %-44s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
