extends Control
## Attack Tester — activate a single figure's attack to test its presentation per
## TYPE: Moneda (coin toss), Dado (a real 3D cube that rolls), Suma 2d6 (two 3D
## pip dice), Ruleta (slot reel). Uses each figure's REAL attack pool.

var _index := 0
var _stage: Control
var _name_label: Label
var _type_label: Label
var _result_label: Label
var _launch_btn: Button
var _busy := false

# Cube geometry. Face order = the 6 outward directions.
const DIRS := [
	Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0),
	Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, -1, 0),
]
# Euler that orients a +Z-facing quad/label so its normal points along DIRS[f].
const QUAD_EULER := [
	Vector3(0, 0, 0), Vector3(0, PI, 0), Vector3(0, PI / 2, 0),
	Vector3(0, -PI / 2, 0), Vector3(-PI / 2, 0, 0), Vector3(PI / 2, 0, 0),
]
# Euler that rotates the whole cube so face f points at the camera (+Z).
const FACE_FRONT := [
	Vector3(0, 0, 0), Vector3(0, PI, 0), Vector3(0, -PI / 2, 0),
	Vector3(0, PI / 2, 0), Vector3(PI / 2, 0, 0), Vector3(-PI / 2, 0, 0),
]

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var top := VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = 16
	top.offset_left = 12
	top.offset_right = -12
	add_child(top)
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 30)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(_name_label)
	_type_label = Label.new()
	_type_label.add_theme_font_size_override("font_size", 22)
	_type_label.modulate = Color(0.8, 0.85, 1.0)
	_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(_type_label)

	_stage = Control.new()
	_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.offset_top = 120
	_stage.offset_bottom = -210
	_stage.clip_contents = false
	add_child(_stage)

	var bottom := VBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -200
	bottom.offset_bottom = -12
	bottom.offset_left = 12
	bottom.offset_right = -12
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_theme_constant_override("separation", 12)
	add_child(bottom)

	_result_label = Label.new()
	_result_label.add_theme_font_size_override("font_size", 24)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom.add_child(_result_label)

	_launch_btn = Button.new()
	_launch_btn.text = "Lanzar ataque"
	_launch_btn.custom_minimum_size = Vector2(300, 64)
	_launch_btn.add_theme_font_size_override("font_size", 28)
	_launch_btn.pressed.connect(_on_launch)
	bottom.add_child(_center(_launch_btn))

	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 16)
	var prev := Button.new()
	prev.text = "◀"
	prev.custom_minimum_size = Vector2(70, 46)
	prev.pressed.connect(func(): _switch(-1))
	nav.add_child(prev)
	var menu := Button.new()
	menu.text = "Menú"
	menu.custom_minimum_size = Vector2(130, 46)
	menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	nav.add_child(menu)
	var nxt := Button.new()
	nxt.text = "▶"
	nxt.custom_minimum_size = Vector2(70, 46)
	nxt.pressed.connect(func(): _switch(1))
	nav.add_child(nxt)
	bottom.add_child(nav)

	_refresh()

func _center(c: Control) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.add_child(c)
	return cc

func _refresh() -> void:
	var d: Dictionary = Roster.FIGURES[_index]
	_name_label.text = "%d/%d   %s" % [_index + 1, Roster.FIGURES.size(), d["name"]]
	_type_label.text = "Tipo de ataque: " + String(d.get("type", "?"))
	_result_label.text = "Toca «Lanzar ataque»"
	_result_label.modulate = Color(0.8, 0.8, 0.9)
	_clear_stage()

func _switch(dir: int) -> void:
	if _busy:
		return
	_index = wrapi(_index + dir, 0, Roster.FIGURES.size())
	_refresh()

func _on_launch() -> void:
	if _busy:
		return
	_busy = true
	_launch_btn.disabled = true
	_result_label.text = "…"
	var d: Dictionary = Roster.FIGURES[_index]
	var idx := _roll_index(d["attack"])
	var result: Dictionary = d["attack"][idx]
	await _present(String(d.get("type", "")), d["attack"], result, idx)
	var extra := "   [" + String(result["fx"]) + "]" if result.has("fx") else ""
	_result_label.text = "Resultado: " + Combat.label(result) + extra
	_result_label.modulate = Combat.color_of(result).lightened(0.2)
	_busy = false
	_launch_btn.disabled = false

## Weighted random INDEX into the pool (so we know which face/segment landed,
## even when two segments are identical).
func _roll_index(pool: Array) -> int:
	var total := 0.0
	for s in pool:
		total += float(s.get("w", 1.0))
	var pick := randf() * total
	for i in pool.size():
		pick -= float(pool[i].get("w", 1.0))
		if pick <= 0.0:
			return i
	return pool.size() - 1

