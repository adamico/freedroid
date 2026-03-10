class_name Bullet
extends Area2D

const FRAME_RATE = 60.0

@export var data: BulletData
@export var movement: MovementComponent
@export var hitbox: HitboxComponent
@export var sprite: Sprite2D
@export var collision_shape: CollisionShape2D

var _direction := Vector2.ZERO
var _distance_traveled := 0.0

var _gun_id: int = 0
var _anim_timer: float = 0.0
var _anim_frame: int = 0
var _anim_frames_count: int = 4
var _anim_fps: float = 20.0
var _active := true
var _flash_time_alive := 0.0

const FLASH_GUN_ID := 3
const FLASH_DURATION := 0.1
const BULLET_COLLISION_BLAST_TYPE := 1

const BULLET_TYPES_CONFIG = {
	0: { "phases": 4, "fps": 20.0 },
	1: { "phases": 4, "fps": 20.0 },
	2: { "phases": 4, "fps": 20.0 },
	3: { "phases": 1, "fps": 1.0 },
	4: { "phases": 4, "fps": 20.0 },
	5: { "phases": 4, "fps": 20.0 },
}


func _ready() -> void:
	if not data:
		push_warning("Bullet spawned without BulletData!")
		return

	hitbox.damage = data.damage
	# Start with generic texture, then regions are applied
	sprite.texture = preload("res://assets/sprites/bullet.png")
	sprite.region_enabled = true
	_update_sprite_region()

	# Hit solid walls -> destroy
	body_entered.connect(_on_body_entered)
	# Hit an entity hurtbox -> destroy (damage is handled by HitboxComponent)
	hitbox.hit.connect(_on_hit)


func setup(direction: Vector2, gun_id: int = 0, shooter_is_player: bool = false) -> void:
	_direction = direction.normalized()
	rotation = _direction.angle() + PI / 2.0
	_gun_id = gun_id
	_flash_time_alive = 0.0

	if _gun_id == FLASH_GUN_ID:
		hitbox.monitoring = false
		hitbox.monitorable = false
		hitbox.damage = 0.0
		hitbox.collision_mask = 0
		monitoring = false
		monitorable = false
	elif shooter_is_player:
		hitbox.collision_mask = 2 # hits the enemy droid
	else:
		hitbox.collision_mask = (1 << 1 - 1) | (1 << 2 - 1) # hits the player and other enemy droids

	if BULLET_TYPES_CONFIG.has(_gun_id):
		_anim_frames_count = BULLET_TYPES_CONFIG[_gun_id].phases
		_anim_fps = BULLET_TYPES_CONFIG[_gun_id].fps
	else:
		_anim_frames_count = 4
		_anim_fps = 20.0
	_update_sprite_region()


func _update_sprite_region() -> void:
	var frame_width := 64
	var frame_height := 64
	var margin := 2
	var rx := _anim_frame * (frame_width + margin)
	var ry := _gun_id * (frame_height + margin)
	if sprite:
		sprite.region_rect = Rect2(rx, ry, frame_width, frame_height)


func _physics_process(delta: float) -> void:
	if not _active or not data:
		return

	if _gun_id == FLASH_GUN_ID:
		_flash_time_alive += delta
		if _flash_time_alive >= FLASH_DURATION:
			_deactivate()
		return

	# Move at constant speed directly
	var step = _direction * data.speed * delta * FRAME_RATE
	position += step
	_distance_traveled += step.length()
	_check_bullet_collision()

	if data.range_dist > 0.0 and _distance_traveled >= data.range_dist:
		_deactivate()
		return

	_anim_timer += delta
	var frame_time = 1.0 / _anim_fps if _anim_fps > 0 else 1.0
	if _anim_timer >= frame_time:
		_anim_timer -= frame_time
		_anim_frame = (_anim_frame + 1) % _anim_frames_count
		_update_sprite_region()


func _on_body_entered(_body: Node2D) -> void:
	if not _active:
		return
	if _gun_id == FLASH_GUN_ID:
		return
	# Ignore the shooter (assuming shooter doesn't have collision layer mask matching bullet)
	_spawn_blast()
	_deactivate()


func _spawn_blast() -> void:
	if BulletManager:
		BulletManager.spawn_blast(global_position, 0)
	else:
		push_warning("BulletManager not found!")


func _on_hit(_hurtbox: Area2D) -> void:
	if _gun_id == FLASH_GUN_ID:
		return
	_deactivate()


func _check_bullet_collision() -> void:
	if _gun_id == FLASH_GUN_ID:
		return
	if not BulletManager:
		return

	var other := _find_colliding_bullet()
	if not other:
		return
	if other._gun_id == FLASH_GUN_ID:
		return

	var blast_position := global_position.lerp(other.global_position, 0.5)
	_deactivate()
	other._deactivate()
	BulletManager.spawn_blast(blast_position, BULLET_COLLISION_BLAST_TYPE)


func _find_colliding_bullet() -> Bullet:
	for child in BulletManager.get_children():
		if child == self:
			continue
		if not (child is Bullet):
			continue

		var other := child as Bullet
		if not other._active or other.is_queued_for_deletion():
			continue

		var collision_distance := _collision_radius() + other._collision_radius()
		if global_position.distance_squared_to(other.global_position) <= collision_distance * collision_distance:
			return other

	return null


func _collision_radius() -> float:
	if collision_shape and collision_shape.shape is CircleShape2D:
		return (collision_shape.shape as CircleShape2D).radius
	return 4.0


func is_flash_projectile() -> bool:
	return _gun_id == FLASH_GUN_ID


func is_active() -> bool:
	return _active and not is_queued_for_deletion()


func deactivate() -> void:
	_deactivate()


func _deactivate() -> void:
	if not _active:
		return
	_active = false
	queue_free()
