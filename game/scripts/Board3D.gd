extends Node3D
## Layer 1 playable board (revised). Figures start in a bench and DEPLOY from an
## entrance (deploy costs 1 stamina; the figure may keep moving with what's left).
## One figure activates per turn: move (by remaining stamina) then the player
## DECIDES to attack an adjacent enemy or press "Terminar turno". Attack -> wheel
## (CombatOverlay) -> a close-up "combat shot" of the winner beating the loser ->
## back to the board -> resolve KO. Enemy = simple bot.
## Deferred: surround KO, KO-bench return, rank-up, energy/modifiers, real bot.

const ROLE_COLOR := {
	"normal": Color(0.086, 0.114, 0.2),        # #161D33
	"entrance_player": Color(0.212, 0.82, 0.498),  # #36D17F
	"entrance_enemy": Color(1.0, 0.322, 0.278),    # #FF5247
	"goal_player": Color(0.212, 0.82, 0.498),
	"goal_enemy": Color(1.0, 0.322, 0.278),
	"buff": Color(1.0, 0.773, 0.239),          # #FFC53D
	"obstacle": Color(0.055, 0.065, 0.1),
	"teleporter": Color(0.722, 0.451, 1.0),    # #B873FF
}
const HILITE_MOVE := Color(0.353, 0.627, 1.0)  # #5AA0FF
const HILITE_ATK := Color(1.0, 0.322, 0.278)
const HILITE_DEPLOY := Color(0.212, 0.82, 0.498)
const HILITE_JUMP := Color(1.0, 0.78, 0.25)    # dorado: aterrizaje de SALTO
## Loseta Meshy por rol (carpeta en assets/board/). Sin asset -> disco procedural.
## El buff usa SU PROPIO asset como tile de piso (la plataforma ya trae su
## diamante): nada de doble tile con otro cristal flotando encima.
const TILE_SLUG := {
	"normal": "node_tile", "buff": "buff_crystal",
	"goal_player": "goal_player", "goal_enemy": "goal_enemy",
	"entrance_player": "entrance_player", "entrance_enemy": "entrance_enemy",
}
const TILE_TOP := 0.06     # altura de la cara superior de las losetas (pies en y=0)
const FACE_OFFSET := 0.0
const STATUS_ES := {
	"fear": "Miedo", "weakened": "Debilitado", "paralysis": "Paralizado", "immobilized": "Inmovilizado",
	"burn": "Quemadura", "poison": "Veneno", "freeze": "Congelado", "silence": "Silencio",
	"confusion": "Confusión", "sleep": "Sueño", "curse": "Maldición", "marked": "Marcado",
	"shield_break": "Escudo Roto",
}

var _gs: GameState
var _cam: Camera3D
var _combat_cam: Camera3D
var _overlay: CombatOverlay
var _vis := {}                # uid -> Figure3D
var _status_lbls := {}        # uid -> Label3D (status indicator over the figure)
var _name_lbls := {}          # uid -> Label3D (figure name + rank over the figure)
var _node_mi := {}
var _node_mat := {}
var _tiled := {}         # nid -> true si tiene loseta Meshy (disco = overlay transparente)
## Cache COMPARTIDA entre partidas: los GLB del tablero se cargan una sola vez
## por sesión (la primera partida 3D paga la carga; las siguientes entran rápido).
static var _tile_scenes := {}
var _assets_on := true   # Configuración: "3d" = losetas Meshy · "2d" = digital
var _last_turn := ""     # para anunciar "¡ES TU TURNO!" solo cuando cambia
var _lock_vis := {}      # nid -> visual de candado (nodo cerrado los 1ros turnos)
var _buff_lbls := {}     # buff node id -> Label3D con el progreso de carga
var _trap_pending := false   # eligiendo nodo para el modificador Trampa
var _trap_vis := {}      # nid -> marcador ▲ de MIS trampas (el rival no lo ve)
## Pasos del TUTORIAL guiado: kind action = avanza al hacerlo · info = botón OK.
const TUT_STEPS := [
	{"text": "1/6 · DESPLIEGA: arrastra una carta de tu BANCA (abajo) a una entrada AZUL brillante.", "kind": "deploy"},
	{"text": "2/6 · MUÉVETE: toca tu figura y luego un nodo AZUL. La estamina ⚡ es cuántos nodos avanza.", "kind": "move"},
	{"text": "3/6 · ATACA: párate junto al muñeco rival y toca su nodo ROJO. ¡Gira la ruleta!", "kind": "attack"},
	{"text": "4/6 · SALTOS: los nodos DORADOS saltan POR ENCIMA de un rival (cuestan 2). Los 🔒 se abren en la ronda 3.", "kind": "info"},
	{"text": "5/6 · BUFF: párate 2 turnos en el nodo ⚡ del centro y tu figura quedará POTENCIADA para siempre.", "kind": "info"},
	{"text": "6/6 · ¡GANA!: lleva CUALQUIER figura a la META dorada del rival (arriba).", "kind": "win"},
]
var _tut_step := -1          # -1 = sin tutorial
var _tut_panel: PanelContainer
var _tut_lbl: Label
var _tut_ok: Button

const TURN_LIMIT := 75.0     # online: segundos por turno (al agotarse, pasa solo)
var _turn_left := 0.0
var _timer_lbl: Label
var _skip_btn: Button        # ⏭ saltar la animación de combate
var _net_blocked := false    # reconectando o rival offline: se pausa la partida
var _net_banner: PanelContainer
var _net_banner_lbl: Label
var _ending_by_time := false
var _highlighted := []
var _entrance_owner := {}      # entrance node id -> owning team (for the "blocked" siren)
var _sirening := {}            # entrance nodes currently pulsing red
var _siren_t := 0.0
var _ui_layer: CanvasLayer
var _bench_cards := []         # [{uid, ctrl}] for hit-testing the drag
var _drag_uid := -1
var _drag_active := false
var _drag_start := Vector2.ZERO
var _drag_ghost: Control
# --- online (turn-based 1v1) ---
var _online := false
var _seat := 0
var _half := 5                 # figures per side (for the uid mirror)
var _remote_q: Array = []
var _remote_busy := false
var _wait_banner: PanelContainer
var _saved_roster: Array = []
# Turn / activation state
var _active_uid := -1
var _remaining := 0
var _committed := false
var _deploy_uid := -1
var _reach := {}
var _foe_nodes := {}          # node id -> foe uid
var _busy := false
var _over := false
var _status: Label
var _end_btn: Button
var _bench_box: HBoxContainer
var _energy_label: Label
var _mods_box: HBoxContainer
var _banner: PanelContainer
var _banner_lbl: Label
var _active_card_slot: Control
var _hud_label: Label
var _jumped := false           # active figure hopped an enemy this turn -> no attack

func _ready() -> void:
	# Force PORTRAIT at runtime (reliable on Android regardless of the manifest).
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	randomize()
	_build_environment()
	if NetSession.online:
		_setup_online_state()
	else:
		_gs = GameState.new(MapData.new(0 if Loadout.tutorial else Loadout.map_index))
		# Teams come from the Deck Builder (player) + a preset enemy deck.
		for ri in Loadout.player_team:
			_gs.add_to_bench("player", int(ri))
		# Tutorial: la CPU usa UNA figura pasiva (muñeco de práctica).
		for ri in ([0] if Loadout.tutorial else Loadout.enemy_team):
			_gs.add_to_bench("enemy", int(ri))
	_build_board()
	_overlay = CombatOverlay.new()
	add_child(_overlay)
	_build_ui()
	_refresh_bench_ui()
	_update_status()
	Music.play_battle()
	if _online:
		NetSession.client.remote_action.connect(_on_remote_action)
		NetSession.client.player_left.connect(_on_opp_left)
		NetSession.client.peer_status.connect(_on_peer_status)
		NetSession.client.match_start.connect(_on_rematch_start)
		NetSession.net_paused.connect(_on_net_paused)
		_turn_left = TURN_LIMIT
	elif Loadout.tutorial:
		_gs.bot_difficulty = -1        # bot pasivo de tutorial
		_tut_start()
	else:
		# Dificultad elegida en el Deck Builder + personalidad al azar (variedad).
		_gs.bot_difficulty = Settings.cpu_level
		_gs.bot_personality = ["balanced", "aggressive", "defensive", "rusher", "hunter"].pick_random()
		var pname: String = GameState.PERSONA_ES.get(_gs.bot_personality, "Equilibrada")
		var dname: String = ["Fácil", "Media", "Difícil"][clampi(Settings.cpu_level, 0, 2)]
		_show_banner("CPU: %s · %s" % [dname, pname], UITheme.PRIMARY_EDGE)

## Online: build the local-perspective state (I am always "player" at the bottom, the
## opponent is "enemy" at the top — no board flip). Both clients build the SAME figures,
## just with their own deck first, so uids line up via a fixed mirror.
func _setup_online_state() -> void:
	_online = true
	_seat = NetSession.seat
	# El mazo viaja como {"team": jugables, "lib": cierre de evoluciones}. SOLO el
	# team se convierte en unidades (mismo tamaño en ambos lados -> mirror exacto);
	# las libs van al final del roster únicamente para resolver modelos/rank-ups.
	var mine_raw = NetSession.decks_by_seat.get(_seat, {})
	var theirs_raw = NetSession.decks_by_seat.get(1 - _seat, {})
	var my_team: Array = NetSession.team_of(mine_raw)
	var their_team: Array = NetSession.team_of(theirs_raw)
	_half = my_team.size()
	# Swap the roster to [my team, their team, libs]; restored on leaving the match.
	_saved_roster = Roster.FIGURES
	var roster: Array = []
	for f in my_team:
		roster.append(f)
	for f in their_team:
		roster.append(f)
	for f in NetSession.lib_of(mine_raw):
		roster.append(f)
	for f in NetSession.lib_of(theirs_raw):
		roster.append(f)
	Roster.FIGURES = roster
	_gs = GameState.new(MapData.new(NetSession.map))
	for i in my_team.size():
		_gs.add_to_bench("player", i)                 # uids 0.._half-1
	for i in their_team.size():
		_gs.add_to_bench("enemy", _half + i)          # uids _half..
	if _seat == 1:
		_gs.turn_team = "enemy"                        # the host (seat 0) moves first

func _mirror_uid(u: int) -> int:
	return (u + _half) if u < _half else (u - _half)

func _mirror_node(n: int) -> int:
	return _gs.map.mirror_node(n)

func _net_send(action: Dictionary) -> void:
	if _online:
		NetSession.client.send_action(action)

func _leave_to_menu() -> void:
	Engine.time_scale = 1.0
	Loadout.tutorial = false
	if _online:
		Roster.FIGURES = _saved_roster                 # un-swap the roster
		NetSession.end_online()
	Music.play_menu()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _process(delta: float) -> void:
	# ONLINE: reloj de turno (al agotarse TU turno, se pasa solo). Se divide por
	# time_scale para que la velocidad ×2 del combate NO drene el reloj más rápido.
	if _online and not _over and not _net_blocked:
		_turn_left = maxf(0.0, _turn_left - delta / maxf(0.02, Engine.time_scale))
		if _timer_lbl != null:
			_timer_lbl.text = "⏱ %d s" % int(ceil(_turn_left))
			_timer_lbl.add_theme_color_override("font_color",
				UITheme.DANGER if _turn_left <= 10.0 else UITheme.GOLD)
		if _gs.turn_team == "player" and _turn_left <= 0.0 and not _ending_by_time:
			_ending_by_time = true
			_show_banner("⏰ ¡Tiempo agotado! Turno pasado.", UITheme.DANGER)
			_timeout_turn()
	# A blocked entrance pulses like a siren: a rival figure is sitting on it (so that
	# side can't deploy there). Highlighted nodes are left to the highlight system.
	_siren_t += delta
	var glow := 0.35 + 1.65 * (0.5 + 0.5 * sin(_siren_t * 7.5))
	for nid in _entrance_owner:
		var occ: int = _gs.board.get(nid, -1)
		var blocked: bool = occ != -1 and _gs.units.has(occ) and _gs.units[occ]["alive"] and _gs.units[occ]["team"] != _entrance_owner[nid]
		if blocked and nid not in _highlighted:
			var mat: StandardMaterial3D = _node_mat[nid]
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.16, 0.16)
			mat.albedo_color = Color(0.5, 0.08, 0.08)
			mat.emission_energy_multiplier = glow
			_sirening[nid] = true
		elif _sirening.has(nid):
			_sirening.erase(nid)
			if nid not in _highlighted:
				_set_highlight(nid, Color(0, 0, 0, 0))   # restore the entrance's base look

# ---------------------------------------------------------------- environment
func _build_environment() -> void:
	_cam = Camera3D.new()
	# Lock the HORIZONTAL fov (KEEP_WIDTH) so the board's width is always fully
	# visible on a tall portrait screen (no cut-off edges); height gets extra room.
	_cam.keep_aspect = Camera3D.KEEP_WIDTH
	_cam.fov = 34.0
	# Camera on the player's side: player sits at the BOTTOM, enemy at the top.
	_cam.look_at_from_position(Vector3(0.0, 11.5, -11.0), Vector3.ZERO, Vector3.UP)
	add_child(_cam)
	_combat_cam = Camera3D.new()
	_combat_cam.keep_aspect = Camera3D.KEEP_WIDTH
	_combat_cam.fov = 45.0
	add_child(_combat_cam)
	_cam.current = true
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)
	# Fill light frío desde el lado opuesto: separa las figuras del fondo.
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-38.0, 145.0, 0.0)
	fill.light_color = Color(0.55, 0.68, 1.0)
	fill.light_energy = 0.35
	add_child(fill)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = UITheme.BG_DEEP
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.6, 0.8)
	env.ambient_light_energy = 0.6
	# Glow: lo emisivo (aros, caminos, faros de meta, luces de KO) florece suave.
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.06
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)

