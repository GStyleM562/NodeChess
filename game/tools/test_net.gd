extends SceneTree
## End-to-end networking: two NetClients against a LOCAL relay (ws://127.0.0.1:8080).
## Requires the server running: `node nodechess_server/server.js`.

var a: NetClient
var b: NetClient
var code := ""
var b_start := {}
var b_action := {}

func _initialize() -> void:
	a = NetClient.new()
	b = NetClient.new()
	get_root().add_child(a)
	get_root().add_child(b)
	a.room_created.connect(func(c, _you, _pl): code = c)
	b.match_start.connect(func(seed, map, decks): b_start = {"seed": seed, "map": map, "decks": decks})
	b.remote_action.connect(func(act): b_action = act)
	a.connect_to("ws://127.0.0.1:8080")
	b.connect_to("ws://127.0.0.1:8080")
	_run()

func _run() -> void:
	var ok := true
	ok = await _wait(func(): return a.is_open() and b.is_open(), 6.0) and ok
	ok = _expect("both connected", a.is_open() and b.is_open(), true) and ok

	# formato nuevo de mazo: {"team": jugables, "lib": cierre} — opaco para el relay
	a.create_room("Host", {"team": [{"id": "stone_golem"}], "lib": [{"id": "emberborn"}]}, 1)
	ok = await _wait(func(): return code != "", 3.0) and ok
	ok = _expect("room code (4)", code.length() == 4, true) and ok

	b.join_room(code, "Guest", {"team": [{"id": "nightblade"}], "lib": []})
	await create_timer(0.4).timeout
	a.start_match()
	ok = await _wait(func(): return not b_start.is_empty(), 3.0) and ok
	ok = _expect("B received start", not b_start.is_empty(), true) and ok
	var decks: Array = b_start.get("decks", [])
	ok = _expect("start carries 2 decks", decks.size(), 2) and ok
	var d0 = decks[0].get("deck", {}) if decks.size() > 0 else {}
	ok = _expect("deck viaja como dict con team", d0 is Dictionary and (d0.get("team", []) as Array).size() == 1, true) and ok
	ok = _expect("lib viaja intacta", (d0.get("lib", []) as Array).size(), 1) and ok

	a.send_action({"kind": "move", "uid": 3, "to": 8})
	ok = await _wait(func(): return not b_action.is_empty(), 3.0) and ok
	ok = _expect("B received action", String(b_action.get("kind", "")), "move") and ok

	print("NET_OK" if ok else "NET_FAIL")
	quit()

func _wait(cond: Callable, timeout: float) -> bool:
	var elapsed := 0.0
	while not cond.call() and elapsed < timeout:
		await create_timer(0.05).timeout
		elapsed += 0.05
	return cond.call()

func _expect(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print(("  %-24s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
