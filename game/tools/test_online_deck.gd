extends SceneTree
## REPRO del bug "partida online SIN BANCA": flujo real de OnlineLobby con mazos
## REALES (Loadout + Roster completos, incl. customs) a través del relay local.
## Requiere `node nodechess_server/server.js` corriendo.

var a: NetClient
var b: NetClient
var code := ""
var a_start := {}
var b_start := {}

## Copia EXACTA de OnlineLobby._my_deck() (el que viaja al relay).
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
	return {"team": team, "lib": lib}

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

	# --- CASO 1: mazo por defecto (integradas) ---
	var deck_a := _my_deck()
	ok = _expect("host: mazo de 6 integradas", (deck_a["team"] as Array).size(), 6) and ok
	a.create_room("Host", deck_a, 0)
	ok = await _wait(func(): return code != "", 3.0) and ok

	# --- el invitado juega un mazo de 6 CUSTOMS (como el teléfono real) ---
	for i in 6:
		Roster.FIGURES.append({"id": "cust_%d" % i, "name": "Ultimate Ninja", "stamina": 3,
			"type": "Ruleta", "custom": true, "rarity": "legend",
			"model_ref": "nightblade", "glb": "res://assets/figures/nightblade/nightblade.glb",
			"size": 0.95, "clips": {"idle": "Idle_10"},
			"passives": ["lunge"], "resists": ["fear"],
			"attack": [{"col": "white", "name": "X", "pow": 100, "w": 80}, {"col": "red", "w": 20}]})
	var base := Roster.FIGURES.size() - 6
	Loadout.player_team = [base, base + 1, base + 2, base + 3, base + 4, base + 5]
	var deck_b := _my_deck()
	ok = _expect("guest: mazo de 6 customs", (deck_b["team"] as Array).size(), 6) and ok
	b.join_room(code, "Guest", deck_b)
	await create_timer(0.4).timeout
	a.start_match()
	ok = await _wait(func(): return not a_start.is_empty() and not b_start.is_empty(), 4.0) and ok

	# --- lo que RECIBE cada lado: ambos equipos deben sobrevivir el viaje ---
	var ns := get_root().get_node("NetSession")
	for side in [["host", a_start], ["guest", b_start]]:
		var st: Dictionary = side[1]
		var by_seat := {0: [], 1: []}
		for d in st.get("decks", []):
			by_seat[int(d.get("seat", 0))] = d.get("deck", [])
		var t0: Array = ns.team_of(by_seat[0])
		var t1: Array = ns.team_of(by_seat[1])
		ok = _expect("%s recibe equipo host de 6" % side[0], t0.size(), 6) and ok
		ok = _expect("%s recibe equipo guest de 6" % side[0], t1.size(), 6) and ok
		if t1.size() == 6:
			ok = _expect("%s: custom conserva ataques" % side[0],
				(t1[0].get("attack", []) as Array).size() > 0, true) and ok

	# --- y la banca del tablero se construye (como Board3D online) ---
	if not b_start.is_empty():
		var by2 := {0: [], 1: []}
		for d in b_start.get("decks", []):
			by2[int(d.get("seat", 0))] = d.get("deck", [])
		var mine: Array = ns.team_of(by2[1])           # guest es seat 1
		var theirs: Array = ns.team_of(by2[0])
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