# ---------------------------------------------------------------- board build
func _build_board() -> void:
	_assets_on = Settings.board_view == "3d"
	_build_island()
	var seen := {}
	for id in _gs.map.adj:
		for nb in _gs.map.adj[id]:
			var key := mini(id, nb) * 10000 + maxi(id, nb)
			if seen.has(key):
				continue
			seen[key] = true
			# 3D: losas de piedra (cuerpo) · SIEMPRE: línea de energía encima —
			# la línea continua es la que hace LEGIBLE qué camino conecta con qué.
			_make_path(_gs.map.pos_of(id), _gs.map.pos_of(nb))
			_make_line(_gs.map.pos_of(id), _gs.map.pos_of(nb))
	for n in _gs.map.nodes:
		var role := String(n["role"])
		var tiled := _place_tile(role, n["pos"])
		_tiled[int(n["id"])] = tiled
		# El disco sigue siendo LA superficie de resaltado (verde/rojo/azul). Con
		# loseta Meshy debajo queda transparente y solo aparece al resaltar.
		var mi := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.5
		disc.bottom_radius = 0.5
		disc.height = 0.08
		mi.mesh = disc
		mi.position = n["pos"] + Vector3(0, 0.10 if tiled else 0.04, 0)
		var mat := StandardMaterial3D.new()
		var col: Color = ROLE_COLOR.get(role, ROLE_COLOR["normal"])
		if tiled:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color = Color(0, 0, 0, 0)
		else:
			mat.albedo_color = col
			if role != "normal":
				mat.emission_enabled = true
				mat.emission = col
				mat.emission_energy_multiplier = 0.5
		mi.material_override = mat
		add_child(mi)
		_node_mi[n["id"]] = mi
		_node_mat[n["id"]] = mat
		if not tiled:
			_add_node_rim(n)
			_add_node_core(n)
	for g in [_gs.map.goal_player, _gs.map.goal_enemy]:
		if g >= 0:
			_add_goal_beacon(g)
	for b in _gs.map.buffs:
		_add_buff_crystal(b)
		# etiqueta de progreso de CARGA del buff (⚡n/2 · ✔ · ⏳ cooldown)
		var bl := Label3D.new()
		bl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		bl.no_depth_test = true
		bl.font_size = 72
		bl.pixel_size = 0.005
		bl.outline_size = 16
		bl.modulate = Color(1.0, 0.8, 0.3)
		bl.position = _gs.map.pos_of(int(b)) + Vector3(0, 1.4, 0)
		add_child(bl)
		_buff_lbls[int(b)] = bl
	for nid in _gs.map.locked_until.keys():
		_add_lock_vis(int(nid))
	# PORTALES (Túneles): anillo violeta girando sobre cada teleporter.
	for pair in _gs.map.teleporters:
		for pn in pair:
			_add_portal_vis(int(pn))
	for e in _gs.map.entrances_player:
		_entrance_owner[e] = "player"
	for e in _gs.map.entrances_enemy:
		_entrance_owner[e] = "enemy"

# ---------------------------------------------------------------- tutorial
func _tut_start() -> void:
	_tut_panel = PanelContainer.new()
	_tut_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_tut_panel.offset_left = 12
	_tut_panel.offset_right = -12
	_tut_panel.offset_top = 96
	_tut_panel.offset_bottom = 178
	_tut_panel.add_theme_stylebox_override("panel", UITheme.panel(Color(0.05, 0.1, 0.08, 0.97), UITheme.SUCCESS, 14, 2, 10))
	_ui_layer.add_child(_tut_panel)
	var vb := VBoxContainer.new()
	_tut_panel.add_child(vb)
	_tut_lbl = Label.new()
	_tut_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.label(_tut_lbl, 14, UITheme.TEXT, true, 700)
	vb.add_child(_tut_lbl)
	_tut_ok = Button.new()
	_tut_ok.text = "Entendido ✓"
	_tut_ok.custom_minimum_size = Vector2(0, 34)
	UITheme.button_font(_tut_ok, 13, UITheme.TEXT, true, 700)
	UITheme.style_primary(_tut_ok, UITheme.SUCCESS, 10)
	_tut_ok.pressed.connect(func(): _tut_advance())
	vb.add_child(_tut_ok)
	_tut_step = 0
	_tut_show()

func _tut_show() -> void:
	if _tut_step < 0 or _tut_step >= TUT_STEPS.size() or _tut_panel == null:
		return
	var st: Dictionary = TUT_STEPS[_tut_step]
	_tut_lbl.text = String(st["text"])
	_tut_ok.visible = String(st["kind"]) == "info"

## Avanza el tutorial cuando el jugador HIZO la acción del paso actual.
func _tut_action(kind: String) -> void:
	if _tut_step < 0 or _tut_step >= TUT_STEPS.size():
		return
	if String(TUT_STEPS[_tut_step]["kind"]) == kind:
		_tut_advance()

func _tut_advance() -> void:
	_tut_step += 1
	if _tut_step >= TUT_STEPS.size():
		if _tut_panel != null:
			_tut_panel.visible = false
		return
	_tut_show()
	Sfx.play("ui_click")

## PORTAL: halo violeta que gira + chispa orbitando (los dos extremos del túnel).
func _add_portal_vis(nid: int) -> void:
	var p := _gs.map.pos_of(nid)
	var ring := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.5
	t.outer_radius = 0.62
	ring.mesh = t
	ring.position = p + Vector3(0, 0.16, 0)
	ring.scale = Vector3(1, 0.5, 1)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.72, 0.45, 1.0, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.72, 0.45, 1.0)
	mat.emission_energy_multiplier = 1.3
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = mat
	add_child(ring)
	var tw := create_tween().set_loops()
	tw.tween_property(ring, "rotation:y", TAU, 3.2).from(0.0)
	var bob := create_tween().set_loops()
	bob.tween_property(ring, "scale", Vector3(1.12, 0.5, 1.12), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(ring, "scale", Vector3(1.0, 0.5, 1.0), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## Candado visible sobre un nodo cerrado los primeros turnos: aro rojo + 🔒.
## Se oculta solo cuando el camino se abre (_refresh_locks en _update_status).
func _add_lock_vis(nid: int) -> void:
	var grp := Node3D.new()
	add_child(grp)
	var p := _gs.map.pos_of(nid)
	var ring := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.42
	t.outer_radius = 0.58
	ring.mesh = t
	ring.position = p + Vector3(0, 0.14, 0)
	ring.scale = Vector3(1, 0.45, 1)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.2, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.25, 0.2)
	mat.emission_energy_multiplier = 1.0
	ring.material_override = mat
	grp.add_child(ring)
	var lbl := Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.text = "🔒"
	lbl.font_size = 96
	lbl.pixel_size = 0.006
	lbl.outline_size = 18
	lbl.position = p + Vector3(0, 0.9, 0)
	grp.add_child(lbl)
	_lock_vis[nid] = grp

func _refresh_locks() -> void:
	for nid in _lock_vis.keys():
		var v = _lock_vis[nid]
		if is_instance_valid(v):
			v.visible = _gs.node_locked(int(nid))
	for bid in _buff_lbls.keys():
		var l: Label3D = _buff_lbls[bid]
		if not is_instance_valid(l):
			continue
		var occ: int = _gs.board.get(int(bid), -1)
		if _gs.turn_no < int(_gs.buff_cd.get(int(bid), 0)):
			l.text = "⏳"
			l.modulate = Color(0.6, 0.6, 0.7)
		elif occ != -1 and bool(_gs.units[occ].get("buffed", false)):
			l.text = ""
		else:
			var n := _gs.buff_progress(int(bid))
			l.text = "⚡%d/%d" % [n, GameState.BUFF_CHARGE_TURNS] if n > 0 else "⚡"
			l.modulate = Color(1.0, 0.8, 0.3)

# ---------------------------------------------------------------- board assets
## Primer GLB dentro de assets/board/<slug>/ (cacheado). null si no hay.
func _board_scene(slug: String) -> PackedScene:
	if _tile_scenes.has(slug):
		return _tile_scenes[slug]
	var ps: PackedScene = null
	var dir := "res://assets/board/%s" % slug
	var d := DirAccess.open(dir)
	if d != null:
		for f in d.get_files():
			var fname := f.trim_suffix(".remap").trim_suffix(".import")
			if fname.ends_with(".glb") or fname.ends_with(".gltf"):
				ps = load(dir + "/" + fname) as PackedScene
				break
	_tile_scenes[slug] = ps
	return ps

## AABB combinado de los meshes de una escena instanciada (en espacio del root).
func _scene_aabb(root: Node3D) -> AABB:
	var bb := AABB()
	var first := true
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var xf: Transform3D = (mi as Node3D).transform
		var p := mi.get_parent()
		while p != null and p != root:
			if p is Node3D:
				xf = (p as Node3D).transform * xf
			p = p.get_parent()
		var t: AABB = xf * (mi as MeshInstance3D).get_aabb()
		bb = t if first else bb.merge(t)
		first = false
	return bb

## Coloca la loseta Meshy del rol bajo el nodo. La cara superior queda en TILE_TOP
## (los pies de las figuras están en y=0, así NUNCA se entierran ni se traban).
func _place_tile(role: String, pos: Vector3) -> bool:
	if not _assets_on:
		return false   # tablero 2D digital: discos procedurales
	var slug := String(TILE_SLUG.get(role, ""))
	if slug == "":
		return false
	var ps := _board_scene(slug)
	if ps == null:
		return false
	var inst := ps.instantiate() as Node3D
	add_child(inst)
	var bb := _scene_aabb(inst)
	if bb.size.length() < 0.001:
		inst.queue_free()
		return false
	# Algunas losetas de Meshy vienen PARADAS (placa vertical): acostarlas.
	if bb.size.y > maxf(bb.size.x, bb.size.z) * 1.25:
		inst.rotation_degrees.x = -90.0
		bb = Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3.ZERO) * bb
	var s := 1.28 / maxf(bb.size.x, bb.size.z)
	inst.scale = Vector3.ONE * s
	var y := TILE_TOP - (bb.position.y + bb.size.y) * s
	if slug == "buff_crystal":
		# plataforma+cristal: se ASIENTA por su BASE (el cristal queda de pie
		# sobre su propio tile — alinear por la cima lo enterraría).
		y = -0.02 - bb.position.y * s
	inst.position = Vector3(
		pos.x - (bb.position.x + bb.size.x * 0.5) * s,
		y,
		pos.z - (bb.position.z + bb.size.z * 0.5) * s)
	return true

## Camino de LOSAS de piedra entre dos nodos (tramos repetidos del asset).
## Cara superior a +0.02: por debajo de los pies, nada que "atore" el paso.
func _make_path(a: Vector3, b: Vector3) -> bool:
	if not _assets_on:
		return false
	var ps := _board_scene("path_stone")
	if ps == null:
		return false
	var dist := a.distance_to(b)
	var clear := dist - 0.55          # las losas LLEGAN al borde de las losetas
	if clear < 0.25:
		return true
	var k := maxi(1, roundi(clear / 0.7))
	var step := clear / float(k)
	var dirn := (b - a).normalized()
	var start := a + dirn * ((dist - clear) * 0.5)
	for i in k:
		var wrap := Node3D.new()
		add_child(wrap)
		var mid := start + dirn * (step * (float(i) + 0.5))
		wrap.look_at_from_position(mid, b, Vector3.UP)   # -Z del wrap corre hacia b
		var inst := ps.instantiate() as Node3D
		wrap.add_child(inst)
		var bb := _scene_aabb(inst)
		inst.rotation.y = PI / 2.0        # el lado LARGO de la losa sigue el camino
		var sl := (step * 0.94) / maxf(bb.size.x, 0.01)
		var sw := 0.46 / maxf(bb.size.z, 0.01)
		inst.scale = Vector3(sl, sw, sw)
		var tb: AABB = Transform3D(inst.basis, Vector3.ZERO) * bb
		inst.position = Vector3(
			-(tb.position.x + tb.size.x * 0.5),
			0.02 - (tb.position.y + tb.size.y),
			-(tb.position.z + tb.size.z * 0.5))
	return true

## Plataforma "isla flotante" bajo el tablero: base clara + sombra profunda.
func _build_island() -> void:
	var ext := 0.0
	for n in _gs.map.nodes:
		var p: Vector3 = n["pos"]
		ext = maxf(ext, Vector2(p.x, p.z).length())
	var top := MeshInstance3D.new()
	var cy := CylinderMesh.new()
	cy.top_radius = ext + 1.5
	cy.bottom_radius = ext + 0.9
	cy.height = 0.34
	top.mesh = cy
	top.position = Vector3(0, -0.19, 0)
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(0.10, 0.115, 0.19)
	mt.roughness = 0.92
	top.material_override = mt
	add_child(top)
	var deep := MeshInstance3D.new()
	var cy2 := CylinderMesh.new()
	cy2.top_radius = ext + 0.9
	cy2.bottom_radius = ext + 0.1
	cy2.height = 0.6
	deep.mesh = cy2
	deep.position = Vector3(0, -0.64, 0)
	var md := StandardMaterial3D.new()
	md.albedo_color = Color(0.05, 0.055, 0.1)
	md.roughness = 1.0
	deep.material_override = md
	add_child(deep)
	if not _assets_on:
		_build_holo_floor(ext + 1.2)

