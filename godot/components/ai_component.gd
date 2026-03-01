## Drives Enemy behavior by calculating movement direction and firing intent.
## Placed as a child of Enemy.
class_name AIComponent
extends Node2D

enum State {
	IDLE,
	CHASE,
	ATTACK,
	FLEE,
}

@export var current_state: AIComponent.State = State.IDLE

## The entity this AI is trying to attack/chase
var target: Node2D = null

## The distance at which the enemy will start chasing the target
@export var chase_radius := 300.0

## The distance at which the enemy will start attacking (firing)
@export var attack_radius := 150.0

var _movement_dir := Vector2.ZERO
var _is_firing := false


func _physics_process(_delta: float) -> void:
	pass
	if target == null:
		# TODO: Later we can add logic to acquire a new target (like the player)
		_movement_dir = Vector2.ZERO
		_is_firing = false
		return

	var distance_to_target := global_position.distance_to(target.global_position)

	if distance_to_target <= attack_radius:
		current_state = State.ATTACK
	elif distance_to_target <= chase_radius:
		current_state = State.CHASE
	else:
		current_state = State.IDLE

	match current_state:
		State.IDLE:
			_movement_dir = Vector2.ZERO
			_is_firing = false
		State.CHASE:
			_movement_dir = global_position.direction_to(target.global_position)
			_is_firing = false
		State.ATTACK:
			# Stay still and shoot, or slowly move towards them
			_movement_dir = Vector2.ZERO
			_is_firing = true


## Returns the desired movement direction (used by the host).
func get_movement_direction() -> Vector2:
	return _movement_dir


## Returns true if the AI wants to fire its weapon (used by the host).
func is_firing() -> bool:
	return _is_firing
