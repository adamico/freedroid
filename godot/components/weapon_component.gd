## Handles weapon cooldown logic and emits a signal when a shot is fired.
## The parent entity or a bullet manager listens for `fired` to spawn projectiles.
class_name WeaponComponent
extends Node

## Emitted when a bullet is successfully fired.
signal fired(bullet_data: BulletData, position: Vector2, direction: Vector2)

## The bullet type this weapon fires. Determines damage, speed, blast type.
@export var bullet_data: BulletData
## Cooldown override in seconds. If <= 0, uses bullet_data.recharging_time.
@export var cooldown_override := -1.0
## Distance from the shooter to spawn the bullet.
@export var spawn_offset: float = 32.0

## Internal cooldown timer (counts down to 0).
var _cooldown_remaining := 0.0

var _gun_id: int = 0


## Set up weapon with a specific gun ID.
func setup(gun_id: int) -> void:
	_gun_id = gun_id

	var bullet_id := str(gun_id).pad_zeros(3)
	var bullet_path := "res://data/converted/bullets/bullet_%s.tres" % bullet_id
	if ResourceLoader.exists(bullet_path):
		bullet_data = load(bullet_path)
	else:
		push_warning("WeaponComponent: Could not find bullet data for gun ID: %d" % gun_id)


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

	var dir_norm = direction.normalized()
	_spawn_bullet(position, dir_norm)

	fired.emit(bullet_data, position, dir_norm)
	return true


func _spawn_bullet(pos: Vector2, direction: Vector2) -> void:
	if BulletManager:
		BulletManager.spawn_bullet(
			bullet_data,
			pos,
			direction,
			spawn_offset,
			_gun_id,
			get_parent().is_in_group("player"),
		)
	else:
		push_warning("BulletManager not found!")


## Manually reset the cooldown (useful for testing or power-ups).
func reset_cooldown() -> void:
	_cooldown_remaining = 0.0


## Returns the remaining cooldown time.
func get_cooldown_remaining() -> float:
	return _cooldown_remaining