## Piso FUTURISTA del tablero 2D digital: retícula emisiva + anillos + chispas
## flotando alrededor de la isla (solo estética; cero colisiones/lógica).
func _build_holo_floor(ext: float) -> void:
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.2, 0.45, 0.85, 0.16)
	gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gmat.emission_enabled = true
	gmat.emission = Color(0.25, 0.5, 0.95)
	gmat.emission_energy_multiplier = 0.5
	gmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var step := 1.15
	var k := int(ext / step)
	for i in range(-k, k + 1):
		var off := float(i) * step
		var half := sqrt(maxf(0.04, ext * ext - off * off))   # recorta al círculo
		for axis in 2:
			var mi := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(0.025, 0.006, half * 2.0) if axis == 0 else Vector3(half * 2.0, 0.006, 0.025)
			mi.mesh = box
			mi.position = Vector3(off, -0.012, 0) if axis == 0 else Vector3(0, -0.012, off)
			mi.material_override = gmat
			add_child(mi)
	# anillos concéntricos suaves
	for r in [ext * 0.55, ext * 0.92]:
		var ring := MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = r - 0.035
		t.outer_radius = r + 0.035
		ring.mesh = t
		ring.position = Vector3(0, -0.01, 0)
		ring.scale = Vector3(1, 0.25, 1)
		ring.material_override = gmat
		add_child(ring)
	# chispas que flotan alrededor (partículas baratas con tweens)
	for i in 14:
		var sp := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.035
		sm.height = 0.07
		sp.mesh = sm
		var smat := StandardMaterial3D.new()
		var col: Color = [Color(0.35, 0.6, 1.0), Color(1.0, 0.78, 0.3), Color(0.7, 0.5, 1.0)][i % 3]
		smat.albedo_color = col
		smat.emission_enabled = true
		smat.emission = col
		smat.emission_energy_multiplier = 1.6
		smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sp.material_override = smat
		var ang := randf() * TAU
		var rad := ext * (0.75 + randf() * 0.45)
		var base := Vector3(cos(ang) * rad, 0.3 + randf() * 1.6, sin(ang) * rad)
		sp.position = base
		add_child(sp)
		var tw := create_tween().set_loops()
		var dur := 1.6 + randf() * 1.8
		tw.tween_property(sp, "position:y", base.y + 0.5 + randf() * 0.5, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(sp, "position:y", base.y, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## Aro emisivo alrededor de cada nodo (por rol) — decorativo, no participa en los
## resaltados de _set_highlight (esos siguen sobre el disco).
func _add_node_rim(n: Dictionary) -> void:
	var rim := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.52
	t.outer_radius = 0.6
	rim.mesh = t
	rim.position = n["pos"] + Vector3(0, 0.055, 0)
	rim.scale = Vector3(1, 0.35, 1)
	var mat := StandardMaterial3D.new()
	var role := String(n["role"])
	var col: Color = ROLE_COLOR.get(role, ROLE_COLOR["normal"])
	if role == "normal":
		mat.albedo_color = Color(0.2, 0.26, 0.42)
		mat.emission_enabled = true
		mat.emission = Color(0.25, 0.38, 0.7)
		mat.emission_energy_multiplier = 0.35
	elif role == "obstacle":
		mat.albedo_color = Color(0.09, 0.1, 0.15)
	else:
		mat.albedo_color = col.darkened(0.2)
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 1.1
	rim.material_override = mat
	add_child(rim)

## Faro vertical suave sobre cada meta: se ve desde toda la mesa a dónde hay que llegar.
func _add_goal_beacon(id: int) -> void:
	var beam := MeshInstance3D.new()
	var cy := CylinderMesh.new()
	cy.top_radius = 0.3
	cy.bottom_radius = 0.42
	cy.height = 3.4
	beam.mesh = cy
	beam.position = _gs.map.pos_of(id) + Vector3(0, 1.75, 0)
	var col: Color = ROLE_COLOR.get(_gs.map.role_of(id), Color(1, 1, 1))
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(col.r, col.g, col.b, 0.07)
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = false
	beam.material_override = mat
	add_child(beam)

## Marcador del buff node. En 3D con asset NO se agrega nada: la loseta del buff
## ya ES la plataforma con su diamante (asentada en el piso por _place_tile).
## En 2D digital (o sin asset) se usa el prisma flotante procedural.
func _add_buff_crystal(id: int) -> void:
	if _assets_on and _board_scene("buff_crystal") != null:
		return
	var mi := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(0.34, 0.5, 0.34)
	mi.mesh = pm
	mi.position = _gs.map.pos_of(id) + Vector3(0, 2.2, 0)
	var col: Color = ROLE_COLOR.get("buff", Color(1.0, 0.6, 0.2))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col.darkened(0.15)
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 1.4
	mi.material_override = mat
	add_child(mi)
	var tw := create_tween().set_loops()
	tw.tween_property(mi, "rotation:y", TAU, 5.0).from(0.0)
	var bob := create_tween().set_loops()
	bob.tween_property(mi, "position:y", mi.position.y + 0.16, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(mi, "position:y", mi.position.y, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## Línea de energía que CONECTA dos nodos (ambos modos: es la lectura del grafo).
## En 2D digital lleva además una pasarela oscura como cuerpo del camino.
func _make_line(a: Vector3, b: Vector3) -> void:
	var dist := a.distance_to(b)
	var mid := (a + b) * 0.5
	if not _assets_on:
		# cuerpo del camino digital
		var walk := MeshInstance3D.new()
		var wbox := BoxMesh.new()
		wbox.size = Vector3(0.3, 0.03, dist - 0.5)
		walk.mesh = wbox
		var wmat := StandardMaterial3D.new()
		wmat.albedo_color = Color(0.135, 0.155, 0.25)
		wmat.roughness = 0.85
		walk.material_override = wmat
		walk.look_at_from_position(mid + Vector3(0, 0.015, 0), b + Vector3(0, 0.015, 0), Vector3.UP)
		add_child(walk)
	# línea de energía: en 3D corre POR ENCIMA de las losas y toca las losetas,
	# para que se vea sin cortes qué camino es de cuál.
	var w := 0.07 if _assets_on else 0.1
	var yl := 0.068 if _assets_on else 0.045
	var trim := 0.7 if _assets_on else 0.42
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(w, 0.018, dist - trim)
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.55, 0.85)
	mat.emission_enabled = true
	mat.emission = Color(0.35, 0.52, 0.95)
	mat.emission_energy_multiplier = 1.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	mi.look_at_from_position(mid + Vector3(0, yl, 0), b + Vector3(0, yl, 0), Vector3.UP)
	add_child(mi)

## Núcleo emisivo al centro de cada nodo del tablero 2D digital (look "holo").
func _add_node_core(n: Dictionary) -> void:
	var mi := MeshInstance3D.new()
	var d := CylinderMesh.new()
	d.top_radius = 0.16
	d.bottom_radius = 0.16
	d.height = 0.02
	mi.mesh = d
	mi.position = n["pos"] + Vector3(0, 0.095, 0)
	var role := String(n["role"])
	var col: Color = ROLE_COLOR.get(role, ROLE_COLOR["normal"])
	if role == "normal":
		col = Color(0.35, 0.5, 0.9)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 1.3 if role != "normal" else 0.55
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	add_child(mi)

# ---------------------------------------------------------------- figures
## `at_node` >= 0: aparece AHÍ aunque el estado ya esté más adelante (la CPU
## despliega y camina en la misma acción; la vista debe partir de la entrada).
func _spawn_vis(uid: int, at_node := -1) -> void:
	Sfx.play("deploy")
	var u: Dictionary = _gs.units[uid]
	var data: Dictionary = _gs.model_data(uid)   # rank-aware (ranked figures keep their model after KO)
	var fig := Figure3D.new()
	add_child(fig)
	fig.setup(data["glb"], data["clips"], float(data.get("size", 1.0)))
	fig.set_meta("glb", String(data["glb"]))
	fig.position = _gs.map.pos_of(at_node if at_node >= 0 else int(u["node"]))
	_face(fig, Vector3(0, 0, 1.0) if u["team"] == "player" else Vector3(0, 0, -1.0))
	_add_team_ring(fig, u["team"])
	fig.play_clip("idle")
	_summon_fx(fig, u["team"])
	var lbl := Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.pixel_size = 0.004
	lbl.font_size = 64
	lbl.outline_size = 14
	lbl.modulate = Color(1.0, 0.8, 0.3)
	lbl.position = Vector3(0, 2.05, 0)
	lbl.visible = false
	fig.add_child(lbl)
	_status_lbls[uid] = lbl
	# Name tag above each figure (so placeholder/shared models are identifiable, and
	# the "+N" rank shows after a Rank Up).
	var nlbl := Label3D.new()
	nlbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	nlbl.no_depth_test = true
	nlbl.pixel_size = 0.0034
	nlbl.font_size = 52
	nlbl.outline_size = 16
	nlbl.outline_modulate = Color(0, 0, 0, 0.9)
	nlbl.modulate = _team_color(u["team"])
	nlbl.position = Vector3(0, 2.55, 0)
	nlbl.text = _gs.name_for(uid)
	fig.add_child(nlbl)
	_name_lbls[uid] = nlbl
	_vis[uid] = fig

## Invocación: la figura APARECE creciendo, con un destello del color del equipo
## y un anillo de energía que se expande y desvanece sobre su nodo.
func _summon_fx(fig: Node3D, team: String) -> void:
	var col := _team_color(team)
	fig.scale = Vector3.ONE * 0.05
	var grow := create_tween()
	grow.tween_property(fig, "scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var l := OmniLight3D.new()
	l.light_color = col
	l.omni_range = 2.4
	l.light_energy = 0.0
	l.position = fig.position + Vector3(0, 1.0, 0)
	add_child(l)
	var lt := create_tween()
	lt.tween_property(l, "light_energy", 3.5, 0.18)
	lt.tween_property(l, "light_energy", 0.0, 0.75)
	lt.tween_callback(l.queue_free)
	var ring := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.32
	t.outer_radius = 0.4
	ring.mesh = t
	ring.position = fig.position + Vector3(0, 0.12, 0)
	ring.scale = Vector3(0.3, 0.5, 0.3)
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(col.r, col.g, col.b, 0.85)
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 1.6
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = mat
	add_child(ring)
	var rt := create_tween()
	rt.set_parallel(true)
	rt.tween_property(ring, "scale", Vector3(2.6, 0.5, 2.6), 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	rt.tween_property(mat, "albedo_color:a", 0.0, 0.55)
	rt.chain().tween_callback(ring.queue_free)

func _add_team_ring(fig: Figure3D, team: String) -> void:
	var ring := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.55
	disc.bottom_radius = 0.55
	disc.height = 0.03
	ring.mesh = disc
	ring.position = Vector3(0, 0.06, 0)
	var mat := StandardMaterial3D.new()
	var col := Color(0.25, 0.55, 1.0) if team == "player" else Color(1.0, 0.35, 0.3)
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.6
	ring.material_override = mat
	fig.add_child(ring)

func _face(fig: Node3D, dir: Vector3) -> void:
	if dir.length() < 0.001:
		return
	fig.rotation.y = atan2(dir.x, dir.z) + FACE_OFFSET

# ---------------------------------------------------------------- ui
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_ui_layer = layer
	# "Waiting for opponent" banner — online only, toggled in _update_status.
	_wait_banner = PanelContainer.new()
	_wait_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_wait_banner.offset_top = 58
	_wait_banner.offset_left = -180
	_wait_banner.offset_right = 180
	_wait_banner.add_theme_stylebox_override("panel", UITheme.pill(Color(0.12, 0.07, 0.04, 0.96), UITheme.ORANGE, 14))
	_wait_banner.visible = false
	layer.add_child(_wait_banner)
	var wl := Label.new()
	wl.text = "⏳  Esperando movimiento del RIVAL…"
	wl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(wl, 15, UITheme.ORANGE, true, 800)
	_wait_banner.add_child(wl)
	_status = Label.new()
	_status.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_status.offset_left = 56
	_status.offset_top = 12
	_status.offset_right = -56
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(_status, 16, UITheme.TEXT, true, 700)
	layer.add_child(_status)

	var menu_btn := Button.new()
	menu_btn.text = "☰"
	menu_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	menu_btn.offset_left = -52
	menu_btn.offset_top = 8
	menu_btn.offset_right = -10
	menu_btn.offset_bottom = 48
	UITheme.button_font(menu_btn, 20, UITheme.TEXT2, false, 700)
	UITheme.style_surface(menu_btn, UITheme.SURFACE, UITheme.BORDER, 11)
	menu_btn.pressed.connect(_leave_to_menu)
	layer.add_child(menu_btn)

	_end_btn = Button.new()
	_end_btn.text = "Terminar turno"
	_end_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_end_btn.offset_left = -176
	_end_btn.offset_top = -118
	_end_btn.offset_right = -12
	_end_btn.offset_bottom = -74
	UITheme.button_font(_end_btn, 17, UITheme.TEXT, true, 800)
	_end_btn.add_theme_color_override("font_disabled_color", UITheme.MUTED)
	# HABILITADO = "puedes terminar turno": verde con brillo que respira. Deshabilitado
	# (aún te quedan acciones) = apagado, para que el contraste se lea de inmediato.
	var glow := UITheme.panel(UITheme.SUCCESS.darkened(0.55), UITheme.SUCCESS, 14, 2, 8)
	glow.shadow_color = Color(UITheme.SUCCESS, 0.5)
	glow.shadow_offset = Vector2.ZERO
	_end_btn.add_theme_stylebox_override("normal", glow)
	var glow_hot := UITheme.panel(UITheme.SUCCESS.darkened(0.3), UITheme.SUCCESS.lightened(0.3), 14, 2, 8)
	glow_hot.shadow_color = Color(UITheme.SUCCESS, 0.75)
	glow_hot.shadow_offset = Vector2.ZERO
	glow_hot.shadow_size = 16
	for st in ["hover", "pressed", "hover_pressed", "focus"]:
		_end_btn.add_theme_stylebox_override(st, glow_hot)
	_end_btn.add_theme_stylebox_override("disabled",
		UITheme.panel(Color(0.078, 0.102, 0.188), UITheme.BORDER, 14, 1, 8))
	var pulse := create_tween().set_loops()
	pulse.tween_property(glow, "shadow_size", 18, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(glow, "shadow_size", 5, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_end_btn.pressed.connect(_on_end_turn_pressed)
	layer.add_child(_end_btn)

	var bench_panel := PanelContainer.new()
	bench_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bench_panel.offset_top = -64
	bench_panel.offset_bottom = -8
	bench_panel.offset_left = 8
	bench_panel.offset_right = -8
	bench_panel.add_theme_stylebox_override("panel", UITheme.panel(Color(0.07, 0.08, 0.14, 0.95), UITheme.BORDER, 14, 1, 6))
	layer.add_child(bench_panel)
	# La banca ahora es de 6 (+ K.O. con contador): scroll horizontal si no cabe.
	var bench_scroll := ScrollContainer.new()
	bench_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bench_panel.add_child(bench_scroll)
	_bench_box = HBoxContainer.new()
	_bench_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_bench_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bench_scroll.add_child(_bench_box)

	# Energy readout (top-left) + equipped modifier cards (row above End Turn).
	var en_pill := PanelContainer.new()
	en_pill.set_anchors_preset(Control.PRESET_TOP_LEFT)
	en_pill.offset_left = 10
	en_pill.offset_top = 48
	en_pill.add_theme_stylebox_override("panel", UITheme.pill(Color(0.05, 0.08, 0.14, 0.95), UITheme.ENERGY.darkened(0.25), 9))
	layer.add_child(en_pill)
	_energy_label = Label.new()
	UITheme.label(_energy_label, 18, UITheme.ENERGY, true, 800)
	en_pill.add_child(_energy_label)

	var mods_panel := PanelContainer.new()
	mods_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	mods_panel.offset_top = -162
	mods_panel.offset_bottom = -122
	mods_panel.offset_left = 8
	mods_panel.offset_right = -8
	layer.add_child(mods_panel)
	_mods_box = HBoxContainer.new()
	_mods_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_mods_box.add_theme_constant_override("separation", 8)
	mods_panel.add_child(_mods_box)

	# Modifier activation banner ("Ahora pasará tal cosa…").
	_banner = PanelContainer.new()
	_banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_banner.offset_top = 86
	_banner.offset_bottom = 150
	_banner.offset_left = 20
	_banner.offset_right = -20
	_banner.add_theme_stylebox_override("panel", UITheme.panel(Color(0.1, 0.09, 0.05, 0.97), UITheme.GOLD.darkened(0.2), 14, 2, 10))
	_banner.visible = false
	layer.add_child(_banner)
	_banner_lbl = Label.new()
	_banner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.label(_banner_lbl, 18, UITheme.GOLD, true, 700)
	_banner.add_child(_banner_lbl)

	# ⏭ Saltar la animación de combate (visible solo durante el combate).
	_skip_btn = Button.new()
	_skip_btn.text = "⏭ Saltar"
	_skip_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_skip_btn.offset_left = 10
	_skip_btn.offset_top = 54
	_skip_btn.offset_right = 120
	_skip_btn.offset_bottom = 92
	UITheme.button_font(_skip_btn, 14, UITheme.TEXT, true, 700)
	UITheme.style_surface(_skip_btn, UITheme.SURFACE, UITheme.BORDER, 10)
	_skip_btn.visible = false
	_skip_btn.pressed.connect(func(): Engine.time_scale = 12.0)   # fast-forward
	layer.add_child(_skip_btn)

	# Online: reloj de turno (arriba a la derecha, bajo el menú).
	_timer_lbl = Label.new()
	_timer_lbl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_timer_lbl.offset_left = -140
	_timer_lbl.offset_top = 54
	_timer_lbl.offset_right = -10
	_timer_lbl.offset_bottom = 82
	_timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UITheme.label(_timer_lbl, 17, UITheme.GOLD, true, 800)
	_timer_lbl.visible = _online
	layer.add_child(_timer_lbl)

	# Online: banner de pausa de red (reconexión propia o rival offline).
	_net_banner = PanelContainer.new()
	_net_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_net_banner.offset_left = -230
	_net_banner.offset_right = 230
	_net_banner.offset_top = 160
	_net_banner.offset_bottom = 220
	_net_banner.add_theme_stylebox_override("panel", UITheme.panel(Color(0.12, 0.06, 0.05, 0.97), UITheme.DANGER, 14, 2, 10))
	_net_banner.visible = false
	layer.add_child(_net_banner)
	_net_banner_lbl = Label.new()
	_net_banner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_net_banner_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_net_banner_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.label(_net_banner_lbl, 15, UITheme.TEXT, true, 700)
	_net_banner.add_child(_net_banner_lbl)

	# In-match figure counts (top, centered).
	_hud_label = Label.new()
	UITheme.label(_hud_label, 15, UITheme.TEXT2, true, 700)
	_hud_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_hud_label.offset_top = 78
	_hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(_hud_label)

	# Active-figure CARD (bottom-left) — so figures read as cards, not just text.
	_active_card_slot = Control.new()
	_active_card_slot.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_active_card_slot.offset_left = 8
	_active_card_slot.offset_top = -120
	_active_card_slot.offset_right = 250
	_active_card_slot.offset_bottom = -66
	_active_card_slot.visible = false
	layer.add_child(_active_card_slot)

func _refresh_active_card() -> void:
	if _active_card_slot == null:
		return
	for c in _active_card_slot.get_children():
		c.queue_free()
	if _active_uid == -1 or not _gs.units.has(_active_uid) or _over:
		_active_card_slot.visible = false
		return
	_active_card_slot.visible = true
	var card := FigureCard.new()
	_active_card_slot.add_child(card)
	card.setup(_gs.rank_data(_active_uid), 0, _team_color(_gs.units[_active_uid]["team"]), true)
	# Tap this profile to see the figure's full description before acting.
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.tooltip_text = "Toca para ver la descripción"
	var auid := _active_uid
	card.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			_preview_figure(auid))

func _show_banner(text: String, col: Color) -> void:
	if _banner == null:
		return
	_banner_lbl.text = text
	_banner_lbl.modulate = col
	_banner.visible = true
	var t := get_tree().create_timer(2.6)
	t.timeout.connect(func(): if is_instance_valid(_banner): _banner.visible = false)

func _refresh_bench_ui() -> void:
	for c in _bench_box.get_children():
		c.queue_free()
	_bench_cards.clear()
	var bench: Array = _gs.bench["player"]
	var kos: Array = _gs.ko_bench["player"]
	if bench.is_empty() and kos.is_empty():
		var l := Label.new()
		l.text = "Banca vacía"
		l.modulate = Color(0.6, 0.6, 0.7)
		_bench_box.add_child(l)
		return
	var disabled := _committed or _gs.turn_team != "player" or _busy or _over
	for uid in bench:
		var fd: Dictionary = Roster.FIGURES[_gs.units[uid]["rindex"]]
		var card := _make_bench_card(fd, _gs.name_for(uid))   # rank-aware name (keeps "+N" after KO)
		card.modulate = Color(1, 1, 1, 0.45) if disabled else Color(1, 1, 1, 1)
		_bench_box.add_child(card)
		_bench_cards.append({"uid": uid, "ctrl": card})
	# K.O.: cada caída muestra en cuántos TURNOS TUYOS regresa (⏳).
	for uid in kos:
		var fd2: Dictionary = Roster.FIGURES[_gs.units[uid]["rindex"]]
		var kcard := _make_bench_card(fd2, _gs.name_for(uid))
		kcard.modulate = Color(0.42, 0.42, 0.52, 0.9)
		var left := maxi(0, int(_gs.units[uid].get("ko_until", 0)) - _gs.turn_no)
		var tag := Label.new()
		tag.text = "💀 ⏳%d" % ceili(left / 2.0)
		tag.set_anchors_preset(Control.PRESET_FULL_RECT)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UITheme.label(tag, 15, Color(1.0, 0.55, 0.5), true, 800)
		kcard.add_child(tag)
		_bench_box.add_child(kcard)

## A small bench thumbnail (rarity frame + RETRATO 3D + name + stamina). Tap =
## preview, drag = deploy. El retrato se renderiza UNA vez por modelo (cache de
## sesión) en un SubViewport; mientras llega, se ve el monograma de siempre.
func _make_bench_card(fd: Dictionary, display_name: String) -> Control:
	var rar: Color = FigureCard.rarity_color(fd)
	var accent: Color = FigureCard.accent_of(fd)
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(84, 52)
	p.add_theme_stylebox_override("panel", UITheme.panel(UITheme.SURFACE2, rar, 10, 2, 3))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 4)
	p.add_child(hb)
	var port := Panel.new()
	port.custom_minimum_size = Vector2(36, 44)
	var ps := StyleBoxFlat.new()
	ps.bg_color = accent.darkened(0.1)
	ps.set_corner_radius_all(7)
	port.add_theme_stylebox_override("panel", ps)
	var ini := Label.new()
	ini.text = _initials(display_name)
	ini.set_anchors_preset(Control.PRESET_FULL_RECT)
	ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.label(ini, 15, Color(1, 1, 1, 0.95), true, 800)
	port.add_child(ini)
	var face := TextureRect.new()
	face.set_anchors_preset(Control.PRESET_FULL_RECT)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	port.add_child(face)
	_portrait_into(face, fd)
	hb.add_child(port)
	var vb := VBoxContainer.new()
	vb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vb.add_theme_constant_override("separation", 1)
	var nm := Label.new()
	nm.text = display_name
	nm.clip_text = true
	nm.custom_minimum_size = Vector2(34, 0)
	UITheme.label(nm, 10, UITheme.TEXT, true, 700)
	vb.add_child(nm)
	var st := Label.new()
	st.text = "⚡%d" % int(fd.get("stamina", 2))
	UITheme.label(st, 10, UITheme.ENERGY, false, 700)
	vb.add_child(st)
	hb.add_child(vb)
	return p

## Cache de retratos por GLB, compartida entre partidas de la sesión.
static var _portrait_cache := {}

## Pinta el retrato 3D del modelo en `rect` (async: renderiza una vez y cachea).
func _portrait_into(rect: TextureRect, data: Dictionary) -> void:
	var key := String(data.get("glb", ""))
	if key == "":
		return
	if _portrait_cache.has(key):
		rect.texture = _portrait_cache[key]
		return
	_render_portrait(rect, data, key)

func _render_portrait(rect: TextureRect, data: Dictionary, key: String) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(128, 156)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.world_3d = World3D.new()
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var cam := Camera3D.new()
	cam.fov = 28.0
	vp.add_child(cam)
	cam.look_at_from_position(Vector3(0.0, 1.1, 2.7), Vector3(0.0, 0.9, 0.0), Vector3.UP)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40.0, -30.0, 0.0)
	sun.light_energy = 1.2
	vp.add_child(sun)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.75, 0.9)
	env.ambient_light_energy = 0.9
	we.environment = env
	vp.add_child(we)
	var fig := Figure3D.new()
	vp.add_child(fig)
	fig.setup(String(data["glb"]), data.get("clips", {}), float(data.get("size", 1.0)))
	fig.play_clip("idle")
	await get_tree().create_timer(0.25).timeout    # deja que la pose "idle" asiente
	await RenderingServer.frame_post_draw
	if not is_instance_valid(vp):
		return
	var img := vp.get_texture().get_image()
	if img != null and img.get_width() > 0:
		var tex := ImageTexture.create_from_image(img)
		_portrait_cache[key] = tex
		if is_instance_valid(rect):
			rect.texture = tex
	vp.queue_free()

func _initials(nm: String) -> String:
	var s := ""
	for part in nm.split(" ", false):
		if part.length() > 0:
			s += part[0]
		if s.length() >= 2:
			break
	return s.to_upper()

# ---------------------------------------------------------------- bench drag/deploy
func _input(event: InputEvent) -> void:
	if _over or _busy or _net_blocked or _gs.turn_team != "player":
		return
	if _ui_layer != null and _ui_layer.get_node_or_null("FigPreview") != null:
		return                                   # a preview overlay is open
	# Follow / activate (real touch drag and emulated mouse motion).
	if (event is InputEventScreenDrag) or (event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0):
		if _drag_uid != -1:
			if not _drag_active and event.position.distance_to(_drag_start) > 12.0:
				_activate_drag()
			if _drag_active:
				_update_drag(event.position)
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var uid := _bench_uid_at(event.position)
			if uid != -1:
				get_viewport().set_input_as_handled()    # the bench owns this press
				if not _committed:
					_drag_uid = uid
					_drag_start = event.position
					_drag_active = false
		elif _drag_uid != -1:
			if _drag_active:
				_drop_drag(event.position)
			else:
				_preview_figure(_drag_uid)               # a tap = preview
			_end_drag()
			get_viewport().set_input_as_handled()

func _bench_uid_at(pos: Vector2) -> int:
	for c in _bench_cards:
		var ctrl: Control = c["ctrl"]
		if is_instance_valid(ctrl) and ctrl.get_global_rect().has_point(pos):
			return int(c["uid"])
	return -1

func _activate_drag() -> void:
	_drag_active = true
	var fd: Dictionary = Roster.FIGURES[_gs.units[_drag_uid]["rindex"]]
	# Drag the SMALL card (like the bench thumb), just lifted a touch — not a big card.
	var ghost := _make_bench_card(fd, _gs.name_for(_drag_uid))
	ghost.modulate = Color(1, 1, 1, 0.96)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.scale = Vector2(1.15, 1.15)
	ghost.z_index = 100
	_ui_layer.add_child(ghost)
	_drag_ghost = ghost
	for e in _gs.free_entrances("player"):
		_set_highlight(e, HILITE_DEPLOY)
		if e not in _highlighted:
			_highlighted.append(e)
	_status.text = "Arrastra %s a una entrada verde y suelta para desplegar." % String(fd["name"])

func _update_drag(pos: Vector2) -> void:
	if is_instance_valid(_drag_ghost):
		_drag_ghost.position = pos - Vector2(45, 28)

func _drop_drag(pos: Vector2) -> void:
	var nid := _node_under_cursor(pos)
	if nid != -1 and nid in _gs.free_entrances("player"):
		_player_deploy(_drag_uid, nid)
	else:
		_clear_highlights()
		_update_status()

func _end_drag() -> void:
	if is_instance_valid(_drag_ghost):
		_drag_ghost.queue_free()
	_drag_ghost = null
	_drag_uid = -1
	_drag_active = false

## Tap-to-preview: the big card + its attacks, with a Desplegar shortcut.
func _preview_figure(uid: int) -> void:
	if _ui_layer == null:
		return
	# Rank-aware: show the CURRENT stage's name / attacks / type / passives.
	var base: Dictionary = Roster.FIGURES[_gs.units[uid]["rindex"]]
	var rd: Dictionary = _gs.rank_data(uid)
	var fd: Dictionary = base.duplicate(true)
	fd["name"] = _gs.name_for(uid)
	fd["attack"] = rd["attack"]
	fd["type"] = rd["type"]
	fd["stamina"] = rd["stamina"]
	fd["passives"] = rd["passives"]
	var ov := Control.new()
	ov.name = "FigPreview"
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_layer.add_child(ov)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			ov.queue_free())
	ov.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.add_child(cc)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel(UITheme.SURFACE, FigureCard.rarity_color(fd), 18, 2, 14))
	cc.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)
	var card := FigureCard.new()
	vb.add_child(card)
	card.setup(fd, 0, _team_color(String(_gs.units[uid]["team"])), false)
	# Description (custom figures carry one) — a reminder of what it is.
	var desc := String(base.get("desc", ""))
	if desc != "":
		var dl := Label.new()
		dl.text = desc
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.custom_minimum_size = Vector2(300, 0)
		UITheme.label(dl, 12, UITheme.TEXT2, false, 500)
		vb.add_child(dl)
	# Passives (with what they DO) so you remember its capabilities.
	var pl: Array = fd.get("passives", [])
	if not pl.is_empty():
		var ph := Label.new()
		ph.text = "Pasivas"
		UITheme.label(ph, 12, UITheme.GOLD.darkened(0.1), true, 700)
		vb.add_child(ph)
		for pid in pl:
			var info: Dictionary = Roster.PASSIVES.get(pid, {})
			var prow := Label.new()
			prow.text = "• %s — %s" % [String(info.get("name", pid)), String(info.get("desc", ""))]
			prow.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			prow.custom_minimum_size = Vector2(300, 0)
			UITheme.label(prow, 11, UITheme.TEXT2, false, 500)
			vb.add_child(prow)
	var hdr := Label.new()
	hdr.text = "Ataques · %s" % String(fd.get("type", "?"))
	UITheme.label(hdr, 12, UITheme.PRIMARY_EDGE, true, 700)
	vb.add_child(hdr)
	var total := 0.0
	for s in fd["attack"]:
		total += float(s.get("w", 1.0))
	for s in fd["attack"]:
		var row := Label.new()
		var pct := 100.0 * float(s.get("w", 1.0)) / total
		row.text = "• %s — %.0f%%%s" % [Combat.label(s), pct, ("  [" + String(s["fx"]) + "]" if s.has("fx") else "")]
		UITheme.label(row, 12, UITheme.TEXT2, false, 500)
		vb.add_child(row)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	vb.add_child(hb)
	# "Desplegar" SOLO si la figura sigue en la banca (desde el tablero, la
	# descripción es solo lectura — nada de duplicar figuras ya desplegadas).
	if uid in _gs.bench["player"]:
		var dep := Button.new()
		dep.text = "Desplegar"
		dep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dep.disabled = _committed or _busy or _over or _gs.turn_team != "player"
		UITheme.button_font(dep, 15, UITheme.TEXT, true, 800)
		UITheme.style_primary(dep, UITheme.SUCCESS)
		dep.pressed.connect(func():
			ov.queue_free()
			_begin_deploy(uid))
		hb.add_child(dep)
	var cl := Button.new()
	cl.text = "Cerrar"
	UITheme.button_font(cl, 15, UITheme.TEXT, false, 700)
	UITheme.style_surface(cl)
	cl.pressed.connect(func(): ov.queue_free())
	hb.add_child(cl)