func _present(type: String, pool: Array, result: Dictionary, idx: int) -> void:
	_clear_stage()
	match type:
		"Moneda":
			await _coin(pool, result)
		"Dado (D6)":
			await _die(pool, idx)
		"Suma 2d6":
			await _dice2(pool, idx)
		_:
			await _reel(pool, result)

func _clear_stage() -> void:
	for c in _stage.get_children():
		c.queue_free()

func _center_in_stage(ctrl: Control, sz: Vector2) -> void:
	await get_tree().process_frame
	ctrl.position = _stage.size * 0.5 - sz * 0.5

# =============================================================== 2D shape (coin)
func _mk_shape(seg: Dictionary, size: int, circle: bool) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(size, size)
	p.size = Vector2(size, size)
	var lbl := Label.new()
	lbl.name = "lbl"
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.offset_left = 10
	lbl.offset_right = -10
	lbl.offset_top = 6
	lbl.offset_bottom = -6
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 21)
	p.add_child(lbl)
	_set_shape(p, seg, circle)
	return p

func _set_shape(p: Panel, seg: Dictionary, circle: bool) -> void:
	var col := Combat.color_of(seg)
	var sb := StyleBoxFlat.new()
	sb.bg_color = col.darkened(0.3)
	var r := int(p.custom_minimum_size.x * 0.5) if circle else 16
	sb.corner_radius_top_left = r
	sb.corner_radius_top_right = r
	sb.corner_radius_bottom_left = r
	sb.corner_radius_bottom_right = r
	sb.border_width_left = 4
	sb.border_width_right = 4
	sb.border_width_top = 4
	sb.border_width_bottom = 4
	sb.border_color = col.lightened(0.4)
	p.add_theme_stylebox_override("panel", sb)
	var lbl := p.get_node_or_null("lbl")
	if lbl:
		(lbl as Label).text = Combat.label(seg)
		(lbl as Label).modulate = col.lightened(0.45)

# =============================================================== coin (toss)
func _coin(pool: Array, result: Dictionary) -> void:
	var faces := _two_faces(pool)
	var coin := _mk_shape(faces[0], 180, true)
	_stage.add_child(coin)
	await get_tree().process_frame
	coin.pivot_offset = coin.size * 0.5
	var base := _stage.size * 0.5 - coin.size * 0.5
	coin.position = base
	var arc := 190.0
	var n := 12
	for i in n:
		var phase := float(i + 1) / float(n)
		var y := base.y - arc * sin(PI * phase)
		var face: Dictionary = result if i == n - 1 else faces[i % 2]
		var t1 := create_tween().set_parallel(true)
		t1.tween_property(coin, "scale:y", 0.07, 0.06)
		t1.tween_property(coin, "position:y", (coin.position.y + y) * 0.5, 0.06)
		await t1.finished
		_set_shape(coin, face, true)
		var t2 := create_tween().set_parallel(true)
		t2.tween_property(coin, "scale:y", 1.0, 0.06)
		t2.tween_property(coin, "position:y", y, 0.06)
		await t2.finished
	var land := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	land.tween_property(coin, "position:y", base.y, 0.3)
	await land.finished

func _two_faces(pool: Array) -> Array:
	var s := pool.duplicate()
	s.sort_custom(func(a, b): return float(a.get("w", 1.0)) > float(b.get("w", 1.0)))
	if s.size() >= 2:
		return [s[0], s[1]]
	return [s[0], s[0]]

# =============================================================== 3D dice
## A real cube that rolls. Each face = one attack (colour + name) for a D6 figure.
func _die(pool: Array, idx: int) -> void:
	var faces: Array = []
	for f in 6:
		faces.append(_attack_face(pool[f % pool.size()]))
	var vp := _new_die_viewport(Vector2i(340, 340), 4.3, 36.0)
	var cube := _add_cube(vp["sv"], faces, Vector3.ZERO, 1.7)
	await _center_in_stage(vp["container"], Vector2(340, 340))
	await _roll(cube, idx, 1.5)

## Two real pip dice that roll; their SUM picks the attack (shown in the result).
func _dice2(pool: Array, idx: int) -> void:
	var target_sum := idx + 2                 # pool index 0 == 2d6 sum of 2
	var d1 := clampi(randi_range(maxi(1, target_sum - 6), mini(6, target_sum - 1)), 1, 6)
	var d2 := clampi(target_sum - d1, 1, 6)
	var pips: Array = []
	for v in range(1, 7):
		pips.append({"text": str(v), "bg": Color(0.93, 0.93, 0.96), "fg": Color(0.12, 0.12, 0.16)})
	var vp := _new_die_viewport(Vector2i(480, 300), 5.6, 38.0)
	var c1 := _add_cube(vp["sv"], pips, Vector3(-1.35, 0, 0), 1.45)
	var c2 := _add_cube(vp["sv"], pips.duplicate(true), Vector3(1.35, 0, 0), 1.45)
	await _center_in_stage(vp["container"], Vector2(480, 300))
	var r1 := _roll(c1, d1 - 1, 1.45)
	await _roll(c2, d2 - 1, 1.7)
	await r1

