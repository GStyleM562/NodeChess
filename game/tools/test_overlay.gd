extends SceneTree
## Smoke test: run the slot-machine combat overlay once, headless.
## Run: Godot --headless --path game --script res://tools/test_overlay.gd

func _initialize() -> void:
	var ov := CombatOverlay.new()
	get_root().add_child(ov)
	await create_timer(0.1).timeout
	var pa := [{"col": "gold", "pow": 40}, {"col": "blue"}, {"col": "white", "pow": 80}, {"col": "red"}]
	var pb := [{"col": "white", "pow": 80}, {"col": "red"}, {"col": "purple", "stars": 2, "fx": "Miedo"}]
	await ov.play("Ironclad Knight  (tú)", "Ironclad Knight  (rival)",
		{"col": "gold", "pow": 40}, {"col": "white", "pow": 80},
		"Ironclad Knight (tú) vence — Ironclad Knight (rival) ¡KO!", Color(0.6, 1, 0.7),
		pa, pb, Color(0.45, 0.7, 1.0), Color(1.0, 0.5, 0.45))
	print("OVERLAY_OK")
	quit()