func _update_status() -> void:
	if _wait_banner != null:
		_wait_banner.visible = _online and not _over and _gs.turn_team == "enemy"
	if _over:
		_end_btn.visible = false
		return
	# Anuncio de turno: al pasar a "player" (vs CPU u online) se avisa UNA vez.
	if _gs.turn_team != _last_turn:
		_last_turn = _gs.turn_team
		_turn_left = TURN_LIMIT       # el reloj online se rearma con cada turno
		_ending_by_time = false
		if _gs.turn_team == "player":
			_show_banner("✨ ¡ES TU TURNO! ✨", UITheme.SUCCESS)
	_refresh_locks()
	_end_btn.visible = _gs.turn_team == "player"
	# Can't end the turn without acting — unless there is genuinely nothing to do.
	_end_btn.disabled = _busy or _net_blocked or (not _committed and _player_has_actions())
	if _gs.turn_team != "player":
		_status.text = "Turno del enemigo…"
	elif _active_uid != -1:
		var fname: String = _gs.name_for(_active_uid)
		if _jumped:
			_status.text = "%s saltó sobre el enemigo — sin más acciones." % fname
		elif _reach.is_empty():
			_status.text = "%s no puede moverse: %s" % [fname, _why_stuck(_active_uid)]
		else:
			_status.text = "%s — mov restante: %d.  azul=mover · DORADO=salto · rojo=atacar." % [fname, _remaining]
	else:
		_status.text = "Tu turno — toca una figura, o despliega desde la banca."
	_refresh_status_labels()
	_refresh_energy_mods()
	_refresh_active_card()
	if _hud_label != null:
		_hud_label.text = "Tú: %d   ·   Rival: %d" % [_gs.units_on_board("player").size(), _gs.units_on_board("enemy").size()]
	if _drag_uid == -1:
		_refresh_bench_ui()   # mantiene vivos los contadores ⏳ de los K.O.
	_drain_traps()
	_music_threat()

