## Scans every level_*.tscn for interactive tiles (doors, consoles,
## elevators) in the TileMapLayer, spawns entity scene instances at
## those positions, erases door tiles, and re-saves the scene.
##
## Also restores any previously erased door tiles from LevelData.grid
## so re-baking is idempotent.
##
## Run headless:
##   godot --headless --path . --script tools/bake_level_entities.gd --quit
extends SceneTree

const LEVELS_DIR := "res://levels/"
const DATA_DIR := "res://data/converted/levels/"

const DOOR_SCENE := "res://entities/door/door.tscn"
const CONSOLE_SCENE := "res://entities/console/console.tscn"
const ELEVATOR_SCENE := "res://entities/elevator/elevator.tscn"
const RECHARGER_SCENE := "res://entities/recharger/recharger.tscn"
const ELEVATORS_DATA_PATH := "res://data/converted/elevators.tres"

var _elevators_data: ElevatorData

## From legacy defs.h:
## H_ZUTUERE=18..H_GANZTUERE=22  (horizontal door phases)
## V_ZUTUERE=27..V_GANZTUERE=31  (vertical door phases)
## KONSOLE_L=23, KONSOLE_R=24, KONSOLE_O=25, KONSOLE_U=26
## LIFT=32
const H_DOOR_RANGE := [18, 19, 20, 21, 22]
const V_DOOR_RANGE := [27, 28, 29, 30, 31]

const CONSOLE_TILES := {
	23: 0, # KONSOLE_L → facing left
	24: 1, # KONSOLE_R → facing right
	25: 2, # KONSOLE_O → facing up
	26: 3, # KONSOLE_U → facing down
}

const LIFT_TILE := 32
const REFRESH_TILES := [34, 35, 36, 37]


func _initialize() -> void:
	print("=== Level Entity Bake Tool ===")

	var door_scene := load(DOOR_SCENE) as PackedScene
	var console_scene := load(CONSOLE_SCENE) as PackedScene
	var elevator_scene := load(ELEVATOR_SCENE) as PackedScene
	var recharger_scene := load(RECHARGER_SCENE) as PackedScene
	_elevators_data = load(ELEVATORS_DATA_PATH) as ElevatorData

	if not door_scene or not console_scene \
	or not elevator_scene or not _elevators_data or not recharger_scene:
		printerr("ERROR: Could not load entity scenes or data")
		return

	for i in range(16):
		var level_path := "%slevel_%02d.tscn" % [LEVELS_DIR, i]
		var data_path := "%slevel_%02d.tres" % [DATA_DIR, i]
		_process_level(
			level_path,
			data_path,
			door_scene,
			console_scene,
			elevator_scene,
			recharger_scene,
		)

	print("=== Done ===")


func _process_level(
		path: String,
		data_path: String,
		door_scene: PackedScene,
		console_scene: PackedScene,
		elevator_scene: PackedScene,
		recharger_scene: PackedScene,
) -> void:
	var scene := load(path) as PackedScene
	if scene == null:
		return

	var level_data := load(data_path) as LevelData
	if level_data == null:
		printerr("  SKIP (no data): ", data_path)
		return

	var scene_root := scene.instantiate() as Node
	if scene_root == null:
		return

	# Find the TileMapLayer (scene_root itself or a child).
	var tilemap: TileMapLayer = null
	if scene_root is TileMapLayer:
		tilemap = scene_root
	else:
		for child in scene_root.get_children():
			if child is TileMapLayer:
				tilemap = child
				break

	if tilemap == null:
		scene_root.free()
		return

	# Remove previously baked entities to allow re-bake.
	var to_remove: Array[Node] = []
	for child in scene_root.get_children():
		if child is Door or child is Console or child is Elevator or child is Recharger:
			to_remove.append(child)
	for n in to_remove:
		n.free()

	# Restore any previously erased door tiles from LevelData.grid.
	for y in range(level_data.ylen):
		for x in range(level_data.xlen):
			var tile_id: int = level_data.grid[y * level_data.xlen + x]
			if tile_id in H_DOOR_RANGE or tile_id in V_DOOR_RANGE:
				var cell := Vector2i(x, y)
				if tilemap.get_cell_atlas_coords(cell) == Vector2i(-1, -1):
					tilemap.set_cell(cell, 0, Vector2i(tile_id, level_data.color))

	var level_color: int = level_data.color
	var doors := 0
	var consoles := 0
	var elevators := 0
	var rechargers := 0

	for cell in tilemap.get_used_cells():
		var atlas := tilemap.get_cell_atlas_coords(cell)
		var col: int = atlas.x
		var pos: Vector2 = tilemap.map_to_local(cell) - Vector2(32, 32)

		# --- Doors ---
		if col in H_DOOR_RANGE:
			var door := _add_entity(scene_root, door_scene, "Door_%02d" % doors, pos)
			door.set("orientation", 0)
			door.set("color", level_color)
			tilemap.erase_cell(cell)
			doors += 1
			continue

		if col in V_DOOR_RANGE:
			var door := _add_entity(scene_root, door_scene, "Door_%02d" % doors, pos)
			door.set("orientation", 1)
			door.set("color", level_color)
			tilemap.erase_cell(cell)
			doors += 1
			continue

		# --- Consoles ---
		if col in CONSOLE_TILES:
			var facing: int = CONSOLE_TILES[col]
			var console := _add_entity(scene_root, console_scene, "Console_%02d" % consoles, pos)
			console.set("facing", facing)
			consoles += 1
			continue

		# --- Elevators ---
		if col == LIFT_TILE:
			var elevator := _add_entity(
				scene_root,
				elevator_scene,
				"Elevator_%02d" % elevators,
				pos,
			)

			var found_index := -1
			for idx in range(_elevators_data.lifts.size()):
				var lift: LiftEntryData = _elevators_data.lifts[idx]
				if lift.deck == level_data.level_number and lift.position == cell:
					found_index = idx
					break

			if found_index == -1:
				printerr(
					"  WARNING: Could not find lift index for level ",
					level_data.level_number,
					" cell ",
					cell,
				)
			else:
				elevator.set_script(load("res://entities/elevator/elevator.gd"))
				elevator.set("lift_index", found_index)

			elevators += 1
			continue

		# --- Rechargers ---
		if col in REFRESH_TILES:
			_add_entity(scene_root, recharger_scene, "Recharger_%02d" % rechargers, pos)
			rechargers += 1
			# Do NOT erase the tilemap cell visually. Rechargers are just triggers placed ON top.
			continue

	var total := doors + consoles + elevators + rechargers
	if total == 0:
		scene_root.free()
		return

	# Clear scene_file_path so the packer doesn't attempt to diff
	# against the poorly-saved previous version of this same file.
	scene_root.scene_file_path = ""

	var packed := PackedScene.new()
	var err := packed.pack(scene_root)
	if err != OK:
		printerr("  ERROR packing: ", path, " code=", err)
		scene_root.free()
		return

	err = ResourceSaver.save(packed, path)
	if err != OK:
		printerr("  ERROR saving: ", path, " code=", err)
	else:
		print("  ", path, ": ", doors, "D ", consoles, "C ", elevators, "E ", rechargers, "R")

	scene_root.free()


func _add_entity(parent_node: Node, scene: PackedScene, node_name: String, pos: Vector2) -> Node2D:
	var inst := scene.instantiate() as Node2D
	inst.name = node_name
	inst.position = pos
	parent_node.add_child(inst)
	inst.owner = parent_node
	return inst


func _process(_delta: float) -> bool:
	return true
