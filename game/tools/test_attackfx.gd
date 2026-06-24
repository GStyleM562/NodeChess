extends SceneTree
## Smoke test: run each attack-type presentation once, headless.
## Run: Godot --headless --path game --script res://tools/test_attackfx.gd

func _initialize() -> void:
	var t = load("res://scripts/AttackTester.gd").new()
	get_root().add_child(t)
	await create_timer(0.1).timeout
	var pool := [{"col": "white", "pow": 80}, {"col": "purple", "stars": 2, "fx": "Miedo"}, {"col": "blue"}, {"col": "red"}, {"col": "gold", "pow": 40}]
	for ty in ["Moneda", "Dado (D6)", "Suma 2d6", "Ruleta"]:
		var res: Dictionary = pool[randi() % pool.size()]
		await t._present(ty, pool, res)
		print("FX_OK ", ty)
	quit()