## Música situacional: si TU figura está a ≤3 nodos de la meta rival → "ventaja";
## si una figura RIVAL está a ≤3 de tu meta → "peligro" (manda sobre ventaja).
## Al desaparecer la situación vuelve sola a la música normal de partida.
func _music_threat() -> void:
	if _over:
		Music.update_threat(false, false)
		return
	Music.update_threat(_goal_dist("player") <= 3, _goal_dist("enemy") <= 3)

## Distancia mínima (en nodos) de las figuras del equipo a la meta que atacan.
func _goal_dist(team: String) -> int:
	var target: int = _gs.map.goal_enemy if team == "player" else _gs.map.goal_player
	if target < 0:
		return 99
	var best := 99
	for uid in _gs.units_on_board(team):
		best = mini(best, _gs.map.graph_dist(int(_gs.units[uid]["node"]), target))
	return best

func _refresh_energy_mods() -> void:
	if _energy_label != null:
		_energy_label.text = "⚡ %d/%d" % [int(_gs.energy["player"]), GameState.ENERGY_MAX]
		if _gs.controls_buff("player"):
			_energy_label.text += "  (buff +1)"
	if _mods_box == null:
		return
	for c in _mods_box.get_children():
		c.queue_free()
	var can_play := not _busy and not _over and _gs.turn_team == "player"
	for mid in Loadout.player_modifiers:
		if not GameState.MODIFIERS.has(mid):
			continue
		var m: Dictionary = GameState.MODIFIERS[mid]
		var b := Button.new()
		b.text = "%s  ⚡%d" % [m["name"], int(m["cost"])]
		b.tooltip_text = String(m["desc"])
		b.disabled = not (can_play and _gs.can_use_modifier("player", mid))
		UITheme.button_font(b, 14, UITheme.TEXT, true, 700)
		UITheme.style_surface(b, UITheme.SURFACE, UITheme.ORANGE.darkened(0.1), 11)
		b.pressed.connect(_on_modifier.bind(mid))
		_mods_box.add_child(b)

func _on_modifier(mid: String) -> void:
	if _busy or _over or _gs.turn_team != "player":
		return
	if mid == "trap":
		_begin_trap_targeting()
		return
	if _gs.activate_modifier("player", mid):
		var m: Dictionary = GameState.MODIFIERS[mid]
		_net_send({"kind": "modifier", "mid": mid})
		_show_banner("Usaste %s — %s" % [String(m["name"]), String(m["desc"])], Color(1.0, 0.85, 0.3))
		_refresh_bench_ui()   # revivir devuelve una figura a la banca
		_update_status()

## TRAMPA: elegir un nodo libre (naranja) donde esconderla.
func _begin_trap_targeting() -> void:
	if not _gs.can_use_modifier("player", "trap"):
		_show_banner("No te alcanza la energía para la Trampa.", UITheme.DANGER)
		return
	_reset_activation()
	_trap_pending = true
	for n in _gs.map.nodes:
		var nid := int(n["id"])
		var role := String(n["role"])
		if _gs.board.has(nid) or nid in _gs.map.obstacles or _gs.traps.has(nid) \
				or _gs.node_locked(nid) or role.begins_with("goal"):
			continue
		_set_highlight(nid, Color(1.0, 0.6, 0.15))
		_highlighted.append(nid)
	_status.text = "TRAMPA: toca un nodo naranja para esconderla (el rival no la verá)."

func _place_trap(nid: int) -> void:
	_trap_pending = false
	_clear_highlights()
	if _gs.activate_modifier("player", "trap", nid):
		_net_send({"kind": "modifier", "mid": "trap", "node": nid})
		_add_trap_marker(nid)
		_show_banner("Trampa colocada. Shhh… 🤫", Color(1.0, 0.6, 0.15))
	_update_status()

## Marcador SOLO para ti (el rival no ve tus trampas hasta que las pisa).
func _add_trap_marker(nid: int) -> void:
	var l := Label3D.new()
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.text = "▲"
	l.font_size = 56
	l.pixel_size = 0.005
	l.outline_size = 12
	l.modulate = Color(1.0, 0.6, 0.15, 0.9)
	l.position = _gs.map.pos_of(nid) + Vector3(0, 0.35, 0)
	add_child(l)
	_trap_vis[nid] = l

## Anuncia (y limpia) los disparos de trampa pendientes del motor.
func _drain_traps() -> void:
	while not _gs.trap_events.is_empty():
		var e: Dictionary = _gs.trap_events.pop_front()
		var nid := int(e["node"])
		if _trap_vis.has(nid):
			if is_instance_valid(_trap_vis[nid]):
				_trap_vis[nid].queue_free()
			_trap_vis.erase(nid)
		var uid := int(e["uid"])
		if _vis.has(uid):
			_dramatize_effect(uid, "💥 ¡TRAMPA!")
		_show_banner("💥 ¡Trampa activada: Inmovilizado!", Color(1.0, 0.6, 0.15))
		Sfx.play("attack_effect")
	_refresh_status_labels()

# ---------------------------------------------------------------- input
func _unhandled_input(event: InputEvent) -> void:
	if _net_blocked:
		return   # partida pausada por red: nada de acciones
	if event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if not _busy and not _over and _gs.turn_team == "player":
				_on_board_click(mb.position)
			elif not _over:
				# Turno rival / animando: tocar cualquier figura abre su ficha
				# (solo lectura) — para saber a QUÉ te enfrentas.
				var nid := _node_under_cursor(mb.position)
				var uid: int = _gs.board.get(nid, -1) if nid != -1 else -1
				if uid != -1:
					_preview_figure(uid)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(0.93)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(1.07)
	elif event is InputEventMagnifyGesture:
		# PELLIZCO (Android): acercar/alejar con dos dedos, igual que la rueda.
		_zoom(1.0 / maxf(0.05, (event as InputEventMagnifyGesture).factor))

## Zoom de cámara con LÍMITES (ni pegarse al piso ni perderse en el cielo).
func _zoom(mult: float) -> void:
	var p := _cam.position * mult
	var d := p.length()
	if d < 7.0:
		p = p.normalized() * 7.0
	elif d > 26.0:
		p = p.normalized() * 26.0
	_cam.position = p

func _node_under_cursor(mouse: Vector2) -> int:
	var from := _cam.project_ray_origin(mouse)
	var dir := _cam.project_ray_normal(mouse)
	if absf(dir.y) < 0.00001:
		return -1
	var t := -from.y / dir.y
	if t < 0.0:
		return -1
	var p := from + dir * t
	var best := -1
	var best_d := 0.7
	for n in _gs.map.nodes:
		var d := Vector2(n["pos"].x - p.x, n["pos"].z - p.z).length()
		if d < best_d:
			best_d = d
			best = n["id"]
	return best

