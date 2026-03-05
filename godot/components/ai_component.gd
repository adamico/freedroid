## Drives Enemy behavior by calculating movement direction and firing intent.
## Outputs intent to an AIInputComponent. Delegates patrol movement to a
## WaypointPatrolComponent.
class_name AIComponent
extends Node2D

enum State {
	IDLE,
	CHASE,
	ATTACK,
	FLEE,
}

@export var attack_radius := 150.0
@export var chase_radius := 300.0
@export var current_state: AIComponent.State = State.IDLE
@export var input: AIInputComponent
@export var patrol: WaypointPatrolComponent
@export var aggression: int = 0

var target: Node2D = null

var _los_raycast: RayCast2D


func _ready() -> void:
	target = get_tree().get_first_node_in_group("player")
	_los_raycast = RayCast2D.new()
	add_child(_los_raycast)
	_los_raycast.collision_mask = 1 | 4 # Hit walls (1) and doors (4)

	# Avoid the raycast hitting the player and returning blocked
	if target and target is CollisionObject2D:
		_los_raycast.add_exception(target)


func _can_see_target() -> bool:
	if target == null:
		return false
	_los_raycast.target_position = to_local(target.global_position)
	_los_raycast.force_raycast_update()
	return not _los_raycast.is_colliding()


func _physics_process(delta: float) -> void:
	if input == null:
		return

	var distance_to_target := INF
	var can_see_target := false

	if is_instance_valid(target):
		distance_to_target = global_position.distance_to(target.global_position)
		can_see_target = _can_see_target()
	else:
		# Re-acquire target when it becomes invalid (e.g. player respawn)
		target = get_tree().get_first_node_in_group("player")
		if target and target is CollisionObject2D:
			_los_raycast.add_exception(target)

	var is_passive := aggression == 0

	if not can_see_target or is_passive or target == null:
		current_state = State.IDLE
	elif distance_to_target <= attack_radius:
		current_state = State.ATTACK
	elif distance_to_target <= chase_radius:
		current_state = State.CHASE
	else:
		current_state = State.IDLE

	# Hide entity when player cannot see it (matches legacy PutEnemy visibility check)
	get_parent().visible = can_see_target or target == null

	if Engine.get_physics_frames() % 60 == 0:
		print(
			"[AIComponent] state=%s aggression=%d can_see=%s dist=%.0f patrol=%s" % [
				State.keys()[current_state],
				aggression,
				can_see_target,
				distance_to_target,
				patrol,
			],
		)

	match current_state:
		State.IDLE:
			input.current_aim_direction = Vector2.ZERO
			input.current_is_firing = false
			_process_patrol(delta)
		State.CHASE:
			input.current_movement_direction = global_position.direction_to(target.global_position)
			input.current_aim_direction = input.current_movement_direction
			input.current_is_firing = false
		State.ATTACK:
			# Stay still and shoot
			input.current_movement_direction = Vector2.ZERO
			input.current_aim_direction = global_position.direction_to(target.global_position)
			input.current_is_firing = true


func _process_patrol(delta: float) -> void:
	if patrol == null:
		if Engine.get_physics_frames() % 60 == 0:
			print("[AIComponent] patrol is null!")
		input.current_movement_direction = Vector2.ZERO
		return

	patrol.process_wait(delta)
	var dir = patrol.get_patrol_direction(global_position)
	if Engine.get_physics_frames() % 60 == 0:
		print("[AIComponent] patrol dir=%s pos=%s" % [dir, global_position])
	input.current_movement_direction = dir
