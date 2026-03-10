extends GutTest


func _make_waypoint(pos: Vector2i, connections: PackedInt32Array) -> WaypointData:
	var wp := WaypointData.new()
	wp.position = pos
	wp.connections = connections
	return wp


func _single_waypoint_level() -> LevelData:
	var level := LevelData.new()
	level.waypoints = [_make_waypoint(Vector2i(1, 1), PackedInt32Array())]
	return level


func test_arrival_snaps_to_center_and_zeroes_velocity() -> void:
	var patrol := WaypointPatrolComponent.new()
	patrol.level_data = _single_waypoint_level()
	add_child_autofree(patrol)

	var entity := Node2D.new()
	entity.global_position = Vector2(95.0, 96.0) # within arrival threshold to centre (96,96)
	var movement := MovementComponent.new()
	movement.name = "MovementComponent"
	movement.velocity = Vector2(25.0, 0.0)
	entity.add_child(movement)
	add_child_autofree(entity)

	var dir := patrol.get_patrol_direction(entity, 0.016)

	assert_eq(dir, Vector2.ZERO)
	assert_eq(entity.global_position, Vector2(96.0, 96.0))
	assert_eq(movement.velocity, Vector2.ZERO)


func test_overshoot_detection_triggers_arrival_snap() -> void:
	var patrol := WaypointPatrolComponent.new()
	patrol.level_data = _single_waypoint_level()
	patrol.set("_current_wp_idx", 0)
	add_child_autofree(patrol)

	var entity := Node2D.new()
	entity.global_position = Vector2(110.0, 96.0) # right of centre (96,96)
	var movement := MovementComponent.new()
	movement.name = "MovementComponent"
	movement.velocity = Vector2(60.0, 0.0) # moving away from waypoint
	entity.add_child(movement)
	add_child_autofree(entity)

	var dir := patrol.get_patrol_direction(entity, 0.016)

	assert_eq(dir, Vector2.ZERO)
	assert_eq(entity.global_position, Vector2(96.0, 96.0))


func test_next_waypoint_selection_uses_connections_when_available() -> void:
	var patrol := WaypointPatrolComponent.new()
	var level := LevelData.new()
	level.waypoints = [
		_make_waypoint(Vector2i(0, 0), PackedInt32Array([1])),
		_make_waypoint(Vector2i(2, 0), PackedInt32Array([0])),
	]
	patrol.level_data = level
	patrol.set("_current_wp_idx", 0)
	add_child_autofree(patrol)

	patrol.call("_on_waypoint_reached")

	assert_eq(patrol.get("_current_wp_idx"), 1)
