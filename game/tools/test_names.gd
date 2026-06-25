extends SceneTree
## Print every figure's attack labels (names) to verify the roster naming.
## Run: Godot --headless --path game --script res://tools/test_names.gd

func _initialize() -> void:
	for d in Roster.FIGURES:
		print("== ", d["name"], "  (", d["type"], ") ==")
		for s in d["attack"]:
			print("   ", Combat.label(s))
	print("NAMES_OK")
	quit()
