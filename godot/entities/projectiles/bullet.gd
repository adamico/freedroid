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

	if shooter_is_player:
		hitbox.collision_mask = 2 # hits the enemy droid
	else:
		hitbox.collision_mask = 1 # hits the player

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
	if not data:
		return

	# Move at constant speed directly
	var step = _direction * data.speed * delta * FRAME_RATE
	position += step
	_distance_traveled += step.length()

	if data.range_dist > 0.0 and _distance_traveled >= data.range_dist:
		queue_free()

	_anim_timer += delta
	var frame_time = 1.0 / _anim_fps if _anim_fps > 0 else 1.0
	if _anim_timer >= frame_time:
		_anim_timer -= frame_time
		_anim_frame = (_anim_frame + 1) % _anim_frames_count
		_update_sprite_region()


func _on_body_entered(_body: Node2D) -> void:
	# Ignore the shooter (assuming shooter doesn't have collision layer mask matching bullet)
	_spawn_blast()
	queue_free()


func _spawn_blast() -> void:
	if BulletManager:
		BulletManager.spawn_blast(global_position, 0)
	else:
		push_warning("BulletManager not found!")


func _on_hit(_hurtbox: Area2D) -> void:
	queue_free()