func _on_board_click(mouse: Vector2) -> void:
	var nid := _node_under_cursor(mouse)
	if nid == -1:
		return
	if _trap_pending:
		if nid in _highlighted:
			_place_trap(nid)
		else:
			_trap_pending = false
			_clear_highlights()
			_update_status()
		return
	if _deploy_uid != -1:
		if nid in _gs.free_entrances("player"):
			_player_deploy(_deploy_uid, nid)
		else:
			_reset_activation()
			_update_status()
		return
	if _active_uid != -1:
		if _reach.has(nid):
			_player_move(nid)
			return
		if _foe_nodes.has(nid):
			_player_attack(int(_foe_nodes[nid]))
			return
		var uid2: int = _gs.board.get(nid, -1)
		if uid2 != -1 and _gs.units[uid2]["team"] == "player" and not _committed:
			_activate_unit(uid2)
		elif uid2 != -1 and _gs.units[uid2]["team"] != "player":
			_preview_figure(uid2)   # rival NO atacable ahora: ver su ficha
		return
	var uid: int = _gs.board.get(nid, -1)
	if uid == -1:
		return
	if _gs.units[uid]["team"] == "player":
		_activate_unit(uid)
	else:
		_preview_figure(uid)        # ficha del rival (solo lectura)

# ---------------------------------------------------------------- activation
func _begin_deploy(uid: int) -> void:
	if _busy or _over or _gs.turn_team != "player" or _committed:
		return
	if not (uid in _gs.bench["player"]):
		return   # solo la BANCA despliega: una figura en el tablero jamás se re-despliega
	_reset_activation()
	_deploy_uid = uid
	for e in _gs.free_entrances("player"):
		_set_highlight(e, HILITE_DEPLOY)
		_highlighted.append(e)
	_status.text = "Toca una entrada azul iluminada para desplegar a %s." % Roster.FIGURES[_gs.units[uid]["rindex"]]["name"]

func _activate_unit(uid: int) -> void:
	_deploy_uid = -1
	_active_uid = uid
	_remaining = _gs.effective_stamina(uid)
	_jumped = false
	_refresh_active_highlights()
	_update_status()

func _refresh_active_highlights() -> void:
	_clear_highlights()
	_reach = {}
	_foe_nodes = {}
	if _active_uid == -1:
		return
	var node: int = _gs.units[_active_uid]["node"]
	if _remaining > 0:
		_reach = _gs.move_targets(_active_uid, _remaining)   # includes jumps over enemies
		for rid in _reach.keys():
			# Aterrizajes de SALTO en DORADO (la ruta empieza sobre un rival).
			var jp: Array = _gs.move_path(_active_uid, rid)
			var is_j: bool = not jp.is_empty() and _gs.board.has(int(jp[0]))
			_set_highlight(rid, HILITE_JUMP if is_j else HILITE_MOVE)
			_highlighted.append(rid)
	if _gs.can_attack(_active_uid) and not _jumped:   # no attack after a jump
		for foe in _gs.adjacent_enemies(_active_uid):
			var fn: int = _gs.units[foe]["node"]
			_foe_nodes[fn] = foe
			_set_highlight(fn, HILITE_ATK)
			_highlighted.append(fn)

func _reset_activation() -> void:
	_active_uid = -1
	_remaining = 0
	_committed = false
	_jumped = false
	_deploy_uid = -1
	_trap_pending = false
	_reach = {}
	_foe_nodes = {}
	_clear_highlights()

func _clear_highlights() -> void:
	for nid in _highlighted:
		_set_highlight(nid, Color(0, 0, 0, 0))
	_highlighted.clear()

func _set_highlight(nid: int, col: Color) -> void:
	var mat: StandardMaterial3D = _node_mat[nid]
	if col.a > 0.0:
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 0.9
		var c := col.darkened(0.3)
		c.a = 0.85 if _tiled.get(nid, false) else 1.0
		mat.albedo_color = c
	elif _tiled.get(nid, false):
		# Con loseta Meshy el disco solo existe para resaltar: invisible en reposo.
		mat.albedo_color = Color(0, 0, 0, 0)
		mat.emission_enabled = false
	else:
		var role: String = _gs.map.role_of(nid)
		var base: Color = ROLE_COLOR.get(role, ROLE_COLOR["normal"])
		mat.albedo_color = base
		if role == "normal":
			mat.emission_enabled = false
		else:
			mat.emission = base
			mat.emission_energy_multiplier = 0.5

# ---------------------------------------------------------------- player actions
func _player_deploy(uid: int, node: int) -> void:
	_tut_action("deploy")
	_clear_highlights()
	_deploy_uid = -1
	_gs.deploy(uid, node)
	_net_send({"kind": "deploy", "uid": uid, "node": node})
	_spawn_vis(uid)
	_active_uid = uid
	_remaining = maxi(0, _gs.effective_stamina(uid) - 1)  # deploy costs 1
	_committed = true
	_refresh_bench_ui()
	_refresh_active_highlights()
	_update_status()
	await _maybe_auto_end()

func _player_move(node: int) -> void:
	var cost: int = int(_reach[node])
	# Compute the path BEFORE moving (board state is still current). Jump-aware.
	_tut_action("move")
	var path := _gs.move_path(_active_uid, node)
	# Phasing figures walk THROUGH occupants (keep moving/attacking); a non-phasing
	# move onto a path that starts with an occupied node is a JUMP (ends the turn).
	var phasing := _gs.has_passive(_active_uid, "phase") or _gs.has_passive(_active_uid, "aerial")
	var is_jump := not phasing and not path.is_empty() and _gs.board.has(path[0])
	_clear_highlights()
	_busy = true
	_committed = true
	_refresh_bench_ui()
	_update_status()
	if not _gs.move_unit(_active_uid, node):
		_busy = false
		_committed = false
		_refresh_active_highlights()
		_update_status()
		return
	_net_send({"kind": "move", "uid": _active_uid, "to": node})
	# A jump (over ONE enemy) always uses up all stamina and ends this figure's
	# actions — you cannot jump again nor keep moving (no chaining through units).
	if is_jump:
		_remaining = 0
		_jumped = true
		_show_banner("🦘 ¡SALTO sobre el rival!", HILITE_JUMP)
	else:
		_remaining -= cost
	await _walk_path(_active_uid, path)
	_busy = false
	if _check_and_show_winner():
		return
	# NOTE: surround KO is resolved at END of turn (you must STAY to surround) — not mid-move.
	_refresh_active_highlights()
	_update_status()
	await _maybe_auto_end()

## After a committed action, if the active figure has no moves left and no enemy
## to attack, end the turn automatically.
func _maybe_auto_end() -> void:
	if _over or _busy or _gs.turn_team != "player":
		return
	if _committed and _reach.is_empty() and _foe_nodes.is_empty():
		await _end_player_turn()

func _player_has_actions() -> bool:
	if _gs.can_deploy("player"):
		return true
	for uid in _gs.units_on_board("player"):
		if not _gs.reachable_for(uid).is_empty():
			return true
		if _gs.can_attack(uid) and not _gs.adjacent_enemies(uid).is_empty():
			return true
	return false

func _refresh_status_labels() -> void:
	for uid in _status_lbls.keys():
		var lbl = _status_lbls[uid]
		if not is_instance_valid(lbl) or not _vis.has(uid) or not _gs.units.has(uid):
			continue
		var sl := _gs.status_list(uid)
		lbl.text = _status_text(sl)
		lbl.visible = not sl.is_empty()
	# ⚡ = figura potenciada por buff node (permanente hasta caer)
	for uid in _name_lbls.keys():
		var nl = _name_lbls[uid]
		if is_instance_valid(nl) and _gs.units.has(uid):
			var base := _gs.name_for(uid)
			nl.text = ("⚡" + base) if bool(_gs.units[uid].get("buffed", false)) else base

func _status_text(list: Array) -> String:
	var parts := []
	for s in list:
		parts.append(STATUS_ES.get(s, s))
	return " · ".join(parts)

## Why can't the active figure move? (No on-screen status can mean an enemy AURA,
## spent stamina, or being boxed in — explain it so it isn't a mystery.)
func _why_stuck(uid: int) -> String:
	for s in ["paralysis", "immobilized", "freeze", "sleep"]:
		if _gs.has_status(uid, s):
			return STATUS_ES.get(s, s)
	if _remaining <= 0:
		return "ya no le queda estamina este turno"
	if _gs.effective_stamina(uid) < int(_gs.units[uid]["stamina"]):
		return "un aura enemiga adyacente le bajó la estamina"
	if not _gs.adjacent_enemies(uid).is_empty():
		return "rodeado, sin nodos libres — puedes atacar o Terminar turno"
	return "sin nodos libres alrededor — Terminar turno"

## Big dramatic effect word that pops over the affected figure, then fades.
func _dramatize_effect(uid: int, fx_text: String) -> void:
	var f: Figure3D = _vis.get(uid)
	if f == null:
		return
	var l := Label3D.new()
	l.text = "¡" + fx_text + "!"
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.pixel_size = 0.006
	l.font_size = 110
	l.outline_size = 22
	l.modulate = Color(1.0, 0.45, 1.0)
	l.position = Vector3(0, 2.6, 0)
	l.scale = Vector3(0.3, 0.3, 0.3)
	f.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector3(1.5, 1.5, 1.5), 0.25)
	tw.tween_interval(0.7)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)

func _player_attack(foe_uid: int) -> void:
	_tut_action("attack")
	var att := _active_uid
	var moved := maxi(0, int(_gs.units[att]["stamina"]) - _remaining)   # for Lunge / Dive
	_clear_highlights()
	_busy = true
	_committed = true
	_update_status()
	var rec := _gs.attack(att, foe_uid, moved)
	_net_send({"kind": "attack", "att": att, "def": foe_uid, "moved": moved,
		"idx_a": int(rec.get("idx_a", -1)), "idx_b": int(rec.get("idx_b", -1))})
	await _play_combat(att, foe_uid, rec)
	# PASSIVE — Bloodthirst: on an enemy KO, the attacker may move 1 node (no attack).
	if int(rec.get("ko", -1)) == foe_uid and _gs.units[att]["alive"] and _gs.has_passive(att, "bloodthirst"):
		_busy = false
		_remaining = 1
		_jumped = true               # the bonus is a move only — no second attack
		_status.text = "%s — ¡sed de sangre! mueve 1 nodo." % Roster.FIGURES[_gs.units[att]["rindex"]]["name"]
		_refresh_active_highlights()
		await _maybe_auto_end()
		return
	await _end_player_turn()

func _on_end_turn_pressed() -> void:
	if _busy or _over or _gs.turn_team != "player":
		return
	Sfx.play("end_turn")
	await _end_player_turn()

# ---------------------------------------------------------------- flow / bot
func _end_player_turn() -> void:
	_reset_activation()
	_busy = true
	_refresh_bench_ui()
	await _resolve_surround()      # surround KO resolves now that the figure STAYED
	if _check_and_show_winner():
		return
	_gs.end_turn()
	_update_status()
	if _check_and_show_winner():
		return
	if _online:
		_net_send({"kind": "end"})       # opponent's turn now (driven by their client)
		_busy = false
		_refresh_bench_ui()
		_update_status()
		return
	await _bot_loop()
	_busy = false
	_refresh_bench_ui()
	_update_status()

# ---------------------------------------------------------------- online remote
func _on_remote_action(action: Dictionary) -> void:
	_remote_q.append(action)
	_drain_remote()

func _drain_remote() -> void:
	if _remote_busy:
		return
	_remote_busy = true
	while not _remote_q.is_empty() and not _over:
		var a: Dictionary = _remote_q.pop_front()
		await _apply_remote(a)
	_remote_busy = false

## Apply + animate the opponent's action on MY board (their figures are my "enemy";
## coords are mirrored so I still see myself at the bottom — no board flip).
func _apply_remote(a: Dictionary) -> void:
	match String(a.get("kind", "")):
		"deploy":
			var uid := _mirror_uid(int(a["uid"]))
			_gs.deploy(uid, _mirror_node(int(a["node"])))
			_spawn_vis(uid)
			await get_tree().create_timer(0.3).timeout
		"move":
			var uid := _mirror_uid(int(a["uid"]))
			var tnode := _mirror_node(int(a["to"]))
			var path := _gs.move_path(uid, tnode)
			# Si el estado rechaza el movimiento (nodo ocupado por desync), NO se
			# anima: la vista jamás diverge del estado.
			if _gs.move_unit(uid, tnode):
				await _walk_path(uid, path)
		"modifier":
			var mnode := _mirror_node(int(a["node"])) if a.has("node") else -1
			_gs.activate_modifier("enemy", String(a["mid"]), mnode)
			var m: Dictionary = GameState.MODIFIERS.get(String(a["mid"]), {})
			if not m.is_empty():
				_show_banner("El rival usó %s — %s" % [String(m.get("name", "")), String(m.get("desc", ""))], Color(1.0, 0.55, 0.4))
				await get_tree().create_timer(1.2).timeout
		"attack":
			var att := _mirror_uid(int(a["att"]))
			var def := _mirror_uid(int(a["def"]))
			var rec := _gs.attack(att, def, int(a.get("moved", 0)), int(a.get("idx_a", -1)), int(a.get("idx_b", -1)))
			await _play_combat(att, def, rec)
		"end":
			await _resolve_surround()        # opponent may have surrounded my figures
			_gs.end_turn()                   # -> my turn
	_update_status()
	_check_and_show_winner()

func _on_opp_left(_id: int) -> void:
	if _over:
		return
	_show_banner("El rival salió de la partida — ganas por abandono.", UITheme.SUCCESS)
	_gs.winner = "player"
	_check_and_show_winner()

## Al agotarse el reloj: espera a que termine cualquier animación y pasa el turno.
func _timeout_turn() -> void:
	_reset_activation()
	while _busy and not _over:
		await get_tree().create_timer(0.2).timeout
	if _over or _gs.turn_team != "player":
		return
	await _end_player_turn()

## Pausa de red: yo reconectando (NetSession) — se bloquea todo hasta volver.
func _on_net_paused(paused: bool) -> void:
	_net_blocked = paused
	_net_banner.visible = paused
	if paused:
		_net_banner_lbl.text = "📡 Conexión perdida — reconectando…"
	else:
		_show_banner("📡 ¡Reconectado!", UITheme.SUCCESS)

