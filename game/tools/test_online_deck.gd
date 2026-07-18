extends SceneTree
## Mazos ONLINE de punta a punta con el FORMATO DE RED v24: integradas viajan
## como {"nc_ref"} y customs sin runtime; el receptor rehidrata en
## NetSession.build_match. Verifica: tamaños mínimos, rehidratación, ESPEJO
## exacto (mismo roster/orden en ambos lados), banca 6/6 y tolerancia al
## formato LEGADO (dicts completos). Requiere `node nodechess_server/server.js`.

var a: NetClient
var b: NetClient
var code := ""
var a_start := {}
var b_start := {}

## Copia EXACTA de OnlineLobby._my_deck() (formato de red v24).
func _my_deck() -> Dictionary:
	var team: Array = []
	var seen := {}
	for ri in Loadout.player_team:
		if ri >= 0 and ri < Roster.FIGURES.size():
			team.append(Roster.FIGURES[ri])
			seen[String(Roster.FIGURES[ri].get("id", ""))] = true
	var lib: Array = []
	var queue := team.duplicate()
	while not queue.is_empty():
		var f: Dictionary = queue.pop_front()
		for st in f.get("ranks", []):
			var eid := String(st.get("evolves_id", ""))
			if eid != "" and not seen.has(eid):
				seen[eid] = true
				for g in Roster.FIGURES:
					if String(g.get("id", "")) == eid:
						lib.append(g)
						queue.append(g)
						break
	var team_w: Array = []
	for f in team:
		team_w.append(CustomFigures.wire_pack(f))
	var lib_w: Array = []
	for f in lib:
		lib_w.append(CustomFigures.wire_pack(f))
	return {"team": team_w, "lib": lib_w}

func _initialize() -> void:
	a = NetClient.new()
	b = NetClient.new()
	get_root().add_child(a)
	get_root().add_child(b)
	a.room_created.connect(func(c, _y, _p): code = c)
	a.match_start.connect(func(s, m, d): a_start = {"seed": s, "map": m, "decks": d})
	b.match_start.connect(func(s, m, d): b_start = {"seed": s, "map": m, "decks": d})
	a.connect_to("ws://127.0.0.1:8080")
	b.connect_to("ws://127.0.0.1:8080")
	_run()

