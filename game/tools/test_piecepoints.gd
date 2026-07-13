extends SceneTree
## Puntos de Construcción (PiecePoints): las 8 figuras integradas CABEN en su
## presupuesto, el orden por rareza es correcto, y las fuentes (clase/evolución/
## innato) suben el presupuesto como diseñado.

func _initialize() -> void:
	var ok := true

	# --- las 12 figuras integradas caben en su presupuesto (regla de medir) ---
	var by_rar := {}
	for f in Roster.FIGURES:
		var fd: Dictionary = f
		if bool(fd.get("custom", false)):
			continue
		var rar := String(fd.get("rarity", FigureCard.RARITY.get(String(fd.get("id", "")), "common")))
		var fig: Dictionary = fd.duplicate(true)
		fig["rarity"] = rar
		var c := PiecePoints.cost(fig)
		var b := PiecePoints.budget(fig)
		by_rar[rar] = maxi(int(by_rar.get(rar, 0)), c)
		ok = _expect("%s cabe (%d/%d)" % [String(fd.get("name", "?")), c, b], c <= b, true) and ok

	# --- presupuestos ordenados: común < rara < épica < legendaria < mítica ---
	var bud := PiecePoints.RARITY_BUDGET
	ok = _expect("orden de presupuestos", int(bud["common"]) < int(bud["rare"])
		and int(bud["rare"]) < int(bud["epic"]) and int(bud["epic"]) < int(bud["legend"])
		and int(bud["legend"]) < int(bud["mythic"]), true) and ok

	# --- FUENTES suben el presupuesto ---
	var base := {"rarity": "epic", "class": "", "stamina": 2, "type": "Ruleta", "attack": []}
	var b0 := PiecePoints.budget(base)
	ok = _expect("épica base = 175", b0, 175) and ok
	var b_bal := PiecePoints.budget({"rarity": "epic", "class": "Balanced"})
	ok = _expect("clase Balanced suma +20", b_bal, b0 + 20) and ok
	var b_evo := PiecePoints.budget({"rarity": "epic", "is_evolution": true})
	ok = _expect("evolución ×1.30", b_evo, int(round(b0 * 1.30))) and ok

	# --- COSTOS: reglas por color/estrellas/estamina ---
	var c_white := PiecePoints.cost({"rarity": "common", "stamina": 0, "type": "Ruleta",
		"attack": [{"col": "white", "pow": 60, "w": 100}]})
	# (0 + 60×0.35) × (100/50) = 21 × 2 = 42
	ok = _expect("blanco 60 @100% = 42", c_white, 42) and ok
	var c_stam := PiecePoints.cost({"rarity": "common", "stamina": 4, "type": "Ruleta", "attack": []})
	ok = _expect("estamina 4 = 28", c_stam, 28) and ok
	var c_pas := PiecePoints.cost({"rarity": "common", "stamina": 0, "type": "Ruleta",
		"attack": [], "passives": ["lunge", "bloodthirst"]})
	ok = _expect("pasivas lunge+bloodthirst = 27", c_pas, 12 + 15) and ok

	# --- fits() como candado ---
	var over := {"rarity": "common", "class": "", "stamina": 6, "type": "Suma 2d6",
		"attack": [{"col": "purple", "stars": 3, "fx": "Miedo", "w": 70}, {"col": "gold", "pow": 100, "w": 30}],
		"passives": ["venom_aura", "phase", "warcry"]}
	ok = _expect("build monstruosa NO cabe en común", PiecePoints.fits(over), false) and ok
	ok = _expect("… pero SÍ cabe en mítica", PiecePoints.fits(_with(over, "rarity", "mythic")), true) and ok

	# --- innato del modelo: gratis y no cuenta la pasiva ya incluida ---
	Roster.FIGURES.append({"id": "pp_innate", "name": "Innata", "stamina": 2, "type": "Ruleta",
		"innate": {"pc": 40, "passives": ["bedrock"], "resists": ["fear"]},
		"attack": [{"col": "white", "pow": 40, "w": 100}]})
	var innate_fig := {"rarity": "common", "model_ref": "pp_innate", "stamina": 2, "type": "Ruleta",
		"attack": [{"col": "white", "pow": 40, "w": 100}], "passives": ["bedrock"], "resists": ["fear"]}
	ok = _expect("modelo innato suma +40 al presupuesto", PiecePoints.budget(innate_fig), 100 + 40) and ok
	# la pasiva/resistencia innata NO se cobra
	var same := innate_fig.duplicate(true)
	same["passives"] = []
	same["resists"] = []
	ok = _expect("pasiva/resistencia innata es GRATIS", PiecePoints.cost(innate_fig), PiecePoints.cost(same)) and ok

	print("PIECEPOINTS_OK" if ok else "PIECEPOINTS_FAIL")
	quit()

func _with(d: Dictionary, k: String, v) -> Dictionary:
	var out := d.duplicate(true)
	out[k] = v
	return out

func _expect(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print(("  %-40s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