func _attack_face(seg: Dictionary) -> Dictionary:
	var col := Combat.color_of(seg)
	return {"text": Combat.label(seg), "bg": col.darkened(0.28), "fg": col.lightened(0.5)}

func _new_die_viewport(sz: Vector2i, cam_z: float, fov: float) -> Dictionary:
	var svc := SubViewportContainer.new()
	svc.stretch = false
	svc.custom_minimum_size = sz
	svc.size = sz
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sv := SubViewport.new()
	sv.size = sz
	sv.transparent_bg = true
	sv.world_3d = World3D.new()
	sv.msaa_3d = Viewport.MSAA_4X
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svc.add_child(sv)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 0, cam_z)
	cam.fov = fov
	sv.add_child(cam)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -32, 0)
	sun.light_energy = 1.15
	sv.add_child(sun)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.74, 0.82)
	env.ambient_light_energy = 0.95
	we.environment = env
	sv.add_child(we)
	_stage.add_child(svc)
	return {"container": svc, "sv": sv}

func _add_cube(sv: SubViewport, faces: Array, pos: Vector3, s: float) -> Node3D:
	var cube := Node3D.new()
	cube.position = pos
	sv.add_child(cube)
	var half := s * 0.5
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(s, s, s) * 0.99
	body.mesh = bm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.09, 0.09, 0.12)
	body.material_override = bmat
	cube.add_child(body)
	for f in 6:
		var fc: Dictionary = faces[f]
		var quad := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(s * 0.97, s * 0.97)
		quad.mesh = qm
		var qmat := StandardMaterial3D.new()
		qmat.albedo_color = fc["bg"]
		quad.material_override = qmat
		quad.position = DIRS[f] * (half + 0.011)
		quad.rotation = QUAD_EULER[f]
		cube.add_child(quad)
		var lbl := Label3D.new()
		lbl.text = String(fc["text"])
		lbl.modulate = fc["fg"]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.font_size = 190 if String(fc["text"]).length() <= 2 else 76
		lbl.pixel_size = 0.006
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl.width = (s * 0.9) / 0.006
		lbl.position = DIRS[f] * (half + 0.02)
		lbl.rotation = QUAD_EULER[f]
		cube.add_child(lbl)
	return cube

## Spin the cube on several axes, decelerating so that face `idx` ends facing
## the camera (a real-looking tumble, not a wobbling box).
func _roll(cube: Node3D, idx: int, dur: float) -> void:
	cube.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
	var target: Vector3 = FACE_FRONT[idx]
	var spun := Vector3(target.x + TAU * 2.0, target.y + TAU * 3.0, target.z)
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(cube, "rotation", spun, dur)
	await tw.finished
	cube.rotation = target

# =============================================================== slot reel
func _reel(pool: Array, result: Dictionary) -> void:
	var cell := 60
	var w := 360
	var win := Control.new()
	win.custom_minimum_size = Vector2(w, 120)
	win.size = Vector2(w, 120)
	win.clip_contents = true
	_stage.add_child(win)
	await _center_in_stage(win, Vector2(w, 120))
	var back := ColorRect.new()
	back.color = Color(0.08, 0.08, 0.11)
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	win.add_child(back)
	var strip := Control.new()
	win.add_child(strip)
	var line := ColorRect.new()
	line.color = Color(1, 1, 1, 0.10)
	line.position = Vector2(0, 120 * 0.5 - cell * 0.5)
	line.size = Vector2(w, cell)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win.add_child(line)
	var n := 22
	var ridx := 19
	for i in n:
		var seg: Dictionary = result if i == ridx else pool[randi() % pool.size()]
		strip.add_child(_mk_cell(seg, i * cell, w))
	var center_y := 120 * 0.5 - cell * 0.5
	strip.position.y = center_y
	var final_y := center_y - ridx * cell
	var tw := create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_property(strip, "position:y", final_y, 1.7)
	await tw.finished

func _mk_cell(seg: Dictionary, y: float, width: int) -> Control:
	var cell := Control.new()
	cell.position = Vector2(0, y)
	cell.size = Vector2(width, 60)
	var col := Combat.color_of(seg)
	var rect := ColorRect.new()
	rect.color = col.darkened(0.35)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.offset_top = 3
	rect.offset_bottom = -3
	cell.add_child(rect)
	var lbl := Label.new()
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.text = Combat.label(seg)
	lbl.modulate = col.lightened(0.35)
	cell.add_child(lbl)
	return cell
