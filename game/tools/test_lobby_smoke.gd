extends SceneTree
## Smoke: the online lobby scene compiles + builds with the NetSession autoload live.

func _initialize() -> void:
	var ns = get_root().get_node_or_null("NetSession")
	var inst = load("res://scenes/online_lobby.tscn").instantiate()
	get_root().add_child(inst)
	await process_frame
	var ok: bool = ns != null and inst != null and inst.has_method("_my_deck")
	print("  NetSession autoload = %s" % (ns != null))
	print("  lobby built = %s" % (inst != null))
	print("LOBBY_OK" if ok else "LOBBY_FAIL")
	if inst != null:
		inst.queue_free()
	quit()
