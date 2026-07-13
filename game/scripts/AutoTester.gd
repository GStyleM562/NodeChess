extends Node
class_name AutoTester
## 🤖 MODO ROBOT (Capa 2-3 de docs/PLAN_Testing.md): tour automático DENTRO de
## la app que hace cosas de verdad (compra, craftea, crea figura, arma mazos,
## juega partidas CPU vs CPU con el tablero renderizando) y LOGGUEA cada paso
## [PASS]/[FAIL] a user://autotest/. SIEMPRE respalda y restaura los datos
## reales del jugador (pase o falle). Se lanza desde Configuración (admin).

static var cpu_vs_cpu := false   # Board3D: el lado del jugador también juega solo
static var running := false
static var auto_quit := false    # modo CI/headless: imprime el reporte y cierra

const FILES := ["user://inventory.json", "user://loadout.json", "user://custom_figures.json"]
const MATCH_TIMEOUT_MS := 180000
const ROBOT_SPEED := 16.0
## Tope de medio-turnos: dos bots difíciles pueden estancarse a la defensiva;
## llegar aquí sin errores cuenta como EMPATE TÉCNICO (hallazgo, no crash).
const MATCH_TURN_CAP := 250

var _burn := false
var _matches := 3
var _log: Array = []
var _pass := 0
var _fail := 0
var _bk := {}
var _fps_min := 9999.0
var _fps_sum := 0.0
var _fps_n := 0
var _mem0 := 0
var _banner: Label

static func start(tree: SceneTree, burn := false) -> void:
	if running:
		return
	running = true
	var t: AutoTester = AutoTester.new()
	t.name = "AutoTesterRun"
	t._burn = burn
	t._matches = 10 if burn else 3
	tree.root.add_child(t)
	t.run.call_deferred()

func run() -> void:
	_build_banner()
	_mem0 = int(Performance.get_monitor(Performance.MEMORY_STATIC))
	_line("🤖 MODO ROBOT — %s · %s" % [Time.get_datetime_string_from_system(), ("BURN-IN 10 partidas" if _burn else "tour estándar")])
	_backup()
	var inv := get_tree().root.get_node("Inventory")
	# fallo garrafal en cualquier fase: NUNCA saltarse la restauración
	_reset_account(inv)
	_phase_economy(inv)
	_phase_creator(inv)
	_phase_decks()
	_phase_chests(inv)
	await _phase_matches(inv)
	_restore()
	_report()

# ------------------------------------------------------------ infraestructura
func _line(t: String) -> void:
	_log.append(t)

func _chk(name: String, got, want) -> void:
	var okv: bool = got == want
	if okv:
		_pass += 1
	else:
		_fail += 1
	_log.append(("[PASS] " if okv else "[FAIL] ") + name + ("" if okv else "   (got=%s want=%s)" % [str(got), str(want)]))
	_set_status(("✔ " if okv else "✘ ") + name)

func _set_status(t: String) -> void:
	if _banner != null and is_instance_valid(_banner):
		_banner.text = "🤖 " + t

func _build_banner() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 60
	add_child(cl)
	var p := PanelContainer.new()
	p.set_anchors_preset(Control.PRESET_TOP_WIDE)
	p.offset_left = 8
	p.offset_right = -8
	p.offset_top = 4
	p.add_theme_stylebox_override("panel", UITheme.panel(Color(0.1, 0.05, 0.12, 0.95), UITheme.ORANGE, 10, 1, 6))
	_banner = Label.new()
	_banner.text = "🤖 Prueba automática en curso…"
	_banner.clip_text = true
	UITheme.label(_banner, 12, UITheme.ORANGE, true, 700)
	p.add_child(_banner)
	cl.add_child(p)

func _backup() -> void:
	for pth in FILES:
		_bk[pth] = FileAccess.get_file_as_string(pth) if FileAccess.file_exists(pth) else null
	_line("· respaldo de %d archivos del jugador" % FILES.size())

## Restaura los archivos reales y RECARGA el estado vivo (pase o falle).
func _restore() -> void:
	for pth in FILES:
		if _bk.get(pth) != null:
			var f := FileAccess.open(pth, FileAccess.WRITE)
			if f != null:
				f.store_string(String(_bk[pth]))
				f.close()
		elif FileAccess.file_exists(pth):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(pth))
	var inv := get_tree().root.get_node("Inventory")
	inv._loaded = false
	inv._ensure_loaded()
	# roster: fuera las customs de prueba, re-fusionar las reales restauradas
	var keep: Array = []
	for f in Roster.FIGURES:
		if not bool(f.get("custom", false)):
			keep.append(f)
	Roster.FIGURES = keep
	CustomFigures.merge_into_roster()
	Loadout.decks = []
	Loadout.active_deck = 0
	Loadout.player_team = [0, 1, 2, 3, 4, 6]
	Loadout.enemy_team = [1, 0, 2, 4, 3, 6]
	Loadout.player_modifiers = ["power_surge", "cleanse", "adrenaline"]
	Loadout.map_index = 0
	Loadout.load()
	cpu_vs_cpu = false
	Engine.time_scale = 1.0
	_line("· datos del jugador RESTAURADOS")

