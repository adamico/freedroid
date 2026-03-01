## Scans every level_*.tscn for door tiles in the TileMapLayer,
## spawns Door.tscn instances at those positions, erases the
## original tiles, and re-saves the scene.
##
## Run headless:
##   godot --headless --path . --script tools/bake_doors.gd
extends MainLoop

const DOOR_SCENE_PATH := "res://entities/door/Door.tscn"
const LEVELS_DIR := "res://levels/"

## From legacy defs.h:
## H_ZUTUERE = 18 (horizontal closed door)
## V_ZUTUERE = 27 (vertical closed door)
const H_DOOR_TILE := 18
const V_DOOR_TILE := 27

## All horizontal door phases (18–22) and vertical (27–31).
const H_DOOR_RANGE := [18, 19, 20, 21, 22]
const V_DOOR_RANGE := [27, 28, 29, 30, 31]


func _initialize() -> void:
	print("=== Door Bake Tool ===")

	var door_scene := load(DOOR_SCENE_PATH) as PackedScene
	if door_scene == null:
		printerr("ERROR: Could not load Door scene: ", DOOR_SCENE_PATH)
		return

	var dir := DirAccess.open(LEVELS_DIR)
	if dir == null:
		printerr("ERROR: Could not open levels dir: ", LEVELS_DIR)
		return

	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".tscn"):
			_process_level(LEVELS_DIR + fname, door_scene)
		fname = dir.get_next()
	dir.list_dir_end()

	print("=== Done ===")


func _process_level(path: String, door_scene: PackedScene) -> void:
	var scene := load(path) as PackedScene
	if scene == null:
		printerr("  SKIP (could not load): ", path)
		return

	var root := scene.instantiate() as Node
	if root == null:
		printerr("  SKIP (could not instantiate): ", path)
		return

	# Find the TileMapLayer (the root itself or a child).
	var tilemap: TileMapLayer = null
	if root is TileMapLayer:
		tilemap = root
	else:
		for child in root.get_children():
			if child is TileMapLayer:
				tilemap = child
				break

	if tilemap == null:
		root.free()
		return

	# Remove any previously baked Door nodes to avoid duplicates.
	var existing_doors: Array[Node] = []
	for child in root.get_children():
		if child is Door:
			existing_doors.append(child)
	for d in existing_doors:
		d.free()

	# Scan all used cells for door tiles.
	var doors_added := 0
	for cell in tilemap.get_used_cells():
		var atlas := tilemap.get_cell_atlas_coords(cell)
		var tile_col: int = atlas.x
		var orientation := -1

		if tile_col in H_DOOR_RANGE:
			orientation = 0
		elif tile_col in V_DOOR_RANGE:
			orientation = 1

		if orientation < 0:
			continue

		# World position: top-left of tile (Door.tscn children are offset by 32,32).
		var world_pos: Vector2 = tilemap.map_to_local(cell) - Vector2(32, 32)

		# Instantiate a Door at this position.
		var door := door_scene.instantiate() as Node2D
		door.name = "Door_%02d" % doors_added
		door.position = world_pos
		door.set("orientation", orientation)
		root.add_child(door)
		door.owner = root

		# Erase the tile from the TileMap.
		tilemap.erase_cell(cell)
		doors_added += 1

	if doors_added == 0:
		root.free()
		return

	# Pack and save the modified scene.
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		printerr("  ERROR packing scene: ", path, " code=", err)
		root.free()
		return

	err = ResourceSaver.save(packed, path)
	if err != OK:
		printerr("  ERROR saving scene: ", path, " code=", err)
	else:
		print("  ", path, ": baked ", doors_added, " door(s)")

	root.free()


func _process(_delta: float) -> bool:
	return true
