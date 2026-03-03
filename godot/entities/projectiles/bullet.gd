class_name Bullet
extends Area2D

@export var data: BulletData
@export var movement: MovementComponent
@export var hitbox: HitboxComponent
@export var sprite: Sprite2D
@export var collision_shape: CollisionShape2D

var _direction := Vector2.ZERO
var _distance_traveled := 0.0


func _ready() -> void:
	if not data:
		push_warning("Bullet spawned without BulletData!")
		return

	hitbox.damage = data.damage
	if data.texture:
		sprite.texture = data.texture

	# Hit solid walls -> destroy
	body_entered.connect(_on_body_entered)
	# Hit an entity hurtbox -> destroy (damage is handled by HitboxComponent)
	hitbox.hit.connect(_on_hit)


func setup(direction: Vector2) -> void:
	_direction = direction.normalized()
	rotation = _direction.angle()


func _physics_process(delta: float) -> void:
	if not data:
		return

	# Move at constant speed directly
	var step = _direction * data.speed * delta
	position += step
	_distance_traveled += step.length()

	if _distance_traveled >= data.range_dist:
		queue_free()


func _on_body_entered(_body: Node2D) -> void:
	# Ignore the shooter (assuming shooter doesn't have collision layer mask matching bullet)
	queue_free()


func _on_hit(_hurtbox: Area2D) -> void:
	queue_free()
