## Translates AI intent from an AI brain into standard InputComponent queries.
class_name AIInputComponent
extends InputComponent

var current_movement_direction := Vector2.ZERO
var current_aim_direction := Vector2.ZERO
var current_is_firing := false


func get_movement_direction() -> Vector2:
	return current_movement_direction


func get_aim_direction() -> Vector2:
	return current_aim_direction


func is_firing() -> bool:
	return current_is_firing
