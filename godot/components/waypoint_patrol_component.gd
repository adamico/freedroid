## Moves an entity along level waypoints using the classical FreeDroid patrol
## algorithm: walk toward the next waypoint at full speed, snap on arrival,
## wait a random duration, then pick a random connected waypoint.
class_name WaypointPatrolComponent
extends Node

@export var level_data: LevelData

const _HALF_TILE := GameConstantsData.TILE_SIZE / 2.0
const _TILE_CENTER_OFFSET := Vector2(_HALF_TILE, _HALF_TILE)

var _current_wp_idx: int = -1
var _last_wp_idx: int = -1
var _wait_timer: float = 0.0


## Returns the patrol movement direction for the given entity.
## Returns Vector2.ZERO when pausing at a waypoint or when no data exists.
func get_patrol_direction(entity: Node2D, _delta: float) -> Vector2:
	var current_pos = entity.global_position
	if level_data == null or level_data.waypoints.is_empty():
		return Vector2.ZERO

	if _current_wp_idx == -1:
		_find_closest_waypoint(current_pos)
		# Fallback abort if finding a waypoint failed (e.g. empty waypoint list)
		if _current_wp_idx == -1:
			return Vector2.ZERO

	if _wait_timer > 0.0:
		return Vector2.ZERO

	var wp := level_data.waypoints[_current_wp_idx]
	var wp_pos := Vector2(wp.position) * GameConstantsData.TILE_SIZE + _TILE_CENTER_OFFSET
	var dist := current_pos.distance_to(wp_pos)

	# To avoid jumping visually in the direction of movement, we do not teleport early.
	# Instead, we wait until the precise frame the droid touches the center (< 2.0px).
	# If the droid's speed is so fast that it overshoots the < 2.0px window entirely,
	# we catch the overshoot instantly by checking if its velocity has suddenly crossed
	# the waypoint and is now pointing away from it!
	var arrived := false
	if dist < 2.0:
		arrived = true
	else:
		var movement_comp = entity.get_node_or_null("MovementComponent")
		if movement_comp and "velocity" in movement_comp:
			var vel: Vector2 = movement_comp.get("velocity")
			if vel.length_squared() > 1.0:
				var vel_dir = vel.normalized()
				var dir_to_wp = current_pos.direction_to(wp_pos)
				# If dot product is <= 0, we've crossed the plane of the waypoint!
				if vel_dir.dot(dir_to_wp) <= 0.0:
					# Bound the check so bumping a wall far away doesn't misfire
					if dist < GameConstantsData.TILE_SIZE * 0.5:
						arrived = true

	if arrived:
		# Perfectly center the entity
		entity.global_position = wp_pos

		# CRITICAL: We must instantly wipe the entity's physics inertia!
		var movement_comp = entity.get_node_or_null("MovementComponent")
		if movement_comp and "velocity" in movement_comp:
			movement_comp.set("velocity", Vector2.ZERO)

		# Debug trace for tuning
		if Engine.get_physics_frames() % 10 == 0: # Throttle prints if stuck
			var log_msg = "[Patrol] Arrived smoothly at WP %d, zeroed velocity " % _current_wp_idx \
			+ "(dist was %.1f)" % dist
			print(log_msg)

		# Arrived — match legacy snap behavior
		_on_waypoint_reached()
		return Vector2.ZERO

	return current_pos.direction_to(wp_pos)


func process_wait(delta: float) -> void:
	if _wait_timer > 0.0:
		_wait_timer -= delta


func _find_closest_waypoint(current_pos: Vector2) -> void:
	if level_data == null or level_data.waypoints.is_empty():
		return
	var min_dist := INF
	for i in range(level_data.waypoints.size()):
		var wp := level_data.waypoints[i]
		var wp_pos := Vector2(wp.position) * GameConstantsData.TILE_SIZE + _TILE_CENTER_OFFSET
		var d := current_pos.distance_to(wp_pos)
		if d < min_dist:
			min_dist = d
			_current_wp_idx = i
	_last_wp_idx = _current_wp_idx


func _on_waypoint_reached() -> void:
	_last_wp_idx = _current_wp_idx
	_wait_timer = randf_range(0.0, GameConstantsData.ENEMY_MAX_WAIT)
	_select_next_waypoint()


func _select_next_waypoint() -> void:
	var wp := level_data.waypoints[_current_wp_idx]
	if wp.connections.size() > 0:
		# Pick a random connection — indices are 0-based.
		var next_wp: int = wp.connections[randi() % wp.connections.size()]
		if next_wp >= 0 and next_wp < level_data.waypoints.size():
			_current_wp_idx = next_wp
		else:
			_current_wp_idx = randi() % level_data.waypoints.size()
	else:
		_current_wp_idx = randi() % level_data.waypoints.size()
