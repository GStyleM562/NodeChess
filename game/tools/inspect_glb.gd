extends SceneTree
## Lists the animation clips inside each new GLB so we can build its clip map.

func _initialize() -> void:
	var paths := [
		"res://assets/figures/heal_bunny/Meshy_AI_Meshy_Merged_Animations.glb",
		"res://assets/figures/mage_bunny/Meshy_AI_Meshy_Merged_Animations (1).glb",
		"res://assets/figures/tank_bunny/Meshy_AI_Meshy_Merged_Animations.glb",
	]
	for p in paths:
		print("=== ", p, " ===")
		var packed = load(p)
		if packed == null:
			print("  (no cargo)")
			continue
		var inst = packed.instantiate()
		var ap := _find_anim(inst)
		if ap == null:
			print("  (sin AnimationPlayer)")
		else:
			for a in ap.get_animation_list():
				print("  clip: ", a)
		inst.free()
	quit()

func _find_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _find_anim(c)
		if r != null:
			return r
	return null
