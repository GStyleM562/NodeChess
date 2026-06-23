extends SceneTree
## Headless check: for each roster figure, load the GLB, find its AnimationPlayer,
## list imported animations, and confirm our Tier 1 clip map resolves.
## Run: Godot --headless --path game --script res://tools/verify_figures.gd

func _initialize() -> void:
	var total_missing := 0
	for data in Roster.FIGURES:
		var packed = load(data["glb"])
		print("== ", data["id"], "  (", data["name"], ") ==")
		if packed == null:
			print("  LOAD FAIL: ", data["glb"])
			total_missing += 1
			continue
		var inst = packed.instantiate()
		var ap := _find(inst)
		var have: Array = []
		if ap != null:
			have = Array(ap.get_animation_list())
		print("  imported anims (", have.size(), "): ", have)
		var missing: Array = []
		for our_name in data["clips"].keys():
			var clip: String = data["clips"][our_name]
			if ap == null or not ap.has_animation(clip):
				missing.append(our_name + " -> '" + clip + "'")
		if missing.is_empty():
			print("  Tier1 map: ALL OK (", data["clips"].size(), " clips)")
		else:
			print("  MISSING: ", missing)
			total_missing += missing.size()
		inst.free()
	print("\n=== TOTAL UNRESOLVED CLIPS: ", total_missing, " ===")
	quit()

func _find(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _find(c)
		if r != null:
			return r
	return null
