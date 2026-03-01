## Computes velocity from directional input, applying acceleration, friction,
## and speed capping. The parent entity decides how to apply the velocity
## (move_and_slide for player, manual position update for enemies).
class_name MovementComponent
extends Node

## Maximum speed in units/sec (from DroidData.maxspeed).
@export var max_speed: float = 2.0
## Acceleration in units/sec² (from DroidData.accel).
@export var acceleration: float = 5.0
## Friction deceleration in units/sec² when no input is pressed.
## Original value: 7.0.
@export var friction: float = 7.0

## Current velocity vector. Read this to feed into move_and_slide() or
## apply as a manual position offset.
var velocity: Vector2 = Vector2.ZERO


## Accelerate in the given direction. Direction should be normalized or zero.
func apply_input(direction: Vector2, delta: float) -> void:
	velocity += direction * acceleration * delta


## Slow down on axes where no input is active.
## Call with the current input direction so we know which axes to decelerate.
func apply_friction(active_direction: Vector2, delta: float) -> void:
	if is_zero_approx(active_direction.x):
		var old_sign := signf(velocity.x)
		velocity.x -= old_sign * friction * delta
		if signf(velocity.x) != old_sign:
			velocity.x = 0.0

	if is_zero_approx(active_direction.y):
		var old_sign := signf(velocity.y)
		velocity.y -= old_sign * friction * delta
		if signf(velocity.y) != old_sign:
			velocity.y = 0.0


## Clamp velocity to max_speed on each axis independently
## (matches the original AdjustSpeed behaviour).
func clamp_speed() -> void:
	velocity.x = clampf(velocity.x, -max_speed, max_speed)
	velocity.y = clampf(velocity.y, -max_speed, max_speed)


## Convenience: returns current velocity vector.
func get_velocity() -> Vector2:
	return velocity