func _run() -> void:
	var ok := true
	ok = await _wait(func(): return a.is_open() and b.is_open(), 6.0) and ok

	# --- HOST: mazo por defecto (6 integradas) -> puras referencias, tamaño mínimo
	var deck_a := _my_deck()
	ok = _expect("host: mazo de 6", (deck_a["team"] as Array).size(), 6) and ok
	ok = _expect("host: integradas como nc_ref", (deck_a["team"][0] as Dictionary).has("nc_ref"), true) and ok
	var bytes_a := JSON.stringify(deck_a).length()
	ok = _expect("host: payload < 2 KB", bytes_a < 2048, true) and ok
	a.create_room("Host", deck_a, 0)
	ok = await _wait(func(): return code != "", 3.0) and ok

	# --- GUEST: 6 CUSTOMS (una con evolución a integrada) como el teléfono real
	for i in 6:
		var fig := {"id": "cust_%d" % i, "name": "Ultimate Ninja", "stamina": 3,
			"type": "Ruleta", "custom": true, "rarity": "legend", "class": "Agile",
			"model_ref": "nightblade", "glb": "res://assets/figures/nightblade/nightblade.glb",
			"size": 0.95, "clips": {"idle": "Idle_10"}, "placeholder": true,
			"passives": ["lunge"], "resists": ["fear"],
			"attack": [{"col": "white", "name": "X", "pow": 100, "w": 80}, {"col": "red", "w": 20}]}
		if i == 0:
			fig["ranks"] = [{"evolves_id": "stone_golem", "at": 3,
				"glb": "res://assets/figures/stone_golem/stone_golem.glb",
				"clips": {"idle": "Idle_3"}, "size": 1.3}]
		Roster.FIGURES.append(fig)
	var base := Roster.FIGURES.size() - 6
	Loadout.player_team = [base, base + 1, base + 2, base + 3, base + 4, base + 5]
	var deck_b := _my_deck()
	ok = _expect("guest: mazo de 6 customs", (deck_b["team"] as Array).size(), 6) and ok
	var c0: Dictionary = deck_b["team"][0]
	ok = _expect("custom viaja SIN glb", c0.has("glb"), false) and ok
	ok = _expect("custom viaja SIN clips", c0.has("clips"), false) and ok
	ok = _expect("rank viaja SIN glb", (c0["ranks"][0] as Dictionary).has("glb"), false) and ok
	ok = _expect("lib: evolución integrada como ref", (deck_b["lib"][0] as Dictionary).has("nc_ref"), true) and ok
	var bytes_b := JSON.stringify(deck_b).length()
	ok = _expect("guest: payload < 4 KB", bytes_b < 4096, true) and ok
	print("  (payload host=%d bytes, guest=%d bytes)" % [bytes_a, bytes_b])
	b.join_room(code, "Guest", deck_b)
	await create_timer(0.4).timeout
	a.start_match()
	ok = await _wait(func(): return not a_start.is_empty() and not b_start.is_empty(), 4.0) and ok

	# --- REHIDRATAR con el build_match REAL en ambos lados y comparar espejo
	var ns := get_root().get_node("NetSession")
	var ids_host: Array = []
	var ids_guest: Array = []
	for side in [["host", a_start, 0, ids_host], ["guest", b_start, 1, ids_guest]]:
		var st: Dictionary = side[1]
		ns.build_match(st["decks"], int(side[2]), int(st["seed"]), int(st["map"]))
		ok = _expect("%s: team0 rehidratado 6" % side[0], ns.team_p0.size(), 6) and ok
		ok = _expect("%s: team1 rehidratado 6" % side[0], ns.team_p1.size(), 6) and ok
		for f in ns.match_roster:
			(side[3] as Array).append(String(f.get("id", "")))
		var t1: Array = ns.team_of(ns.decks_by_seat[1])
		if t1.size() == 6:
			ok = _expect("%s: custom conserva ataques" % side[0],
				((t1[0] as Dictionary).get("attack", []) as Array).size() > 0, true) and ok
			ok = _expect("%s: custom RECUPERA modelo" % side[0],
				String((t1[0] as Dictionary).get("glb", "")) != "", true) and ok
	ok = _expect("ESPEJO: mismo roster en ambos lados", ids_host == ids_guest and ids_host.size() > 0, true) and ok

	# --- banca del tablero (como Board3D._setup_online_state, lado guest)
	var mine: Array = ns.team_of(ns.decks_by_seat[1])
	var theirs: Array = ns.team_of(ns.decks_by_seat[0])
	var roster: Array = []
	for f in mine: roster.append(f)
	for f in theirs: roster.append(f)
	var saved := Roster.FIGURES
	Roster.FIGURES = roster
	var gs := GameState.new(MapData.new(0))
	for i in mine.size():
		gs.add_to_bench("player", i)
	for i in theirs.size():
		gs.add_to_bench("enemy", mine.size() + i)
	ok = _expect("banca del guest: 6 figuras", (gs.bench["player"] as Array).size(), 6) and ok
	ok = _expect("banca rival: 6 figuras", (gs.bench["enemy"] as Array).size(), 6) and ok
	Roster.FIGURES = saved

	# --- LEGADO: un mazo con dicts COMPLETOS (cliente viejo) sigue rehidratando
	var legacy_team: Array = []
	for ri in [0, 1, 2, 3, 4, 6]:
		legacy_team.append(Roster.FIGURES[ri])
	var legacy := [{"seat": 0, "name": "Old", "deck": {"team": legacy_team, "lib": []}},
		{"seat": 1, "name": "Old2", "deck": {"team": legacy_team, "lib": []}}]
	ns.build_match(legacy, 0, 1, 0)
	ok = _expect("legado: dicts completos rehidratan 6/6",
		ns.team_p0.size() == 6 and ns.team_p1.size() == 6, true) and ok

	ns.online = false
	a.leave_room()
	b.leave_room()
	print("ONLINE_DECK_OK" if ok else "ONLINE_DECK_FAIL")
	quit()

func _wait(cond: Callable, secs: float) -> bool:
	var t := 0.0
	while t < secs:
		if cond.call():
			return true
		await create_timer(0.1).timeout
		t += 0.1
	return cond.call()

func _expect(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print(("  %-36s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
