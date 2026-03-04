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

var bullet_scene: PackedScene = preload("res://entities/projectiles/bullet.tscn")
var _gun_id: int = 0


## Set up weapon with a specific gun ID. If gun_id is 0, the weapon is considered unequipped.
func setup(gun_id: int) -> void:
	_gun_id = gun_id
	if gun_id == 0:
		return

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
	if not bullet_scene:
		push_warning(name, " tried to fire but bullet_scene is null.")
		return

	# TODO: Create a BulletManager so entities don't spawn their own bullets
	#onto the main scene tree directly
	# For now, just spawn it in the current level.
	var entity = get_parent()
	print("Spawning bullet for ", entity.name, " at ", pos, " heading ", direction)
	var bullet := bullet_scene.instantiate() as Node2D
	bullet.data = bullet_data

	# Add to the same parent as the entity (the level)
	entity.get_parent().add_child(bullet)

	# Setting global position must happen *after* adding to tree if not top level,
	# but it's safe here.
	bullet.global_position = pos + direction * spawn_offset
	if bullet.has_method("setup"):
		bullet.setup(direction, _gun_id, entity.is_in_group("player"))


## Manually reset the cooldown (useful for testing or power-ups).
func reset_cooldown() -> void:
	_cooldown_remaining = 0.0


## Returns the remaining cooldown time.
func get_cooldown_remaining() -> float:
	return _cooldown_remaining
