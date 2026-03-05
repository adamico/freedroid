## Moves an entity along level waypoints using the classical FreeDroid patrol
## algorithm: walk toward the next waypoint at full speed, snap on arrival,
## wait a random duration, then pick a random connected waypoint.
class_name WaypointPatrolComponent
extends Node

@export var level_data: LevelData

var _current_wp_idx: int = -1
var _last_wp_idx: int = -1
var _wait_timer: float = 0.0


## Returns the patrol movement direction for the given world position.
## Returns Vector2.ZERO when pausing at a waypoint or when no data exists.
func get_patrol_direction(current_pos: Vector2) -> Vector2:
	if level_data == null or level_data.waypoints.is_empty():
		return Vector2.ZERO

	if _current_wp_idx == -1:
		_find_closest_waypoint(current_pos)

	if _current_wp_idx == -1:
		return Vector2.ZERO

	if _wait_timer > 0.0:
		return Vector2.ZERO

	var wp := level_data.waypoints[_current_wp_idx]
	var wp_pos := Vector2(wp.position) * GameConstantsData.TILE_SIZE
	var dist := current_pos.distance_to(wp_pos)

	if dist < 2.0:
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
		var wp_pos := Vector2(wp.position) * GameConstantsData.TILE_SIZE
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
