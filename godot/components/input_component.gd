## Base class for providing movement and action intent to an entity.
## Can be overridden by PlayerInputComponent (reads hardware input) or
## AIInputComponent (simulates input for attract mode/enemies).
class_name InputComponent
extends Node

## Emitted when the player presses the interact action.
signal interact_pressed


## Virtual: Returns the current movement direction.
func get_movement_direction() -> Vector2:
	return Vector2.ZERO


## Virtual: Returns true if the fire action is intended.
func is_firing() -> bool:
	return false
