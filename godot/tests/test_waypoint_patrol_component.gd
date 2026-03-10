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


func _clear_group_nodes(group_name: String) -> void:
	for node in get_tree().get_nodes_in_group(group_name):
		if node == self:
			continue
		if node is Node:
			(node as Node).queue_free()
	await get_tree().process_frame


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


func test_reverse_course_after_collision_swaps_waypoints_and_sets_wait() -> void:
	var patrol := WaypointPatrolComponent.new()
	patrol.set("_current_wp_idx", 5)
	patrol.set("_last_wp_idx", 2)
	patrol.set("_wait_timer", 0.1)
	add_child_autofree(patrol)

	patrol.reverse_course_after_collision(0.5)

	assert_eq(patrol.get("_current_wp_idx"), 2)
	assert_eq(patrol.get("_last_wp_idx"), 5)
	assert_eq(patrol.get("_wait_timer"), 0.5)


func test_select_next_waypoint_avoids_blocked_path() -> void:
	await _clear_group_nodes("enemy")
	await _clear_group_nodes("player")

	var patrol := WaypointPatrolComponent.new()
	var level := LevelData.new()
	level.waypoints = [
		_make_waypoint(Vector2i(100, 100), PackedInt32Array([1, 2])),
		_make_waypoint(Vector2i(101, 100), PackedInt32Array([0])),
		_make_waypoint(Vector2i(100, 101), PackedInt32Array([0])),
	]
	patrol.level_data = level
	patrol.set("_current_wp_idx", 0)
	add_child_autofree(patrol)

	var actor := CharacterBody2D.new()
	actor.add_to_group("enemy")
	actor.global_position = Vector2(6432.0, 6432.0)
	var actor_shape := CollisionShape2D.new()
	var actor_circle := CircleShape2D.new()
	actor_circle.radius = 16.0
	actor_shape.shape = actor_circle
	actor_shape.name = "CollisionShape2D"
	actor.add_child(actor_shape)
	add_child_autofree(actor)

	var blocker := CharacterBody2D.new()
	blocker.add_to_group("player")
	# Position chosen for legacy shared radius (0.3 tiles):
	# blocks wp0->wp1 horizontal segment, but stays outside wp0->wp2 segment clearance.
	blocker.global_position = Vector2(6464.0, 6408.0)
	var blocker_shape := CollisionShape2D.new()
	var blocker_circle := CircleShape2D.new()
	blocker_circle.radius = 16.0
	blocker_shape.shape = blocker_circle
	blocker_shape.name = "CollisionShape2D"
	blocker.add_child(blocker_shape)
	add_child_autofree(blocker)

	patrol.call("_select_next_waypoint", actor)

	assert_eq(patrol.get("_current_wp_idx"), 2)
