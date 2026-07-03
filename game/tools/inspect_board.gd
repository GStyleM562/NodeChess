extends SceneTree
## Inspect the new board GLBs (AABB size/orientation) and the ninja's clips.

func _initialize() -> void:
	var dirs := ["node_tile", "goal_player", "goal_enemy", "entrance_player",
		"entrance_enemy", "path_stone", "buff_crystal", "island_platform"]
	for d in dirs:
		var glb := _first_glb("res://assets/board/%s" % d)
		if glb == "":
			print(d, ": (sin glb)")
			continue
		var inst = (load(glb) as PackedScene).instantiate()
		get_root().add_child(inst)
		var bb := _merged_aabb(inst)
		print("%s: size=(%.2f, %.2f, %.2f) ymin=%.2f  [%s]" % [d, bb.size.x, bb.size.y, bb.size.z, bb.position.y, glb.get_file()])
		inst.free()
	print()
	var np := _first_glb("res://assets/figures/ninja")
	print("ninja glb: ", np)
	if np != "":
		var inst2 = (load(np) as PackedScene).instantiate()
		var ap := _find_anim(inst2)
		if ap == null:
			print("  (sin AnimationPlayer)")
		else:
			for a in ap.get_animation_list():
				print("  clip: ", a)
		var bb2 := _merged_aabb(inst2)
		print("  size=(%.2f, %.2f, %.2f)" % [bb2.size.x, bb2.size.y, bb2.size.z])
		inst2.free()
	quit()

func _first_glb(dir: String) -> String:
	var d := DirAccess.open(dir)
	if d == null:
		return ""
	for f in d.get_files():
		if f.ends_with(".glb") or f.ends_with(".gltf"):
			return dir + "/" + f
	return ""

func _merged_aabb(n: Node) -> AABB:
	var bb := AABB()
	var first := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var t: AABB = (mi as MeshInstance3D).get_aabb()
		t = (mi as MeshInstance3D).global_transform * t if (mi as Node3D).is_inside_tree() else t
		if first:
			bb = t
			first = false
		else:
			bb = bb.merge(t)
	return bb

func _find_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _find_anim(c)
		if r != null:
			return r
	return null
