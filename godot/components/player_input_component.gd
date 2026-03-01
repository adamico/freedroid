## Reads hardware input actions and provides intent to the entity.
class_name PlayerInputComponent
extends InputComponent

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact_pressed.emit()


func get_movement_direction() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func is_firing() -> bool:
	return Input.is_action_pressed("fire")
