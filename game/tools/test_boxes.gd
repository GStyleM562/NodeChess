extends SceneTree
## CAJAS POR TIPO: cada tipo saca piezas SOLO de su pool (figuras/ataque/pasivas),
## la Variada de cualquiera; la rareza (tier) controla la cantidad; los cofres
## ganados llevan tipo y open_won_chest lo respeta. Compat: cofre viejo = Variada.

func _initialize() -> void:
	var ok := true
	var inv = get_root().get_node("Inventory")
	inv.mode = "user"   # piezas reales (no admin infinito)

	# --- pools por tipo: prefijos correctos ---
	var pf: Array = inv.box_pool("figures")
	ok = _expect("pool figuras: todo model:", _all_prefixed(pf, ["model:"]), true) and ok
	var pa: Array = inv.box_pool("attack")
	ok = _expect("pool ataque: solo categorías de ataque",
		_all_prefixed(pa, ["color:", "pow:", "stars:", "prob:", "atype:", "fx:"]), true) and ok
	var pp: Array = inv.box_pool("passive")
	ok = _expect("pool pasivas: passive:/resist:", _all_prefixed(pp, ["passive:", "resist:"]), true) and ok
	var pr: Array = inv.box_pool("random")
	ok = _expect("pool variada = catálogo completo", pr.size(), inv.catalog().size()) and ok

	# --- open_box: el tipo solo da piezas de su pool; tier controla la cantidad ---
	for t in 3:
		var r: Dictionary = inv.open_box("figures", t)
		ok = _expect("figuras tier %d: %d piezas" % [t, [2,3,4][t]], (r["pieces"] as Array).size(), [2,3,4][t]) and ok
		ok = _expect("figuras tier %d: todas son model:" % t, _all_prefixed(r["pieces"], ["model:"]), true) and ok
	var ra: Dictionary = inv.open_box("attack", 2)
	ok = _expect("ataque: solo piezas de ataque", _all_prefixed(ra["pieces"],
		["color:", "pow:", "stars:", "prob:", "atype:", "fx:"]), true) and ok
	var rp: Dictionary = inv.open_box("passive", 1)
	ok = _expect("pasivas: solo passive:/resist:", _all_prefixed(rp["pieces"], ["passive:", "resist:"]), true) and ok

	# --- las piezas se ACREDITAN de verdad ---
	inv.pieces = {}
	var before: int = 0
	var rr: Dictionary = inv.open_box("figures", 0)
	for key in rr["pieces"]:
		before += int(inv.pieces.get(key, 0))
	ok = _expect("piezas acreditadas al inventario", before >= 2, true) and ok

	# --- cofres ganados llevan tipo y open_won_chest lo respeta ---
	inv.chest_inv = []
	inv.grant_won_chest("passive")
	var info: Dictionary = inv.chest_info(0)
	ok = _expect("cofre ganado guarda el tipo", String(info.get("type", "")), "passive") and ok
	inv.chest_inv[0]["state"] = "ready"   # forzar listo
	var wr: Dictionary = inv.open_won_chest(0)
	ok = _expect("cofre de pasivas da solo passive:/resist:", _all_prefixed(wr["pieces"], ["passive:", "resist:"]), true) and ok

	# --- COMPAT: un cofre viejo SIN type se trata como Variada, sin crash ---
	inv.chest_inv = [{"tier": "t5", "state": "ready", "ready_at": 0}]
	var old: Dictionary = inv.open_won_chest(0)
	ok = _expect("cofre viejo (sin type) abre como Variada", not old.is_empty(), true) and ok

	# --- ANUNCIOS: dan recurso y respetan el tope diario ---
	inv.ads = {"day": "", "used": {}}
	inv.coins = 0
	var a1: Dictionary = inv.watch_ad("coins")
	ok = _expect("anuncio de monedas: ok", bool(a1.get("ok", false)), true) and ok
	ok = _expect("anuncio de monedas: acredita 🪙", inv.coins > 0, true) and ok
	ok = _expect("usos restantes bajaron", inv.ad_left("coins"), int((inv.AD_TYPES["coins"] as Dictionary)["daily"]) - 1) and ok
	var box_ad: Dictionary = inv.watch_ad("box")
	ok = _expect("anuncio de caja: entrega piezas", not (box_ad.get("box", {}) as Dictionary).is_empty(), true) and ok
	# agotar el tope de gemas
	var glimit: int = int((inv.AD_TYPES["gems"] as Dictionary)["daily"])
	for i in glimit:
		inv.watch_ad("gems")
	ok = _expect("gemas: sin usos tras el tope", inv.ad_left("gems"), 0) and ok
	var over: Dictionary = inv.watch_ad("gems")
	ok = _expect("anuncio sin usos: rechazado", bool(over.get("ok", true)), false) and ok

	print("BOXES_OK" if ok else "BOXES_FAIL")
	quit()

func _all_prefixed(arr: Array, prefixes: Array) -> bool:
	for key in arr:
		var hit := false
		for p in prefixes:
			if String(key).begins_with(String(p)):
				hit = true
				break
		if not hit:
			return false
	return not arr.is_empty()

func _expect(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print(("  %-44s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
