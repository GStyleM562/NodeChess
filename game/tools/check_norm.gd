extends SceneTree
## Confirms Figure3D normalization: every figure should end up ~1.5u tall.
## Run: Godot --headless --path game --script res://tools/check_norm.gd

func _initialize() -> void:
	var holder := Node3D.new()
	get_root().add_child(holder)
	for data in Roster.FIGURES:
		var f := Figure3D.new()
		holder.add_child(f)
		f.setup(data["glb"], data["clips"], float(data.get("size", 1.0)))
		print("    => %s  view_height=%.2f  radius=%.2f" % [data["id"], f.view_height, f.view_radius])
		f.queue_free()
	quit()
