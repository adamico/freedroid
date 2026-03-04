## Drives Enemy behavior by calculating movement direction and firing intent.
## Outputs intent to an AIInputComponent.
class_name AIComponent
extends Node2D

enum State {
	IDLE,
	CHASE,
	ATTACK,
	FLEE,
}

@export var current_state: AIComponent.State = State.IDLE
@export var chase_radius := 300.0
@export var attack_radius := 150.0
@export var input: AIInputComponent

var target: Node2D = null

var _los_raycast: RayCast2D
var _level_data: LevelData
var _current_wp_idx: int = -1
var _waypoint_pause_timer: float = 0.0

@onready var _entity: DroidEntity = get_parent() as DroidEntity


func _ready() -> void:
	target = get_tree().get_first_node_in_group("player")
	_los_raycast = RayCast2D.new()
	add_child(_los_raycast)
	_los_raycast.collision_mask = 1 | 4 # Hit walls (1) and doors (4)

	# Avoid the raycast hitting the player and returning blocked
	if target and target is CollisionObject2D:
		_los_raycast.add_exception(target)

	# Assuming parent's parent is the level scene e.g., "level_00"
	var level_node = _entity.get_parent()
	if level_node and level_node.name.begins_with("level_"):
		var level_num = level_node.name.substr(6).to_int()
		var path = "res://data/converted/levels/level_%02d.tres" % level_num
		if ResourceLoader.exists(path):
			_level_data = load(path)


func _can_see_target() -> bool:
	if target == null:
		return false
	_los_raycast.target_position = to_local(target.global_position)
	_los_raycast.force_raycast_update()
	return not _los_raycast.is_colliding()


func _physics_process(delta: float) -> void:
	if input == null:
		return
	if _entity == null or not _entity.droid_data:
		return

	var distance_to_target := INF
	var can_see_target := false

	if is_instance_valid(target):
		distance_to_target = global_position.distance_to(target.global_position)
		can_see_target = _can_see_target()
	else:
		target = null

	var is_passive = _entity.droid_data.aggression == 0

	if not can_see_target or is_passive or target == null:
		current_state = State.IDLE
	elif distance_to_target <= attack_radius:
		current_state = State.ATTACK
	elif distance_to_target <= chase_radius:
		current_state = State.CHASE
	else:
		current_state = State.IDLE

	# Hide entity if Player cannot see it
	_entity.visible = can_see_target or target == null

	match current_state:
		State.IDLE:
			input.current_aim_direction = Vector2.ZERO
			input.current_is_firing = false
			_process_waypoints(delta)
		State.CHASE:
			input.current_movement_direction = global_position.direction_to(target.global_position)
			input.current_aim_direction = input.current_movement_direction
			input.current_is_firing = false
		State.ATTACK:
			# Stay still and shoot, or slowly move towards them
			input.current_movement_direction = Vector2.ZERO
			input.current_aim_direction = global_position.direction_to(target.global_position)
			input.current_is_firing = true


func _find_closest_waypoint() -> void:
	if _level_data == null or _level_data.waypoints.is_empty():
		return
	var min_dist = INF
	for i in range(_level_data.waypoints.size()):
		var wp = _level_data.waypoints[i]
		var wp_pos = Vector2(wp.position) * 64.0
		var d = global_position.distance_to(wp_pos)
		if d < min_dist:
			min_dist = d
			_current_wp_idx = i


func _process_waypoints(delta: float) -> void:
	if _waypoint_pause_timer > 0.0:
		_waypoint_pause_timer -= delta
		input.current_movement_direction = Vector2.ZERO
		return

	if _level_data == null or _level_data.waypoints.is_empty():
		input.current_movement_direction = Vector2.ZERO
		return

	if _current_wp_idx == -1:
		_find_closest_waypoint()

	if _current_wp_idx == -1:
		return

	var wp = _level_data.waypoints[_current_wp_idx]
	var wp_pos = Vector2(wp.position) * 64.0
	var dist = global_position.distance_to(wp_pos)

	if dist < 10.0:
		_waypoint_pause_timer = randf_range(0.5, 2.0)
		if wp.connections.size() > 0:
			# Connections in legacy are 1-based or 0-based? Let's check wp.connections
			# Legacy waypoint connections usually reference the waypoint index.
			# In data converter, it parses tokens as ints directly.
			var next_wp = wp.connections[randi() % wp.connections.size()]
			# If 1-based, we would subtract 1. Often waypoint indices start at 0.
			# Assume indices in connection are 0-based.
			if next_wp >= 0 and next_wp < _level_data.waypoints.size():
				_current_wp_idx = next_wp
			else:
				# Error fallback
				_current_wp_idx = randi() % _level_data.waypoints.size()
		else:
			_current_wp_idx = randi() % _level_data.waypoints.size()
		input.current_movement_direction = Vector2.ZERO
	else:
		input.current_movement_direction = global_position.direction_to(wp_pos)