## Cuenta de PRUEBA limpia (modo usuario + kit inicial), sin tocar el respaldo.
func _reset_account(inv: Node) -> void:
	inv._loaded = true
	inv.mode = "user"
	inv.pieces = {}
	inv.fragments = {}
	inv.chest_inv = []
	inv.next_chest = {}
	inv.tx_log = []
	inv.coins = 0
	inv.gems = 0
	inv.xp = 0
	inv.level = 1
	inv.level_chests = 0
	inv.wins = 0
	inv.losses = 0
	inv.streak = 0
	inv.best_streak = 0
	inv._starter = false
	inv.set_mode("user")   # re-otorga el kit inicial
	_chk("cuenta de prueba con kit inicial", inv.has_piece("color:white"), true)

# ------------------------------------------------------------ fases lógicas
func _phase_economy(inv: Node) -> void:
	_line("— FASE 1 · ECONOMÍA —")
	var p: Dictionary = inv.price_of("color:white")
	_chk("precio canónico blanco 200🪙", int(p.get("price", 0)) == 200 and String(p.get("currency", "")) == "coins", true)
	inv.adjust_funds(2000, 200)
	_chk("fondos acreditados", inv.coins == 2000 and inv.gems == 200, true)
	var w0: int = int(inv.pieces.get("color:white", 0))
	var br: Dictionary = inv.buy("color:white")
	_chk("compra 🪙 entrega y cobra", bool(br.get("ok", false)) and int(inv.pieces.get("color:white", 0)) == w0 + 1 and inv.coins == 1800, true)
	_chk("recibo con saldo real", int(br.get("coins", -1)), 1800)
	var bg: Dictionary = inv.buy("passive:lunge")   # épica → 💎30
	_chk("compra 💎 entrega y cobra", bool(bg.get("ok", false)) and inv.gems == 170, true)
	_chk("pieza inexistente rechazada", bool(inv.buy("model:hackx").get("ok", false)), false)
	inv.add_frags("stamina:3", 10)
	var cv: Dictionary = inv.convert("stamina:3")
	_chk("crafteo 10→1 entrega", bool(cv.get("ok", false)) and inv.has_piece("stamina:3") and inv.frags("stamina:3") == 0, true)
	_chk("crafteo sin frags rechazado", bool(inv.convert("stamina:3").get("ok", false)), false)
	var fr: Dictionary = inv.open_free()
	_chk("caja gratis da fragmentos", (fr.get("frags", {}) as Dictionary).size() > 0, true)
	_chk("🧾 log registró la sesión", inv.tx_log.size() >= 5, true)

func _phase_creator(inv: Node) -> void:
	_line("— FASE 2 · CREADOR —")
	var fig: Dictionary = CharacterCreator.make_figure({
		"name": "Robot QA", "desc": "figura de prueba automática",
		"class": "Balanced", "rarity": "epic", "stamina": 2, "type": "Ruleta",
		"passives": [], "resists": [], "model_ref": "ironclad_knight",
		"evolve": false, "stages": [],
		"pool": [
			{"col": "white", "name": "Golpe", "pow": 60, "stars": 1, "fx_index": 0, "w": 50},
			{"col": "blue", "name": "Guardia", "pow": 0, "stars": 1, "fx_index": 0, "w": 30},
			{"col": "red", "name": "", "pow": 0, "stars": 1, "fx_index": 0, "w": 20},
		]})
	var v: Dictionary = FigureValidator.validate(fig)
	_chk("figura de prueba válida", String(v["state"]) != "INVALID", true)
	_chk("kit inicial la permite (0 faltantes)", (inv.missing_pieces(fig) as Array).size(), 0)
	var before := {}
	for key in inv.required_pieces(fig):
		before[key] = int(inv.pieces.get(key, 0))
	inv.consume_for(fig)
	var consumed_ok := true
	for key in before.keys():
		if int(inv.pieces.get(key, 0)) != int(before[key]) - 1:
			consumed_ok = false
	_chk("crear CONSUME exactamente 1 de cada pieza", consumed_ok, true)
	CustomFigures.add(fig)
	CustomFigures.apply_live(fig)
	_chk("figura guardada y en el roster", CustomFigures.exists(String(fig["id"])), true)
	# edición: blanco→oro cobra el delta y reembolsa
	var fig2: Dictionary = fig.duplicate(true)
	fig2["attack"] = [{"col": "gold", "pow": 60, "w": 50}, {"col": "blue", "w": 30}, {"col": "red", "w": 20}]
	inv.buy("color:gold")   # asegurar la pieza nueva (💎 sobran del presupuesto)
	var g0: int = int(inv.pieces.get("color:gold", 0))
	var w0: int = int(inv.pieces.get("color:white", 0))
	inv.adjust_for_edit(fig, fig2)
	_chk("editar cobra el delta (oro −1)", int(inv.pieces.get("color:gold", 0)), g0 - 1)
	_chk("editar reembolsa (blanco +1)", int(inv.pieces.get("color:white", 0)), w0 + 1)
	CustomFigures.remove(String(fig["id"]))   # limpieza (el archivo se restaura igual)