## El RIVAL se cayó: pausa (sus acciones se perderían) hasta que regrese.
func _on_peer_status(_seat: int, online_now: bool) -> void:
	_net_blocked = not online_now
	_net_banner.visible = not online_now
	if not online_now:
		_net_banner_lbl.text = "📡 El rival se desconectó — esperando su regreso (90 s)…"
	else:
		_show_banner("📡 El rival volvió. ¡Seguimos!", UITheme.SUCCESS)

## REVANCHA aceptada por ambos: el server manda otro start (misma sala/mazos).
func _on_rematch_start(s: int, m: int, decks: Array) -> void:
	if not _online or not _over:
		return
	NetSession.build_match(decks, NetSession.seat, s, m)
	Loadout.map_index = m
	Roster.FIGURES = _saved_roster                 # des-swap antes de reconstruir
	get_tree().change_scene_to_file("res://scenes/board.tscn")

func _bot_loop() -> void:
	while _gs.winner == "" and _gs.turn_team == "enemy":
		var rec := _gs.bot_action("enemy")
		await _animate_bot(rec)
		if _check_and_show_winner():
			return
		_gs.end_turn()
		if _check_and_show_winner():
			return

func _animate_bot(rec: Dictionary) -> void:
	match String(rec.get("type", "pass")):
		"deploy":
			_spawn_vis(int(rec["uid"]), int(rec["node"]))   # aparece en la ENTRADA
			await get_tree().create_timer(0.3).timeout
			# La CPU puede CAMINAR tras desplegar (estamina restante), como tú.
			if rec.has("move_to"):
				await _walk_path(int(rec["uid"]), rec.get("path", [int(rec["move_to"])]))
			await _resolve_surround()
		"move":
			await _walk_path(int(rec["uid"]), rec.get("path", [int(rec["node"])]))
			await _resolve_surround()
		"attack":
			var bmid := String(rec.get("modifier", ""))
			if bmid != "" and GameState.MODIFIERS.has(bmid):
				var m: Dictionary = GameState.MODIFIERS[bmid]
				_show_banner("El rival usó %s — %s" % [String(m["name"]), String(m["desc"])], Color(1.0, 0.55, 0.4))
				await get_tree().create_timer(1.5).timeout
			await _play_combat(int(rec["att"]), int(rec["def"]), rec)
		_:
			await get_tree().create_timer(0.2).timeout

func _walk_vis(uid: int, target: Vector3) -> void:
	var fig: Figure3D = _vis[uid]
	_face(fig, target - fig.position)
	fig.play_clip("move_walk")
	var dur := maxf(0.3, fig.position.distance_to(target) * 0.28)
	var tw := create_tween()
	tw.tween_property(fig, "position", target, dur)
	await tw.finished
	fig.play_clip("idle")

## Walk the figure THROUGH each node of the path (follows the graph edges).
## If a node is occupied by another figure (a JUMP), the figure leaps in an arc
## OVER that figure to the landing node — instead of sliding straight through it.
func _walk_path(uid: int, nodes: Array) -> void:
	var fig: Figure3D = _vis.get(uid)
	if fig == null or nodes.is_empty():
		return
	var phasing := _gs.has_passive(uid, "phase") or _gs.has_passive(uid, "aerial")
	fig.play_clip("move_walk")
	var announced := false
	var i := 0
	while i < nodes.size():
		var nid := int(nodes[i])
		# Bloqueado si el estado O la VISTA tienen una figura ahí: aunque el estado
		# se desincronizara, jamás se debe ATRAVESAR una figura visible (se salta).
		var blocked: bool = (_gs.board.has(nid) and int(_gs.board[nid]) != uid) or _vis_occupied(nid, uid)
		if blocked and not phasing:
			# SALTO: SIEMPRE en arco por encima del ocupante (aunque sea el último
			# nodo del camino por un desync — nunca se camina a través de nadie).
			if not announced:
				_dramatize_effect(uid, "Salto")
				announced = true
			var land := i + 1 if i + 1 < nodes.size() else i
			await _hop_over(fig, _gs.map.pos_of(nid), _gs.map.pos_of(int(nodes[land])))
			i = land + 1
		else:
			# PHASE: walk straight THROUGH the occupant (announce it).
			if blocked and phasing and not announced:
				_dramatize_effect(uid, "Phase")
				announced = true
			var target := _gs.map.pos_of(nid)
			_face(fig, target - fig.position)
			var dur := maxf(0.16, fig.position.distance_to(target) * 0.34)
			var tw := create_tween()
			tw.tween_property(fig, "position", target, dur)
			await tw.finished
			i += 1
	fig.play_clip("idle")

## ¿Hay alguna OTRA figura parada visualmente en este nodo? (respaldo del estado)
func _vis_occupied(nid: int, ignore_uid: int) -> bool:
	var p := _gs.map.pos_of(nid)
	for ouid in _vis.keys():
		if ouid != ignore_uid and is_instance_valid(_vis[ouid]) and _vis[ouid].position.distance_to(p) < 0.3:
			return true
	return false

## A parabolic leap from the figure's current position, arcing up and OVER the
## figure standing at `over_pos`, landing at `land_pos`. Reads clearly as "jumped
## over it": faces the landing, plays the run clip, and rises above the occupant.
func _hop_over(fig: Figure3D, over_pos: Vector3, land_pos: Vector3) -> void:
	var start := fig.position
	_face(fig, land_pos - start)
	fig.play_clip("move_run" if fig.has_clip("move_run") else "move_walk")
	var dur := maxf(0.45, start.distance_to(land_pos) * 0.3)
	# Peak clears the occupant's head (relative to the lower of the two ends).
	var arc_h := maxf(1.8, over_pos.y - minf(start.y, land_pos.y) + 1.4)
	var tw := create_tween()
	tw.tween_method(func(t: float):
		var p := start.lerp(land_pos, t)
		p.y += arc_h * 4.0 * t * (1.0 - t)   # 0 at ends, peak at the middle (over enemy)
		fig.position = p
	, 0.0, 1.0, dur)
	await tw.finished
	fig.position = land_pos

# ---------------------------------------------------------------- combat
func _play_combat(att_uid: int, def_uid: int, rec: Dictionary) -> void:
	# Velocidad de combate (Configuración) + botón ⏭ para saltarlo del todo.
	Engine.time_scale = float(maxi(1, Settings.combat_speed))
	if _skip_btn != null:
		_skip_btn.visible = true
	var a_name := _named(att_uid)
	var b_name := _named(def_uid)
	var a_col := _team_color(_gs.units[att_uid]["team"])
	var b_col := _team_color(_gs.units[def_uid]["team"])
	# Pre-combat windup on the board: face off + attacker winds up.
	var fa0: Figure3D = _vis.get(att_uid)
	var fb0: Figure3D = _vis.get(def_uid)
	if fa0 and fb0:
		_face(fa0, fb0.position - fa0.position)
		_face(fb0, fa0.position - fb0.position)
		fa0.play_clip("attack")
	await get_tree().create_timer(0.45).timeout
	var msg := _combat_msg(a_name, b_name, rec)
	# 1) the wheel (announce + spin + result)
	var data_a: Dictionary = _gs.rank_data(att_uid)
	var data_b: Dictionary = _gs.rank_data(def_uid)
	await _overlay.play(a_name, b_name, rec["seg_a"], rec["seg_b"], msg[0], msg[1],
		_gs.pool_for(att_uid), _gs.pool_for(def_uid), a_col, b_col,
		_gs.type_for(att_uid), _gs.type_for(def_uid), data_a, data_b,
		int(rec.get("idx_a", -1)), int(rec.get("idx_b", -1)))
	# 2) the close-up action shot
	await _combat_cutaway(att_uid, def_uid, rec)
	# 2.5) displacement (push / pull / swap), if any
	var disp: Dictionary = rec.get("disp", {})
	if not disp.is_empty():
		await _animate_displacement(disp)
	# 3) resolve KO removal (only real KOs)
	var ko: int = int(rec.get("ko", -1))
	if ko != -1 and _vis.has(ko):
		_vis[ko].queue_free()
		_vis.erase(ko)
		_status_lbls.erase(ko)
		_name_lbls.erase(ko)
	# RANK UP: the figure that scored the KO evolves (update its name tag).
	var ranked: int = int(rec.get("rankup", -1))
	if ranked != -1:
		_show_rankup(ranked)
	_refresh_status_labels()
	await _resolve_surround()
	Engine.time_scale = 1.0        # fin del combate: velocidad normal
	if _skip_btn != null:
		_skip_btn.visible = false

func _show_rankup(uid: int) -> void:
	Sfx.play("rankup")
	_swap_model(uid)                                   # change the 3D model if the stage has its own
	if _name_lbls.has(uid) and is_instance_valid(_name_lbls[uid]):
		_name_lbls[uid].text = _gs.name_for(uid)
	if _vis.has(uid) and is_instance_valid(_vis[uid]):
		(_vis[uid] as Figure3D).play_clip("attack_heavy")
	_status.text = "¡RANK UP!  " + _gs.name_for(uid)

