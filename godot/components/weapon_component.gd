## Handles weapon cooldown logic and emits a signal when a shot is fired.
## The parent entity or a bullet manager listens for `fired` to spawn projectiles.
class_name WeaponComponent
extends Node

## Emitted when a bullet is successfully fired.
## Listeners should spawn the actual projectile scene.
signal fired(bullet_data: BulletData, position: Vector2, direction: Vector2)

## The bullet type this weapon fires. Determines damage, speed, blast type.
@export var bullet_data: BulletData
## Cooldown override in seconds. If <= 0, uses bullet_data.recharging_time.
@export var cooldown_override := -1.0

## Internal cooldown timer (counts down to 0).
var _cooldown_remaining := 0.0


func _process(delta: float) -> void:
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)


## Returns the effective cooldown duration.
func _get_cooldown() -> float:
	if cooldown_override > 0.0:
		return cooldown_override
	if bullet_data:
		return bullet_data.recharging_time
	return 0.5 # fallback


## Returns true if the weapon can fire right now.
func can_fire() -> bool:
	return _cooldown_remaining <= 0.0 and bullet_data != null


## Attempt to fire. Returns true if the shot was taken.
## `position`: world position of the shooter.
## `direction`: normalized aim direction.
func try_fire(position: Vector2, direction: Vector2) -> bool:
	if not can_fire():
		return false
	_cooldown_remaining = _get_cooldown()
	fired.emit(bullet_data, position, direction.normalized())
	return true


## Manually reset the cooldown (useful for testing or power-ups).
func reset_cooldown() -> void:
	_cooldown_remaining = 0.0


## Returns the remaining cooldown time.
func get_cooldown_remaining() -> float:
	return _cooldown_remaining