func _phase_decks() -> void:
	_line("— FASE 3 · MAZOS —")
	Loadout.decks = []
	Loadout.active_deck = 0
	Loadout.player_team = [0, 1, 2, 3, 4, 6]
	Loadout.stash_active()
	var base_team: Array = (Loadout.decks[0] as Dictionary).get("team", [])
	Loadout.decks.append({"name": "Robot", "team": base_team.duplicate(), "mods": [], "map": 1})
	Loadout.switch_deck(1)
	_chk("mazo nuevo EN USO", Loadout.active_deck == 1 and Loadout.active_name() == "Robot", true)
	_chk("mazo en uso listo (6/6)", Loadout.active_ready(), true)
	var code := Loadout.deck_code()
	var imp: Dictionary = Loadout.import_deck_code(code)
	_chk("código NCDECK exporta/importa", bool(imp.get("ok", false)) and Loadout.decks.size() == 3, true)
	Loadout.switch_deck(2)
	Loadout.decks.remove_at(Loadout.active_deck)
	Loadout.switch_deck(0, false)
	_chk("borrar mazo NO pisa el Mazo 1", ((Loadout.decks[0] as Dictionary).get("team", []) as Array).size(), 6)

func _phase_chests(inv: Node) -> void:
	_line("— FASE 4 · COFRES —")
	inv.chest_inv = []
	var tier := String(inv.grant_won_chest())
	_chk("victoria otorga cofre", tier != "" and inv.chest_inv.size() == 1, true)
	_chk("descifrar arranca", inv.start_unlock(0), true)
	_chk("sin terminar NO entrega", (inv.open_won_chest(0) as Dictionary).is_empty(), true)
	(inv.chest_inv[0] as Dictionary)["ready_at"] = 0   # acelerar el reloj (modo prueba)
	var wr: Dictionary = inv.open_won_chest(0)
	_chk("cofre listo entrega piezas", (wr.get("pieces", []) as Array).size() >= 2, true)
	while inv.chest_inv.size() < inv.CHEST_SLOTS:
		inv.grant_won_chest()
	_chk("ranuras llenas: no entrega otro", String(inv.grant_won_chest()), "")
	inv.level_chests = 1
	var lr: Dictionary = inv.open_level_chest()
	_chk("cofre de nivel da 3 piezas", (lr.get("pieces", []) as Array).size(), 3)

# ------------------------------------------------------------ fase partidas
func _phase_matches(inv: Node) -> void:
	_line("— FASE 5 · %d PARTIDAS CPU vs CPU (tablero real) —" % _matches)
	cpu_vs_cpu = true
	for m in _matches:
		Loadout.tutorial = false
		Loadout.lesson = ""
		TutorialLib.active_guide = ""
		Loadout.map_index = m % MapData.count()
		Loadout.player_team = [0, 1, 2, 3, 4, 6]
		Loadout.enemy_team = [1, 0, 2, 4, 3, 6]
		var games0: int = int(inv.wins) + int(inv.losses)
		get_tree().change_scene_to_file("res://scenes/board.tscn")
		for i in 8:
			await get_tree().process_frame
		var t0 := Time.get_ticks_msec()
		var consistent := true
		var ended := false
		var stalled := false
		var winner := ""
		var turns := 0
		while Time.get_ticks_msec() - t0 < MATCH_TIMEOUT_MS:
			Engine.time_scale = ROBOT_SPEED
			await get_tree().create_timer(0.4).timeout
			var sc := get_tree().current_scene
			if sc == null or not is_instance_valid(sc):
				continue
			var gs = sc.get("_gs")
			if gs == null:
				continue
			# métricas (saltando los primeros segundos: carga de GLBs)
			if Time.get_ticks_msec() - t0 > 4000:
				var fps := Performance.get_monitor(Performance.TIME_FPS)
				_fps_min = minf(_fps_min, fps)
				_fps_sum += fps
				_fps_n += 1
			if not bool(gs.board_consistent()):
				consistent = false
			winner = String(gs.winner)
			turns = int(gs.turn_no)
			if winner != "":
				ended = true
				break
			if turns >= MATCH_TURN_CAP:
				stalled = true   # empate técnico: bots defensivos, sin errores
				break
		Engine.time_scale = 1.0
		_chk("partida %d (%s) concluye sin colgarse" % [m + 1, MapData.display_name(Loadout.map_index)], ended or stalled, true)
		_chk("partida %d consistente todo el tiempo" % (m + 1), consistent, true)
		if stalled:
			_line("· EMPATE TÉCNICO en %d medio-turnos (bots defensivos — hallazgo de balance, no error)" % turns)
		if ended:
			_line("· ganador=%s · medio-turnos=%d" % [winner, turns])
			await get_tree().create_timer(0.8).timeout   # deja correr add_match_xp
			_chk("partida %d acredita resultado (XP/stats)" % (m + 1), int(inv.wins) + int(inv.losses), games0 + 1)
	cpu_vs_cpu = false