## Rebuild a figure's 3D model when its current rank uses a DIFFERENT model (e.g. a
## creator evolution that morphs into another figure). Keeps position + name/status tags.
func _swap_model(uid: int) -> void:
	if not _vis.has(uid) or not is_instance_valid(_vis[uid]):
		return
	var data: Dictionary = _gs.model_data(uid)
	var old: Figure3D = _vis[uid]
	if String(data.get("glb", "")) == "" or String(data.get("glb", "")) == String(old.get_meta("glb", "")):
		return                                         # same model -> nothing to do
	var fig := Figure3D.new()
	add_child(fig)
	fig.setup(data["glb"], data["clips"], float(data.get("size", 1.0)))
	fig.set_meta("glb", String(data["glb"]))
	fig.position = old.position
	fig.rotation = old.rotation
	fig.scale = Vector3.ONE * 0.05               # grows in
	_add_team_ring(fig, _gs.units[uid]["team"])
	# move the floating tags (name + status) onto the new figure
	for tag_map in [_name_lbls, _status_lbls]:
		if tag_map.has(uid) and is_instance_valid(tag_map[uid]):
			var l: Node = tag_map[uid]
			if l.get_parent() != null:
				l.get_parent().remove_child(l)
			fig.add_child(l)
	_vis[uid] = fig
	fig.play_clip("idle")
	_dramatize_effect(uid, "Evolución")          # flash over the (new) figure
	# transition: the old version shrinks away, the new one pops in
	var shrink := create_tween()
	shrink.tween_property(old, "scale", Vector3.ONE * 0.05, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	shrink.tween_callback(old.queue_free)
	var grow := create_tween()
	grow.tween_property(fig, "scale", Vector3.ONE, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## KO any figures that combat/movement just surrounded (enemies on every side).
func _resolve_surround() -> void:
	var koed := _gs.check_surround()
	if koed.is_empty():
		return
	for uid in koed:
		if _vis.has(uid):
			_dramatize_effect(uid, "Rodeado")    # explain WHY it was KO'd
			_vis[uid].play_clip("ko")
	await get_tree().create_timer(1.2).timeout
	for uid in koed:
		if _vis.has(uid):
			_vis[uid].queue_free()
			_vis.erase(uid)
			_status_lbls.erase(uid)
			_name_lbls.erase(uid)
	_refresh_status_labels()

func _animate_displacement(disp: Dictionary) -> void:
	match String(disp.get("type", "")):
		"swap":
			var fa: Figure3D = _vis.get(int(disp["a"]))
			var fb: Figure3D = _vis.get(int(disp["b"]))
			var ta := _gs.map.pos_of(int(disp["a_to"]))
			var tb := _gs.map.pos_of(int(disp["b_to"]))
			var tw := create_tween()
			tw.set_parallel(true)
			if fa:
				fa.play_clip("move_walk")
				tw.tween_property(fa, "position", ta, 0.4)
			if fb:
				fb.play_clip("move_walk")
				tw.tween_property(fb, "position", tb, 0.4)
			await tw.finished
			if fa:
				fa.play_clip("idle")
			if fb:
				fb.play_clip("idle")
		"push", "pull", "dash", "retreat":
			var f: Figure3D = _vis.get(int(disp["uid"]))
			if f:
				var to := _gs.map.pos_of(int(disp["to"]))
				if f.position.distance_to(to) > 0.05:
					f.play_clip("move_walk")
					var tw2 := create_tween()
					tw2.tween_property(f, "position", to, 0.4)
					await tw2.finished
					f.play_clip("idle")
		"teleport":
			# desaparece -> reaparece en su entrada (con chispa de invocación)
			var ft: Figure3D = _vis.get(int(disp["uid"]))
			if ft:
				var tw3 := create_tween()
				tw3.tween_property(ft, "scale", Vector3.ONE * 0.05, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
				await tw3.finished
				ft.position = _gs.map.pos_of(int(disp["to"]))
				_summon_fx(ft, String(_gs.units[int(disp["uid"])]["team"]))   # crece + destello
				await get_tree().create_timer(0.5).timeout

func _named(uid: int) -> String:
	return _gs.name_for(uid) + ("  (tú)" if _gs.units[uid]["team"] == "player" else "  (rival)")

func _team_color(team: String) -> Color:
	return Color(0.45, 0.7, 1.0) if team == "player" else Color(1.0, 0.5, 0.45)

func _combat_msg(a_name: String, b_name: String, rec: Dictionary) -> Array:
	var r: int = int(rec["result"])
	var reason: String = Combat.win_reason(rec["seg_a"], rec["seg_b"])
	if r == 0:
		return ["Empate — nadie cae  (%s)" % reason, UITheme.TEXT]
	var winner := a_name if r > 0 else b_name
	var loser := b_name if r > 0 else a_name
	if int(rec.get("ko", -1)) != -1:
		return ["%s  ¡KO a %s!\n(%s)" % [winner, loser, reason], UITheme.SUCCESS]
	match String(rec.get("win_col", "")):
		"purple":
			return ["%s gana — %s\n(%s · %s)" % [winner, String(rec.get("effect", "Estado")), reason, loser], UITheme.R_EPIC]
		"blue":
			return ["%s bloquea\n(%s)" % [winner, reason], UITheme.PRIMARY_EDGE]
		_:
			return ["%s gana\n(%s)" % [winner, reason], UITheme.TEXT]

func _combat_cutaway(att_uid: int, def_uid: int, rec: Dictionary) -> void:
	var fa: Figure3D = _vis.get(att_uid)
	var fb: Figure3D = _vis.get(def_uid)
	if fa == null or fb == null:
		return
	var pa := fa.global_position
	var pb := fb.global_position
	var m := (pa + pb) * 0.5
	var dir := pb - pa
	dir.y = 0.0
	if dir.length() < 0.01:
		dir = Vector3(0, 0, 1)
	dir = dir.normalized()
	var side := dir.cross(Vector3.UP).normalized()
	var sep := pa.distance_to(pb)
	# Hide the other figures so they don't block the shot.
	for uid in _vis.keys():
		if uid != att_uid and uid != def_uid:
			_vis[uid].visible = false
	# 3/4 side angle, backed off a bit more to frame BOTH fighters.
	var cam_pos := m + side * (sep + 4.3) + Vector3(0, 2.0, 0)
	_combat_cam.look_at_from_position(cam_pos, m + Vector3(0, 0.9, 0), Vector3.UP)
	_combat_cam.current = true
	_face(fa, pb - pa)
	_face(fb, pa - pb)
	fa.play_clip("attack")
	await get_tree().create_timer(0.65).timeout
	var ko: int = int(rec.get("ko", -1))
	Sfx.play(_combat_sfx(rec))
	if ko != -1:
		var winner_uid := def_uid if ko == att_uid else att_uid
		if _vis.has(winner_uid):
			_vis[winner_uid].play_clip("attack_heavy")
			_victory_light(_vis[winner_uid].global_position)
		if _vis.has(ko):
			_vis[ko].play_clip("ko")
			_defeat_light(_vis[ko].global_position)
		await get_tree().create_timer(2.5).timeout      # hold so the KO is appreciated
	else:
		# Non-KO but decisive (block / effect): the winner still gets its glow.
		var rr: int = int(rec.get("result", 0))
		if rr != 0:
			var wuid := att_uid if rr > 0 else def_uid
			if _vis.has(wuid):
				_victory_light(_vis[wuid].global_position)
		# Survives: defender blocks (Blue) or flinches, then both return to idle.
		if _vis.has(def_uid):
			_vis[def_uid].play_clip("defend" if String(rec.get("win_col", "")) == "blue" else "hit")
		# Drama: pop the applied effect over the affected figure.
		var st: Dictionary = rec.get("status", {})
		if not st.is_empty():
			var fx_txt := "🛡 ¡RESISTIÓ!" if bool(st.get("resisted", false)) else String(st.get("fx", "Estado"))
			_dramatize_effect(int(st["target"]), fx_txt)
		await get_tree().create_timer(1.9).timeout
		if _vis.has(att_uid):
			_vis[att_uid].play_clip("idle")
		if _vis.has(def_uid):
			_vis[def_uid].play_clip("idle")
		await get_tree().create_timer(0.6).timeout
	# Restore the others.
	for uid in _vis.keys():
		if uid != att_uid and uid != def_uid:
			_vis[uid].visible = true
	_cam.current = true

## Slot de SFX según el desenlace del combate (ver carpetas en assets/audio/sfx/).
func _combat_sfx(rec: Dictionary) -> String:
	if int(rec.get("ko", -1)) != -1:
		return "ko"
	match String(rec.get("win_col", "")):
		"white", "gold":
			return "attack_hit"
		"blue":
			return "attack_block"
		"purple":
			return "attack_effect"
		_:
			return "attack_miss"

## Victoria: una pequeña luz VERDE envuelve al ganador y su nodo, y se desvanece.
func _victory_light(pos: Vector3) -> void:
	var l := OmniLight3D.new()
	l.light_color = Color(0.3, 1.0, 0.55)
	l.omni_range = 2.8
	l.light_energy = 0.0
	l.position = pos + Vector3(0, 1.2, 0)
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "light_energy", 3.2, 0.25)
	tw.tween_interval(1.3)
	tw.tween_property(l, "light_energy", 0.0, 0.8)
	tw.tween_callback(l.queue_free)

## Derrota: un haz desde ARRIBA baña al caído (como fundiéndose), parpadea y se
## APAGA — la luz que se extingue simula que perdió.
func _defeat_light(pos: Vector3) -> void:
	var l := SpotLight3D.new()
	l.light_color = Color(1.0, 0.84, 0.55)
	l.spot_range = 6.5
	l.spot_angle = 16.0
	l.light_energy = 0.0
	l.position = pos + Vector3(0, 4.6, 0)
	l.rotation_degrees.x = -90.0
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "light_energy", 6.0, 0.3)
	tw.tween_interval(0.55)
	tw.tween_property(l, "light_energy", 1.2, 0.16)   # parpadeo agónico…
	tw.tween_property(l, "light_energy", 4.2, 0.13)
	tw.tween_property(l, "light_energy", 0.7, 0.15)
	tw.tween_property(l, "light_energy", 2.4, 0.12)
	tw.tween_property(l, "light_energy", 0.0, 0.55)   # …y se apaga: perdió
	tw.tween_callback(l.queue_free)

# ---------------------------------------------------------------- victory
func _check_and_show_winner() -> bool:
	if _gs.winner == "":
		return false
	_show_winner(_gs.winner)
	return true

func _show_winner(team: String) -> void:
	Engine.time_scale = 1.0
	if _skip_btn != null:
		_skip_btn.visible = false
	_over = true
	_busy = true
	_reset_activation()
	_end_btn.visible = false
	var win := team == "player"
	Music.stop()
	Sfx.play("victory" if win else "defeat")
	if Loadout.tutorial and win:
		Settings.set_tutorial_done(true)
		if _tut_panel != null:
			_tut_panel.visible = false
	# XP REAL: se suma aquí, sube de nivel y regala piezas (persistente).
	var res: Dictionary = Inventory.add_match_xp(win, _online)

	var cl := CanvasLayer.new()
	cl.layer = 20
	add_child(cl)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.06, 0.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.add_child(bg)
	create_tween().tween_property(bg, "color:a", 0.92, 0.4)
	var glow := _vic_glow(UITheme.GOLD if win else UITheme.DANGER)
	cl.add_child(glow)
	glow.modulate.a = 0.0
	create_tween().tween_property(glow, "modulate:a", 1.0, 0.6)

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.offset_left = -210
	card.offset_right = 210
	card.offset_top = -300
	card.offset_bottom = 300
	card.add_theme_stylebox_override("panel", UITheme.panel(Color(0.09, 0.10, 0.18, 0.98), (UITheme.GOLD if win else UITheme.DANGER).darkened(0.1), 22, 2, 18))
	cl.add_child(card)
	card.pivot_offset = Vector2(210, 300)
	if win:
		# VICTORIA: la tarjeta ESTALLA en pantalla + lluvia de confeti.
		card.scale = Vector2(0.5, 0.5)
		card.rotation_degrees = -4.0
		var ct := create_tween()
		ct.set_parallel(true)
		ct.tween_property(card, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		ct.tween_property(card, "rotation_degrees", 0.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_confetti(cl)
	else:
		# DERROTA: la tarjeta CAE pesada desde arriba y la pantalla tiembla.
		card.position.y -= 700.0
		var dt := create_tween()
		dt.tween_property(card, "position:y", card.position.y + 700.0, 0.55).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
		dt.tween_callback(func():
			var sh := create_tween()
			for off in [10.0, -8.0, 6.0, -4.0, 0.0]:
				sh.tween_property(card, "rotation_degrees", off * 0.35, 0.05)
			var gt := create_tween()
			gt.tween_property(glow, "modulate:a", 0.35, 0.08)
			gt.tween_property(glow, "modulate:a", 1.0, 0.3))
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 12)
	card.add_child(v)

	v.add_child(_vic_lbl("🏆" if win else "💔", 40, UITheme.GOLD if win else UITheme.MUTED, true, 800))
	v.add_child(_vic_lbl("¡VICTORIA!" if win else "DERROTA", 42, (UITheme.GOLD if win else UITheme.DANGER), true, 800))
	v.add_child(_vic_lbl("Buen duelo." if win else "La próxima es tuya.", 16, UITheme.TEXT2, false, 600))
	if Loadout.tutorial and win:
		v.add_child(_vic_chip("🎓 ¡TUTORIAL COMPLETADO! Ya sabes jugar.", UITheme.SUCCESS))

	# --- barra de nivel REAL (animada hasta el progreso actual) ---
	v.add_child(_vic_lbl("Nivel %d" % int(res["level"]), 14, UITheme.TEXT2, true, 700))
	var xp := ProgressBar.new()
	xp.custom_minimum_size = Vector2(360, 18)
	xp.min_value = 0
	xp.max_value = Inventory.xp_needed()
	xp.value = 0
	xp.show_percentage = false
	var xbg := StyleBoxFlat.new(); xbg.bg_color = Color(0.1, 0.13, 0.22); xbg.set_corner_radius_all(9)
	var xfg := StyleBoxFlat.new(); xfg.bg_color = UITheme.GOLD; xfg.set_corner_radius_all(9)
	xp.add_theme_stylebox_override("background", xbg)
	xp.add_theme_stylebox_override("fill", xfg)
	v.add_child(_center(xp))
	create_tween().tween_property(xp, "value", float(Inventory.xp), 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	v.add_child(_vic_lbl("+%d XP  (%d/%d)" % [int(res["gained"]), Inventory.xp, Inventory.xp_needed()], 13, UITheme.GOLD, true, 700))

	# --- recompensas REALES por subir de nivel: COFRES reclamables en el lobby ---
	if int(res["leveled"]) > 0:
		v.add_child(_vic_chip("⬆ ¡SUBISTE A NIVEL %d!" % int(res["level"]), UITheme.SUCCESS))
		v.add_child(_vic_chip("🏅 +%d Cofre de Nivel — recógelo en el menú" % int(res["chests"]), UITheme.GOLD))
	else:
		v.add_child(_vic_chip("🎁 Tus cofres te esperan en el menú", UITheme.PRIMARY_EDGE))

	# buttons
	var rematch := Button.new()
	rematch.text = "↻  Revancha"
	rematch.custom_minimum_size = Vector2(360, 54)
	UITheme.button_font(rematch, 20, UITheme.TEXT2, true, 700)
	UITheme.style_surface(rematch, UITheme.SURFACE, UITheme.BORDER, 14)
	rematch.pressed.connect(func():
		if _online:
			NetSession.client.request_rematch()
			rematch.disabled = true
			rematch.text = "⌛ Esperando al rival…"
		else:
			get_tree().change_scene_to_file("res://scenes/board.tscn"))
	if _online:
		NetSession.client.rematch_wait.connect(func(_s: int):
			if is_instance_valid(rematch) and not rematch.disabled:
				rematch.text = "↻  ¡El rival quiere REVANCHA!")
	v.add_child(_center(rematch))
	var claim := Button.new()
	claim.text = "Reclamar y volver"
	claim.custom_minimum_size = Vector2(360, 60)
	UITheme.button_font(claim, 22, Color.WHITE, true, 800)
	UITheme.style_primary(claim, UITheme.PRIMARY, 16)
	claim.pressed.connect(_leave_to_menu)
	v.add_child(_center(claim))

	_status.text = ""

## Lluvia de confeti (victoria): emojis que caen girando por toda la pantalla.
func _confetti(cl: CanvasLayer) -> void:
	var vw := get_viewport().get_visible_rect().size
	var picks := ["🎉", "✨", "⭐", "🎊", "💛"]
	for i in 16:
		var l := Label.new()
		l.text = picks[i % picks.size()]
		l.add_theme_font_size_override("font_size", 26 + (i % 3) * 10)
		l.position = Vector2(randf() * vw.x, -60.0 - randf() * 120.0)
		l.rotation_degrees = randf_range(-40.0, 40.0)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cl.add_child(l)
		var tw := create_tween()
		tw.set_parallel(true)
		var dur := randf_range(1.4, 2.4)
		tw.tween_property(l, "position:y", vw.y + 80.0, dur).set_delay(randf() * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(l, "rotation_degrees", l.rotation_degrees + randf_range(-260.0, 260.0), dur)
		tw.chain().tween_callback(l.queue_free)

func _vic_glow(col: Color) -> TextureRect:
	var tr := TextureRect.new()
	tr.set_anchors_preset(Control.PRESET_CENTER)
	tr.offset_left = -260; tr.offset_right = 260; tr.offset_top = -320; tr.offset_bottom = 120
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var g := Gradient.new()
	g.set_color(0, Color(col.r, col.g, col.b, 0.3))
	g.set_color(1, Color(col.r, col.g, col.b, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 1.0)
	tr.texture = gt
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	return tr

func _center(c: Control) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.add_child(c)
	return cc

func _vic_lbl(t: String, sz: int, col: Color, title: bool, weight: int) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.label(l, sz, col, title, weight)
	return l

func _vic_chip(t: String, col: Color) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.pill(UITheme.SURFACE2, col.darkened(0.3), 10))
	p.add_child(_vic_lbl(t, 13, col, true, 700))
	return p
