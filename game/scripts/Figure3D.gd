extends Node3D
class_name Figure3D
## Loads a Meshy GLB figure, normalizes its height, and plays animation clips
## by our Tier 1 names (idle / move_walk / attack / ...), remapping to the
## figure's actual Meshy clip names via a per-figure map.

const LOOPED := ["idle", "move_walk", "move_run", "move_fly"]

var _anim: AnimationPlayer
var _clip_map: Dictionary = {}      # our_name -> meshy clip name
var _model: Node3D
var current_clip: String = ""

## glb_path: res:// path. clip_map: { "idle": "Idle_3", ... }.
## size_mult: relative size (golem bigger, etc.). target_height: world units.
func setup(glb_path: String, clip_map: Dictionary, size_mult: float = 1.0, target_height: float = 1.5) -> bool:
	_clip_map = clip_map
	var packed = load(glb_path)
	if packed == null:
		push_error("Figure3D: no se pudo cargar " + glb_path)
		return false
	_model = packed.instantiate()
	add_child(_model)
	# Normalize so every figure stands at a consistent on-board height.
	var ab := _visual_aabb(_model)
	if ab.size.y > 0.001:
		_model.scale = Vector3.ONE * ((target_height * size_mult) / ab.size.y)
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

## Returns the list of our-names that actually exist for this figure.
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

# --- AABB of all visual meshes, in this figure's local space ---
func _visual_aabb(root: Node) -> AABB:
	var res := {"ab": AABB(), "has": false}
	_accum_aabb(root, root, res)
	return res["ab"] if res["has"] else AABB(Vector3.ZERO, Vector3.ONE)

func _accum_aabb(node: Node, root: Node3D, res: Dictionary) -> void:
	if node is VisualInstance3D:
		var vi := node as VisualInstance3D
		var rel := root.global_transform.affine_inverse() * vi.global_transform
		var box: AABB = rel * vi.get_aabb()
		if not res["has"]:
			res["ab"] = box
			res["has"] = true
		else:
			res["ab"] = (res["ab"] as AABB).merge(box)
	for c in node.get_children():
		_accum_aabb(c, root, res)
