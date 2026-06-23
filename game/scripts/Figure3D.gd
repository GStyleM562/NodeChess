extends Node3D
class_name Figure3D
## Loads a Meshy GLB figure, normalizes it to a consistent on-board height,
## recenters it on its base, and plays animation clips by our Tier 1 names
## (idle / move_walk / attack / ...), remapping to the figure's real Meshy
## clip names via a per-figure map.

const LOOPED := ["idle", "move_walk", "move_run", "move_fly"]

var _anim: AnimationPlayer
var _clip_map: Dictionary = {}      # our_name -> meshy clip name
var _model: Node3D
var current_clip: String = ""

# View metrics (after normalization) used by the camera to frame the figure.
var view_height: float = 1.5
var view_radius: float = 0.5
var view_center_y: float = 0.75

func setup(glb_path: String, clip_map: Dictionary, size_mult: float = 1.0, target_height: float = 1.5) -> bool:
	_clip_map = clip_map
	var packed = load(glb_path)
	if packed == null:
		push_error("Figure3D: no se pudo cargar " + glb_path)
		return false
	_model = packed.instantiate()
	add_child(_model)

	# Measure native size by composing LOCAL transforms (no global_transform,
	# so it is correct the instant the model is added — and handles GLBs whose
	# real size lives in a parent node scale).
	var ab := _local_aabb(_model)
	var s := 1.0
	if ab.size.y > 0.0001:
		s = (target_height * size_mult) / ab.size.y
	_model.scale = Vector3.ONE * s

	# Recenter: feet on the base (y=0), centered on x/z.
	var center := ab.position + ab.size * 0.5
	_model.position = Vector3(-center.x * s, -ab.position.y * s, -center.z * s)

	view_height = ab.size.y * s
	view_radius = maxf(ab.size.x, ab.size.z) * 0.5 * s
	view_center_y = view_height * 0.5
	print("[Figure3D] %s nativeH=%.3f scale=%.4f -> H=%.2f" % [glb_path.get_file(), ab.size.y, s, view_height])

	_anim = _find_anim_player(_model)
	if _anim == null:
		push_warning("Figure3D: sin AnimationPlayer en " + glb_path)
	else:
		_configure_loops()
	return true

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

func available_clips() -> Array:
	var out := []
	if _anim == null:
		return out
	for our_name in _clip_map.keys():
		if _anim.has_animation(_clip_map[our_name]):
			out.append(our_name)
	return out

func has_clip(our_name: String) -> bool:
	return _anim != null and _clip_map.has(our_name) and _anim.has_animation(_clip_map[our_name])

func play_clip(our_name: String) -> void:
	if not has_clip(our_name):
		return
	current_clip = our_name
	_anim.play(_clip_map[our_name])

# --- Combined AABB of all meshes, in this model's local space, via LOCAL transforms ---
func _local_aabb(root: Node) -> AABB:
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
