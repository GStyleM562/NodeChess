extends SceneTree
## Cold-start retry: con un servidor wss:// que NO responde (simula Render dormido/apagado)
## el cliente debe REINTENTAR con espera durante toda la ventana, y solo al agotarla
## emitir error. Con ws:// local se mantienen los 3 reintentos rapidos.

var status_msgs: Array[String] = []
var err := ""
var lerr := ""   # miembro, no local: las lambdas capturan locales POR COPIA

func _initialize() -> void:
	_run()

func _run() -> void:
	var ok := true

	# --- remoto (wss://) inalcanzable: reintentos pacientes hasta agotar la ventana ---
	var c := NetClient.new()
	get_root().add_child(c)
	c.wake_window = 5.0
	c.retry_delay = 0.4
	c.ws_timeout = 1.0
	c.wake_timeout = 1.0   # el GET a un puerto cerrado se queda colgado; que caiga rapido
	c.connecting_status.connect(func(t: String): status_msgs.append(t))
	c.error_msg.connect(func(t: String): err = t)
	var t0 := Time.get_ticks_msec()
	c.connect_to("wss://127.0.0.1:9")   # puerto cerrado: nunca va a responder

	# A los 3s (dentro de la ventana) NO debe haber error todavia, y ya debio reintentar.
	await create_timer(3.0).timeout
	ok = _expect("sin error dentro de la ventana", err, "") and ok
	ok = _expect("ya reintento (>=1)", _count_retries() >= 1, true) and ok

	# Al agotar la ventana: error emitido, y aguanto al menos wake_window segundos.
	ok = await _wait(func(): return err != "", 10.0) and ok
	var took := float(Time.get_ticks_msec() - t0) / 1000.0
	ok = _expect("error tras agotar ventana", err.contains("Sin conexión"), true) and ok
	ok = _expect("aguanto toda la ventana (>=4.5s)", took >= 4.5, true) and ok
	ok = _expect("reintento varias veces (>=2)", _count_retries() >= 2, true) and ok
	c.queue_free()

	# --- local (ws://) inalcanzable: 3 reintentos rapidos y error (sin espera larga) ---
	var l := NetClient.new()
	get_root().add_child(l)
	l.ws_timeout = 0.5   # a un puerto cerrado el WS puede quedarse "conectando"
	l.error_msg.connect(func(t: String): lerr = t)
	var t1 := Time.get_ticks_msec()
	l.connect_to("ws://127.0.0.1:9")
	var got_err := await _wait(func(): return lerr != "", 8.0)
	var took_l := float(Time.get_ticks_msec() - t1) / 1000.0
	ok = _expect("local: error rapido", got_err, true) and ok
	ok = _expect("local: en <5s", took_l < 5.0, true) and ok
	l.queue_free()

	print("NET_RETRY_OK" if ok else "NET_RETRY_FAIL")
	quit()

func _count_retries() -> int:
	var n := 0
	for m in status_msgs:
		if m.contains("reintento"):
			n += 1
	return n

func _wait(cond: Callable, timeout: float) -> bool:
	var elapsed := 0.0
	while not cond.call() and elapsed < timeout:
		await create_timer(0.05).timeout
		elapsed += 0.05
	return cond.call()

func _expect(label: String, got, want) -> bool:
	var pass_: bool = got == want
	print(("  %-36s got=%s want=%s  %s") % [label, str(got), str(want), ("OK" if pass_ else "<<< FAIL")])
	return pass_
