extends SceneTree
## Verify the DEPLOYED Render server end-to-end (two clients over the internet).
## Patient timeouts for the free-tier cold start (~50s).

const URL := "wss://nodechess-server.onrender.com"
var a: NetClient
var b: NetClient
var code := ""
var b_start := {}

func _initialize() -> void:
	a = NetClient.new()
	b = NetClient.new()
	get_root().add_child(a)
	get_root().add_child(b)
	a.room_created.connect(func(c, _y, _p): code = c)
	b.match_start.connect(func(s, m, d): b_start = {"seed": s, "decks": d})
	a.connecting_status.connect(func(t): print("  [status] ", t))
	a.connect_to(URL)
	_run()

func _run() -> void:
	var ok := true
	ok = await _wait(func(): return a.is_open(), 100.0) and ok
	print("  A connected = %s" % a.is_open())
	if a.is_open():
		b.connect_to(URL)
		ok = await _wait(func(): return b.is_open(), 60.0) and ok
		a.create_room("Host", [{"id": "stone_golem"}], 0)
		ok = await _wait(func(): return code != "", 8.0) and ok
		print("  room code = %s" % code)
		b.join_room(code, "Guest", [{"id": "nightblade"}])
		await create_timer(0.6).timeout
		a.start_match()
		ok = await _wait(func(): return not b_start.is_empty(), 8.0) and ok
	ok = ok and a.is_open() and b.is_open() and code.length() == 4 and not b_start.is_empty()
	print("NET_LIVE_OK" if ok else "NET_LIVE_FAIL")
	quit()

func _wait(cond: Callable, timeout: float) -> bool:
	var t := 0.0
	while not cond.call() and t < timeout:
		await create_timer(0.2).timeout
		t += 0.2
	return cond.call()
