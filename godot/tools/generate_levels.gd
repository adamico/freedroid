## Generates level scenes from LevelData resources.
##
## Run headless:
##   godot --headless --path . --script tools/generate_levels.gd --quit
extends MainLoop

const TILESET_PATH := "res://assets/tilesets/classic_tileset.tres"
const LEVELS_DIR := "res://data/converted/levels/"
const OUTPUT_DIR := "res://levels/"
const ATLAS_SOURCE_ID := 0
const VOID_TILE := 33 # TileTypes.VOID — skip these cells


func _initialize() -> void:
	print("=== Level Scene Generator ===")

	var tileset := load(TILESET_PATH) as TileSet
	if tileset == null:
		printerr("ERROR: Could not load TileSet at ", TILESET_PATH)
		return

	_ensure_output_dir()

	var level_files := _discover_level_files()
	if level_files.is_empty():
		return

	_process_all_levels(level_files, tileset)
	print("=== Done ===")


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(
		OUTPUT_DIR.replace(
			"res://",
			ProjectSettings.globalize_path("res://").get_base_dir() + "/",
		),
	)


func _discover_level_files() -> Array[String]:
	var dir := DirAccess.open(LEVELS_DIR)
	if dir == null:
		printerr("ERROR: Could not open ", LEVELS_DIR)
		return []

	var files: Array[String] = []
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.begins_with("level_") and fname.ends_with(".tres"):
			files.append(fname)
		fname = dir.get_next()
	dir.list_dir_end()
	files.sort()

	print("  Found ", files.size(), " level files")
	return files


func _process_all_levels(level_files: Array[String], tileset: TileSet) -> void:
	for level_file in level_files:
		var level_data := load(LEVELS_DIR + level_file) as LevelData
		if level_data == null:
			printerr("  SKIP: Could not load ", level_file)
			continue
		_generate_level_scene(level_data, tileset)


func _generate_level_scene(level: LevelData, tileset: TileSet) -> void:
	var scene_name := "level_%02d" % level.level_number

	var tile_map := TileMapLayer.new()
	tile_map.name = scene_name
	tile_map.tile_set = tileset

	var cells_set := _populate_cells(tile_map, level)
	_add_waypoint_markers(tile_map, level.waypoints)
	_save_scene(tile_map, scene_name, level, cells_set)

	tile_map.free()


func _populate_cells(tile_map: TileMapLayer, level: LevelData) -> int:
	var count := 0
	for y in range(level.ylen):
		for x in range(level.xlen):
			var tile_type: int = level.grid[y * level.xlen + x]
			if tile_type == VOID_TILE:
				continue
			tile_map.set_cell(
				Vector2i(x, y),
				ATLAS_SOURCE_ID,
				Vector2i(tile_type, level.color),
			)
			count += 1
	return count


func _add_waypoint_markers(tile_map: TileMapLayer, waypoints: Array[WaypointData]) -> void:
	for i in range(waypoints.size()):
		var marker := Marker2D.new()
		marker.name = "Waypoint_%02d" % i
		marker.position = Vector2(waypoints[i].position) * GameConstantsData.TILE_SIZE
		tile_map.add_child(marker)
		marker.owner = tile_map


func _save_scene(
		tile_map: TileMapLayer,
		scene_name: String,
		level: LevelData,
		cells_set: int,
) -> void:
	var output_path := OUTPUT_DIR + scene_name + ".tscn"

	var scene := PackedScene.new()
	var err := scene.pack(tile_map)
	if err != OK:
		printerr("  ERROR: Failed to pack ", scene_name, ": ", err)
		return

	err = ResourceSaver.save(scene, output_path)
	if err != OK:
		printerr("  ERROR: Failed to save ", scene_name, ": ", err)
		return

	print(
		"  %s: %dx%d grid, %d cells, %d waypoints → %s" % [
			scene_name,
			level.xlen,
			level.ylen,
			cells_set,
			level.waypoints.size(),
			output_path,
		],
	)


func _process(_delta: float) -> bool:
	return true # exit after _initialize
