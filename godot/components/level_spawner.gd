class_name LevelSpawner
extends Node

@export var level_number: int = 0
@export var spawn_interval: float = 5.0
var _spawn_data: DroidSpawnData
var _level_data: LevelData
var _spawn_timer: float = 0.0

var _enemies_spawned: int = 0
var _level_completed: bool = false

var enemy_scene: PackedScene = preload("res://entities/enemy/enemy.tscn")


func _ready() -> void:
	# Try to load existing spawn/level data based on level_number
	# If this is attached to level_00, we can read level_number from the name
	var p = get_parent()
	if p and p.name.begins_with("level_"):
		level_number = p.name.substr(6).to_int()

	var spawn_path = "res://data/converted/spawns/spawn_level_%02d.tres" % level_number
	if ResourceLoader.exists(spawn_path):
		_spawn_data = load(spawn_path) as DroidSpawnData

	var level_path = "res://data/converted/levels/level_%02d.tres" % level_number
	if ResourceLoader.exists(level_path):
		_level_data = load(level_path) as LevelData

	if _spawn_data:
		# Initial spawn of special forces
		_spawn_special_forces()

	_spawn_timer = spawn_interval


func _process(delta: float) -> void:
	if not _spawn_data or not _level_data:
		return

	if not _level_completed:
		_check_level_completed()

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = spawn_interval
		_try_spawn_random_droid()


func _spawn_special_forces() -> void:
	for sf in _spawn_data.special_forces:
		var type_scene = _load_droid_data(sf["type"])
		if type_scene == null:
			continue
		var enemy = enemy_scene.instantiate() as Node2D
		# Assume enemy has a DroidEntity component we can assign to
		if enemy is DroidEntity:
			enemy.droid_data = type_scene
		elif enemy.has_node("EnemyEntity"):
			pass # Or however enemy.tscn is arranged. Need to verify this later.

		var pos = Vector2(sf["x"], sf["y"]) * GameConstantsData.TILE_SIZE \
		+ Vector2(GameConstantsData.TILE_SIZE / 2.0, GameConstantsData.TILE_SIZE / 2.0)
		enemy.global_position = pos
		_inject_ai_data(enemy, type_scene)
		get_parent().add_child(enemy)
		_enemies_spawned += 1


func _try_spawn_random_droid() -> void:
	if _spawn_data.allowed_droid_types.is_empty():
		return

	var current_droids = get_tree().get_nodes_in_group("enemy")
	var count = 0
	# Only count enemies in this level
	for d in current_droids:
		if d.get_parent() == get_parent():
			count += 1

	if count >= _spawn_data.max_random_droids:
		return

	# Prevent spawning more than the maximum total allowed
	var expected_special_forces_count = _spawn_data.special_forces.size()
	var max_total_droids = expected_special_forces_count + _spawn_data.max_random_droids
	if _enemies_spawned >= max_total_droids:
		return

	# Pick random type
	var types = _spawn_data.allowed_droid_types
	var r_type = types[randi() % types.size()]

	var type_res = _load_droid_data(r_type)
	if not type_res:
		return

	# Pick random waypoint
	if _level_data.waypoints.is_empty():
		return
	var wp = _level_data.waypoints[randi() % _level_data.waypoints.size()]
	var half := GameConstantsData.TILE_SIZE / 2.0
	var pos = Vector2(wp.position) * GameConstantsData.TILE_SIZE \
	+ Vector2(half, half)

	var enemy = enemy_scene.instantiate() as Node2D
	# Let's set the resource based on the structure of enemy.tscn
	if enemy.has_method("set_droid_data"):
		enemy.set_droid_data(type_res)
	elif "droid_data" in enemy:
		enemy.set("droid_data", type_res)

	enemy.global_position = pos
	enemy.add_to_group("enemy")
	_inject_ai_data(enemy, type_res)
	get_parent().add_child(enemy)
	_enemies_spawned += 1


func _load_droid_data(droid_name: String) -> DroidData:
	var path = "res://data/converted/droids/droid_%s.tres" % droid_name
	if ResourceLoader.exists(path):
		return load(path) as DroidData
	return null


func _inject_ai_data(enemy: Node, droid_res: DroidData) -> void:
	if enemy.has_node("WaypointPatrolComponent") and _level_data:
		enemy.get_node("WaypointPatrolComponent").level_data = _level_data
	if enemy.has_node("AIComponent") and droid_res:
		enemy.get_node("AIComponent").aggression = droid_res.aggression


func _check_level_completed() -> void:
	var expected_special_forces_count = _spawn_data.special_forces.size()
	var max_total_droids = expected_special_forces_count + _spawn_data.max_random_droids

	# First condition: all expected droids have been spawned
	if _enemies_spawned >= max_total_droids:
		var current_droids = get_tree().get_nodes_in_group("enemy")
		var count = 0
		# Count remaining enemies in this level
		for d in current_droids:
			if d.get_parent() == get_parent():
				count += 1

		# Second condition: no enemies left alive
		if count == 0:
			_level_completed = true
			_convert_level_to_greyscale()


func _convert_level_to_greyscale() -> void:
	var level = get_parent()
	if level is TileMapLayer:
		var tilemap := level as TileMapLayer
		var used_cells = tilemap.get_used_cells()
		for cell in used_cells:
			var source_id = tilemap.get_cell_source_id(cell)
			var current_atlas_coords = tilemap.get_cell_atlas_coords(cell)
			var alt_tile = tilemap.get_cell_alternative_tile(cell)

			# Switch to row 6 (greyscale tiles)
			var new_atlas_coords = Vector2i(current_atlas_coords.x, 6)
			tilemap.set_cell(cell, source_id, new_atlas_coords, alt_tile)

		for child in level.get_children():
			if child is Door:
				child.set_color(6)