# ------------------------------------------------------------ reporte
func _report() -> void:
	var mem1 := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	_line("— MÉTRICAS —")
	if _fps_n > 0:
		_line("fps: mín %.0f · prom %.0f" % [_fps_min, _fps_sum / _fps_n])
	_line("memoria: %.1f MB → %.1f MB" % [_mem0 / 1048576.0, mem1 / 1048576.0])
	_line("— RESULTADO: %d PASS · %d FAIL —" % [_pass, _fail])
	# archivo
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://autotest"))
	var fname := "user://autotest/reporte_%s.txt" % Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var f := FileAccess.open(fname, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(_log))
		f.close()
		_line("· guardado en " + fname)
	if auto_quit:
		for l in _log:
			print(l)
		print("ROBOT_OK" if _fail == 0 else "ROBOT_FAIL")
		running = false
		get_tree().quit(0 if _fail == 0 else 1)
		return
	_show_results()

func _show_results() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 70
	add_child(cl)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	cl.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.add_child(cc)
	var ok_all := _fail == 0
	var accent: Color = UITheme.SUCCESS if ok_all else UITheme.DANGER
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(minf(440.0, get_viewport().get_visible_rect().size.x - 24.0), 0)
	panel.add_theme_stylebox_override("panel", UITheme.panel(Color(0.07, 0.09, 0.17, 0.99), accent, 20, 2, 16))
	cc.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	var t := Label.new()
	t.text = "🤖 Reporte de la prueba automática"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(t, 17, accent, true, 800)
	v.add_child(t)
	var sum := Label.new()
	sum.text = ("✅ TODO EN VERDE — %d verificaciones" % _pass) if ok_all else ("✔ %d PASS   ·   ✘ %d FAIL" % [_pass, _fail])
	sum.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(sum, 14, UITheme.TEXT, true, 700)
	v.add_child(sum)
	if _fps_n > 0:
		var mtr := Label.new()
		mtr.text = "fps mín %.0f · prom %.0f" % [_fps_min, _fps_sum / _fps_n]
		mtr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UITheme.label(mtr, 12, UITheme.TEXT2, false, 600)
		v.add_child(mtr)
	if not ok_all:
		var scr := ScrollContainer.new()
		scr.custom_minimum_size = Vector2(0, 180)
		scr.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		v.add_child(scr)
		var lst := VBoxContainer.new()
		lst.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scr.add_child(lst)
		for l in _log:
			if String(l).begins_with("[FAIL]"):
				var fl := Label.new()
				fl.text = String(l)
				fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				UITheme.label(fl, 11, UITheme.DANGER, false, 600)
				lst.add_child(fl)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	v.add_child(hb)
	var cp := Button.new()
	cp.text = "⧉ Copiar reporte"
	cp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cp.custom_minimum_size = Vector2(0, 46)
	UITheme.button_font(cp, 13, UITheme.GOLD, true, 700)
	UITheme.style_surface(cp)
	cp.pressed.connect(func():
		DisplayServer.clipboard_set("\n".join(_log))
		cp.text = "✓ Copiado")
	hb.add_child(cp)
	var cls := Button.new()
	cls.text = "Cerrar"
	cls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cls.custom_minimum_size = Vector2(0, 46)
	UITheme.button_font(cls, 13, Color.WHITE, true, 800)
	UITheme.style_primary(cls, UITheme.PRIMARY, 12)
	cls.pressed.connect(func():
		running = false
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		queue_free())
	hb.add_child(cls)
