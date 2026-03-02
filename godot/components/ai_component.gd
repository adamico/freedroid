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


func _ready() -> void:
	target = get_tree().get_first_node_in_group("player")


func _physics_process(_delta: float) -> void:
	if input == null:
		return

	if target == null:
		# TODO: Later we can add logic to acquire a new target (like the player)
		input.current_movement_direction = Vector2.ZERO
		input.current_is_firing = false
		return

	var distance_to_target := global_position.distance_to(target.global_position)

	var previous_state = current_state

	if distance_to_target <= attack_radius:
		current_state = State.ATTACK
	elif distance_to_target <= chase_radius:
		current_state = State.CHASE
	else:
		current_state = State.IDLE

	if current_state != previous_state:
		print(
			"AI State changed to: ",
			State.keys()[current_state],
			" Distance: ",
			distance_to_target,
		)

	match current_state:
		State.IDLE:
			input.current_movement_direction = Vector2.ZERO
			input.current_aim_direction = Vector2.ZERO
			input.current_is_firing = false
		State.CHASE:
			input.current_movement_direction = global_position.direction_to(target.global_position)
			input.current_aim_direction = input.current_movement_direction
			input.current_is_firing = false
		State.ATTACK:
			# Stay still and shoot, or slowly move towards them
			input.current_movement_direction = Vector2.ZERO
			input.current_aim_direction = global_position.direction_to(target.global_position)
			input.current_is_firing = true
			print("AI Attempting to Fire! Dir: ", input.current_aim_direction)
