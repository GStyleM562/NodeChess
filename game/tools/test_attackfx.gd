extends SceneTree
## Structural smoke test for AttackPresenter (shared by the tester + combat overlay).
## We exercise every node-building path (3D cube faces, viewport, 2D shape, reel)
## so missing/renamed APIs surface, without running the render/tween loop that
## stalls under --headless. Also instantiates AttackTester to compile-check it.
## Run: Godot --headless --path game --script res://tools/test_attackfx.gd

func _initialize() -> void:
	var p = AttackPresenter.new()
	p.size = Vector2(500, 400)
	get_root().add_child(p)
	await create_timer(0.1).timeout

	var sv := SubViewport.new()
	sv.size = Vector2i(64, 64)
	sv.world_3d = World3D.new()
	sv.render_target_update_mode = SubViewport.UPDATE_DISABLED   # don't render (stalls headless)
	get_root().add_child(sv)

	var faces: Array = []
	for f in 6:
		faces.append(p._attack_face({"col": "purple", "name": "Hex", "stars": 2, "fx": "Miedo"}))
	var cube = p._add_cube(sv, faces, Vector3.ZERO, 1.6)
	cube.rotation = p.FACE_FRONT[3]
	print("CUBE_OK kids=", cube.get_child_count())

	var pips: Array = []
	for v in range(1, 7):
		pips.append({"text": str(v), "bg": Color.WHITE, "fg": Color.BLACK})
	var c2 = p._add_cube(sv, pips, Vector3(3, 0, 0), 1.4)
	print("PIPS_OK kids=", c2.get_child_count())

	var shp = p._mk_shape({"col": "white", "name": "Slash", "pow": 80}, 100, true)
	print("SHAPE_OK ", shp.get_node_or_null("lbl") != null)

	var tester = load("res://scripts/AttackTester.gd").new()
	get_root().add_child(tester)
	await create_timer(0.05).timeout
	print("TESTER_OK")
	print("FX_OK")
	quit()
