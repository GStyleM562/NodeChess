extends SceneTree
## Structural smoke test for the attack presentations. We DON'T run the full
## tween/render loop (a 3D SubViewport stalls under --headless dummy rendering),
## but we DO exercise every node-building API path so missing/renamed properties
## (Label3D.width, QuadMesh.size, materials, constants…) surface as errors.
## Run: Godot --headless --path game --script res://tools/test_attackfx.gd

func _initialize() -> void:
	var t = load("res://scripts/AttackTester.gd").new()
	get_root().add_child(t)
	await create_timer(0.1).timeout

	var sv := SubViewport.new()
	sv.size = Vector2i(64, 64)
	sv.world_3d = World3D.new()
	get_root().add_child(sv)

	# Attack-name cube (D6 figure faces).
	var faces: Array = []
	for f in 6:
		faces.append(t._attack_face({"col": "purple", "name": "Hex", "stars": 2, "fx": "Miedo"}))
	var cube = t._add_cube(sv, faces, Vector3.ZERO, 1.6)
	cube.rotation = t.FACE_FRONT[3]
	print("CUBE_OK kids=", cube.get_child_count())

	# Pip cube (2d6).
	var pips: Array = []
	for v in range(1, 7):
		pips.append({"text": str(v), "bg": Color.WHITE, "fg": Color.BLACK})
	var c2 = t._add_cube(sv, pips, Vector3(3, 0, 0), 1.4)
	print("PIPS_OK kids=", c2.get_child_count())

	# Viewport builder + weighted index.
	var vp = t._new_die_viewport(Vector2i(120, 120), 4.0, 36.0)
	print("VP_OK ", vp.has("sv"))
	var pool: Array = Roster.FIGURES[1]["attack"]
	var idx = t._roll_index(pool)
	print("ROLL ", idx, " -> ", Combat.label(pool[idx]))
	print("FX_OK")
	quit()
