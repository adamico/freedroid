extends GutTest


func _resource_files(path: String) -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open(path)
	assert_not_null(dir, "Directory should exist: %s" % path)
	if dir == null:
		return files

	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir():
			continue
		if file_name.ends_with(".tres"):
			files.append(path.path_join(file_name))
	dir.list_dir_end()
	files.sort()
	return files


func test_converted_droid_resources_have_required_fields() -> void:
	var files := _resource_files("res://data/converted/droids")
	assert_gt(files.size(), 0)

	for path in files:
		var data := load(path) as DroidData
		assert_not_null(data, "Expected DroidData at %s" % path)
		assert_gt(data.maxspeed, 0.0, "maxspeed must be > 0: %s" % path)
		assert_gt(data.accel, 0.0, "accel must be > 0: %s" % path)
		assert_gt(data.maxenergy, 0.0, "maxenergy must be > 0: %s" % path)
		assert_ne(data.droid_name, "", "droid_name must be set: %s" % path)
		assert_true(data.gun >= 0, "gun id must be >= 0: %s" % path)


func test_converted_bullet_resources_have_required_fields() -> void:
	var files := _resource_files("res://data/converted/bullets")
	assert_gt(files.size(), 0)

	for path in files:
		var data := load(path) as BulletData
		assert_not_null(data, "Expected BulletData at %s" % path)
		assert_true(data.recharging_time >= 0.0, "recharging_time must be >= 0: %s" % path)
		assert_true(data.speed >= 0.0, "speed must be >= 0: %s" % path)
		assert_true(data.damage >= 0, "damage must be >= 0: %s" % path)
		assert_true(data.range_dist >= 0.0, "range_dist must be >= 0: %s" % path)
