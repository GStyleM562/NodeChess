extends SceneTree
## Verify the new bunny models load and their clip maps resolve (idle + walk).

func _initialize() -> void:
	var ok := true
	for id in ["heal_bunny", "mage_bunny", "tank_bunny"]:
		var idx := -1
		for i in Roster.FIGURES.size():
			if String(Roster.FIGURES[i].get("id", "")) == id:
				idx = i
		if idx == -1:
			print("  %s NOT in roster" % id)
			ok = false
			continue
		var fd: Dictionary = Roster.FIGURES[idx]
		var fig := Figure3D.new()
		get_root().add_child(fig)
		var loaded: bool = fig.setup(String(fd["glb"]), fd["clips"], float(fd.get("size", 1.0)))
		var has_idle: bool = fig.has_clip("idle")
		var has_walk: bool = fig.has_clip("move_walk")
		print("  %-12s loaded=%s idle=%s walk=%s" % [id, loaded, has_idle, has_walk])
		ok = ok and loaded and has_idle and has_walk
		fig.queue_free()
	print("MODELS_OK" if ok else "MODELS_FAIL")
	quit()
