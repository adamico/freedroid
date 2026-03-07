extends SceneTree

func _init() -> void:
	var path := "res://entities/enemy/enemy.tscn"
	print("Processing %s..." % path)
	var pack := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if pack:
		var err := ResourceSaver.save(pack, path)
		if err != OK:
			print("Error saving res: %d" % err)
		else:
			print("Saved successfully.")
	quit()
