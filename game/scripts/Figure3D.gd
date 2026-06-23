extends Node3D
class_name Figure3D
## Loads a Meshy GLB figure, normalizes it to a consistent on-board height by
## MEASURING THE SKELETON BONES (robust for skinned meshes, whose mesh AABB does
## not reflect the rendered size), recenters it on its base, and plays animation
## clips by our Tier 1 names, remapping to each figure's real Meshy clip names.

const LOOPED := ["idle", "move_walk", "move_run", "move_fly"]

var _anim: AnimationPlayer
var _clip_map: Dictionary = {}      # our_name -> meshy clip name
var _model: Node3D
var current_clip: String = ""

# View metrics (after normalization) used by the camera to frame the figure.
var view_height: float = 1.5
var view_radius: float = 0.5
var view_center_y: float = 0.75

# Debug
var native_height: float = 0.0
var applied_scale: float = 1.0
var measure_source: String = "bones"

func setup(glb_path: String, clip_map: Dictionary, size_mult: float = 1.0, target_height: float = 1.5) -> bool:
	_clip_map = clip_map
	var packed = load(glb_path)
	if packed == null:
		push_error("Figure3D: no se pudo cargar " + glb_path)
		return false
	_model = packed.instantiate()
	add_child(_model)

	var ab := _measure(_model)
	native_height = ab.size.y
	applied_scale = 1.0
	if ab.size.y > 0.00001:
		applied_scale = (target_height * size_mult) / ab.size.y
	_model.scale = Vector3.ONE * applied_scale

	# Recenter: bottom on the base (y=0), centered on x/z.
	var center := ab.position + ab.size * 0.5
	_model.position = Vector3(-center.x * applied_scale, -ab.position.y * applied_scale, -center.z * applied_scale)

	view_height = ab.size.y * applied_scale
	view_radius = maxf(ab.size.x, ab.size.z) * 0.5 * applied_scale
	view_center_y = view_height * 0.5
	print("[Figure3D] %s src=%s nativeH=%.4f scale=%.3f -> H=%.2f r=%.2f" % [
		glb_path.get_file(), measure_source, native_height, applied_scale, view_height, view_radius])

	_anim = _find_anim_player(_model)
	if _anim == null:
		push_warning("Figure3D: sin AnimationPlayer en " + glb_path)
	else:
		_configure_loops()
	return true

# --- Measurement -----------------------------------------------------------
## Prefer the skeleton's bone extents (reflect the actual rendered figure).
## Fall back to mesh AABB if there is no skeleton.
func _measure(root: Node) -> AABB:
	var skel := _find_skeleton(root)
	if skel != null and skel.get_bone_count() > 0:
		var rel := _relative_xform(root, skel)        # skeleton space -> model space (local only)
		var ab := AABB()
		var has := false
		for i in skel.get_bone_count():
			var p: Vector3 = rel * skel.get_bone_global_pose(i).origin
			if not has:
				ab = AABB(p, Vector3.ZERO)
				has = true
			else:
				ab = ab.expand(p)
		if has and ab.size.y > 0.00001:
			measure_source = "bones"
			# Bones span ~ankle..head; pad ~12% so the full mesh ≈ target height.
			var pad := ab.size.y * 0.12
			return AABB(ab.position - Vector3(0, pad, 0), ab.size + Vector3(0, pad * 2.0, 0))
	measure_source = "mesh"
	return _mesh_aabb(root)

func _find_skeleton(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var r := _find_skeleton(c)
		if r != null:
			return r
	return null

## Product of LOCAL transforms from ancestor (exclusive) down to node (inclusive).
func _relative_xform(ancestor: Node, node: Node) -> Transform3D:
	var chain: Array = []
	var n := node
	while n != null and n != ancestor:
		chain.push_front(n)
		n = n.get_parent()
	var t := Transform3D.IDENTITY
	for c in chain:
		if c is Node3D:
			t = t * (c as Node3D).transform
	return t

func _mesh_aabb(root: Node) -> AABB:
	var res := {"ab": AABB(), "has": false}
	_accum(root, Transform3D.IDENTITY, res)
	return res["ab"] if res["has"] else AABB(Vector3.ZERO, Vector3.ONE)

func _accum(node: Node, xform: Transform3D, res: Dictionary) -> void:
	if node is MeshInstance3D:
		var box: AABB = xform * (node as MeshInstance3D).get_aabb()
		if not res["has"]:
			res["ab"] = box
			res["has"] = true
		else:
			res["ab"] = (res["ab"] as AABB).merge(box)
	for c in node.get_children():
		var cx := xform
		if c is Node3D:
			cx = xform * (c as Node3D).transform
		_accum(c, cx, res)

# --- Animation -------------------------------------------------------------
func _find_anim_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _find_anim_player(c)
		if r != null:
			return r
	return null

func _configure_loops() -> void:
	for our_name in _clip_map.keys():
		var clip: String = _clip_map[our_name]
		if our_name in LOOPED and _anim.has_animation(clip):
			var a := _anim.get_animation(clip)
			if a != null:
				a.loop_mode = Animation.LOOP_LINEAR

func has_clip(our_name: String) -> bool:
	return _anim != null and _clip_map.has(our_name) and _anim.has_animation(_clip_map[our_name])

func play_clip(our_name: String) -> void:
	if not has_clip(our_name):
		return
	current_clip = our_name
	_anim.play(_clip_map[our_name])
