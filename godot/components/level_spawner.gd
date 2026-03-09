class_name LevelSpawner
extends Node

@export var level_number: int = 0
@export var min_spawn_distance_from_player_tiles: float = 4.0

var _enemies_spawned: int = 0
var _level_completed: bool = false
var _spawning_finished: bool = false
var _level_data: LevelData
var _spawn_data: DroidSpawnData

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
		# Defer spawn so player placement for this level is available for proximity filtering.
		call_deferred("_spawn_initial_droids")


func _spawn_initial_droids() -> void:
	_spawn_special_forces()
	_spawn_random_droids()
	_spawning_finished = true


func _process(_delta: float) -> void:
	if not _spawn_data or not _level_data:
		return

	if not _level_completed:
		_check_level_completed()


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
		if _is_too_close_to_player(pos):
			continue

		enemy.global_position = pos
		_inject_ai_data(enemy, type_scene)
		get_parent().add_child(enemy)
		_enemies_spawned += 1


func _spawn_random_droids() -> void:
	if _spawn_data.allowed_droid_types.is_empty() or _level_data.waypoints.is_empty():
		return

	var types = _spawn_data.allowed_droid_types
	var half := GameConstantsData.TILE_SIZE / 2.0
	var candidate_waypoints: Array[WaypointData] = []

	for wp in _level_data.waypoints:
		var candidate_pos = Vector2(wp.position) * GameConstantsData.TILE_SIZE + Vector2(half, half)
		if not _is_too_close_to_player(candidate_pos):
			candidate_waypoints.append(wp)

	if candidate_waypoints.is_empty():
		return

	var max_spawnable = mini(_spawn_data.max_random_droids, candidate_waypoints.size())

	for i in range(max_spawnable):
		var r_type = types[randi() % types.size()]
		var type_res = _load_droid_data(r_type)
		if not type_res:
			continue

		var wp_index = randi() % candidate_waypoints.size()
		var wp = candidate_waypoints[wp_index]
		candidate_waypoints.remove_at(wp_index)
		var pos = Vector2(wp.position) * GameConstantsData.TILE_SIZE \
		+ Vector2(half, half)

		var enemy = enemy_scene.instantiate() as Node2D
		if enemy.has_method("set_droid_data"):
			enemy.set_droid_data(type_res)
		elif "droid_data" in enemy:
			enemy.set("droid_data", type_res)

		enemy.global_position = pos
		enemy.add_to_group("enemy")
		_inject_ai_data(enemy, type_res)
		get_parent().add_child(enemy)
		_enemies_spawned += 1


func _is_too_close_to_player(spawn_pos: Vector2) -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return false

	var min_distance = min_spawn_distance_from_player_tiles * GameConstantsData.TILE_SIZE
	return spawn_pos.distance_to(player.global_position) < min_distance


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
	if not _spawning_finished:
		return

	var current_droids = get_tree().get_nodes_in_group("enemy")
	var count = 0
	# Count remaining enemies in this level
	for d in current_droids:
		if d.get_parent() == get_parent():
			count += 1

	# Level completes when all spawned enemies on this level are gone.
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
