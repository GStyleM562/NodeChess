extends SceneTree
## MATCHMAKING: dos clientes que buscan rival deben emparejar y recibir "start"
## con los DOS mazos (auto-inicio). Requiere el server local v25.
var a: NetClient
var b: NetClient
var a_start := {}
var b_start := {}
var a_matched := false
var b_matched := false
func _deck() -> Dictionary:
	var team := []
	for ri in [0,1,2,3,4,6]:
		team.append(CustomFigures.wire_pack(Roster.FIGURES[ri]))
	return {"team": team, "lib": []}
func _initialize() -> void:
	a = NetClient.new(); b = NetClient.new()
	get_root().add_child(a); get_root().add_child(b)
	a.matched.connect(func(c,y,p): a_matched = true)
	b.matched.connect(func(c,y,p): b_matched = true)
	a.match_start.connect(func(s,m,d): a_start = {"decks": d})
	b.match_start.connect(func(s,m,d): b_start = {"decks": d})
	a.searching.connect(func(): print("A en cola"))
	a.connect_to("ws://127.0.0.1:8080")
	b.connect_to("ws://127.0.0.1:8080")
	_run()
func _run() -> void:
	var ok := true
	ok = await _wait(func(): return a.is_open() and b.is_open(), 6.0) and ok
	a.find_match("Ana", _deck(), 0)
	await create_timer(0.4).timeout   # A queda en cola
	b.find_match("Beto", _deck(), 0)  # B empareja con A
	ok = await _wait(func(): return a_matched and b_matched, 4.0) and ok
	ok = _expect("ambos emparejados", a_matched and b_matched, true) and ok
	ok = await _wait(func(): return not a_start.is_empty() and not b_start.is_empty(), 4.0) and ok
	ok = _expect("ambos reciben start", not a_start.is_empty() and not b_start.is_empty(), true) and ok
	var d0: Array = a_start.get("decks", [])
	ok = _expect("start trae 2 mazos", d0.size(), 2) and ok
	# rehidratar como el tablero
	var ns := get_root().get_node("NetSession")
	ns.build_match(a_start["decks"], 0, 1, 0)
	ok = _expect("mazos rehidratados 6/6", ns.team_p0.size() == 6 and ns.team_p1.size() == 6, true) and ok
	print("MATCHMAKING_OK" if ok else "MATCHMAKING_FAIL")
	quit()
func _wait(cond: Callable, t: float) -> bool:
	var e := 0.0
	while e < t:
		if cond.call(): return true
		await create_timer(0.1).timeout; e += 0.1
	return cond.call()
func _expect(label: String, got, want) -> bool:
	var p: bool = got == want
	print(("  %-32s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if p else "<<< FAIL")])
	return p
