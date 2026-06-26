extends Control
class_name AttackPresenter
## Reusable, type-aware attack presentation. Drop it into any Control area, give it
## a size, and `await present(type, pool, result)`:
##   Moneda     -> a coin toss (rises, two faces, lands on result)
##   Dado (D6)  -> a real 3D cube that rolls and lands on the attack face
##   Suma 2d6   -> two 3D pip dice that roll (their sum picks the attack)
##   _ (Ruleta) -> a slot-machine reel
## Everything centres inside this control's own size, so it works in the Attack
## Tester (full screen) and in the combat overlay (a smaller boxed area) alike.

const DIRS := [
	Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0),
	Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, -1, 0),
]
const QUAD_EULER := [
	Vector3(0, 0, 0), Vector3(0, PI, 0), Vector3(0, PI / 2, 0),
	Vector3(0, -PI / 2, 0), Vector3(-PI / 2, 0, 0), Vector3(PI / 2, 0, 0),
]
const FACE_FRONT := [
	Vector3(0, 0, 0), Vector3(0, PI, 0), Vector3(0, -PI / 2, 0),
	Vector3(0, PI / 2, 0), Vector3(PI / 2, 0, 0), Vector3(-PI / 2, 0, 0),
]

func present(type: String, pool: Array, result: Dictionary, idx: int = -1) -> void:
	clear()
	if idx < 0:
		idx = maxi(0, pool.find(result))
	match type:
		"Moneda":
			await _coin(pool, result)
		"Dado (D6)":
			await _die(pool, idx)
		"Suma 2d6":
			await _dice2(pool, idx)
		_:
			await _reel(pool, result)

func clear() -> void:
	for c in get_children():
		c.queue_free()

func _center(ctrl: Control, sz: Vector2) -> void:
	await get_tree().process_frame
	ctrl.position = size * 0.5 - sz * 0.5

# --------------------------------------------------------------- 2D shape (coin)
func _mk_shape(seg: Dictionary, s: int, circle: bool) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(s, s)
	p.size = Vector2(s, s)
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

# --------------------------------------------------------------- coin (toss)
func _coin(pool: Array, result: Dictionary) -> void:
	var faces := _two_faces(pool)
	var coin := _mk_shape(faces[0], 170, true)
	add_child(coin)
	await get_tree().process_frame
	coin.pivot_offset = coin.size * 0.5
	var base := size * 0.5 - coin.size * 0.5
	coin.position = base
	var arc := 175.0
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

# --------------------------------------------------------------- 3D dice
func _die(pool: Array, idx: int) -> void:
	var faces: Array = []
	for f in 6:
		faces.append(_attack_face(pool[f % pool.size()]))
	var vp := _new_die_viewport(Vector2i(340, 340), 4.3, 36.0)
	var cube := _add_cube(vp["sv"], faces, Vector3.ZERO, 1.7)
	await _center(vp["container"], Vector2(340, 340))
	await _roll_tween(cube, idx, 1.5).finished

func _dice2(pool: Array, idx: int) -> void:
	var target_sum := idx + 2
	var d1 := clampi(randi_range(maxi(1, target_sum - 6), mini(6, target_sum - 1)), 1, 6)
	var d2 := clampi(target_sum - d1, 1, 6)
	var pips: Array = []
	for v in range(1, 7):
		pips.append({"text": str(v), "bg": Color(0.93, 0.93, 0.96), "fg": Color(0.12, 0.12, 0.16)})
	var vp := _new_die_viewport(Vector2i(470, 290), 5.6, 38.0)
	var c1 := _add_cube(vp["sv"], pips, Vector3(-1.35, 0, 0), 1.45)
	var c2 := _add_cube(vp["sv"], pips.duplicate(true), Vector3(1.35, 0, 0), 1.45)
	await _center(vp["container"], Vector2(470, 290))
	var t1 := _roll_tween(c1, d1 - 1, 1.45)
	var t2 := _roll_tween(c2, d2 - 1, 1.7)
	await t1.finished
	await t2.finished

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
	add_child(svc)
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

## Returns the spin Tween (so the caller can await it, or run two in parallel).
func _roll_tween(cube: Node3D, idx: int, dur: float) -> Tween:
	cube.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
	var target: Vector3 = FACE_FRONT[idx]
	var spun := Vector3(target.x + TAU * 2.0, target.y + TAU * 3.0, target.z)
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(cube, "rotation", spun, dur)
	tw.finished.connect(func(): cube.rotation = target)
	return tw

# --------------------------------------------------------------- slot reel
func _reel(pool: Array, result: Dictionary) -> void:
	var cell := 60
	var w := int(min(420.0, size.x - 20.0))
	var win := Control.new()
	win.custom_minimum_size = Vector2(w, 120)
	win.size = Vector2(w, 120)
	win.clip_contents = true
	add_child(win)
	await _center(win, Vector2(w, 120))
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
