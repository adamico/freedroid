class_name Blast
extends Area2D

@export var data: BlastData
@export var hitbox: HitboxComponent
@export var animated_sprite: AnimatedSprite2D

const GameConstants = preload("res://data/converted/game_constants.tres")

enum BlastType {
	COSMETIC = 0,
	DAMAGING = 1,
}

var _blast_type: int = BlastType.COSMETIC

const BULLET_BLAST_TYPE := 0


func setup(type: int = 0) -> void:
	_blast_type = type


func _ready() -> void:
	var tex = preload("res://assets/sprites/blast.png")
	var frames = SpriteFrames.new()

	var anim_time: float
	if _blast_type == BlastType.COSMETIC:
		anim_time = GameConstants.blast_one_animation_time
	else:
		anim_time = GameConstants.blast_two_animation_time

	var fps = 6.0 / anim_time if anim_time > 0.0 else 12.0
	frames.set_animation_speed("default", fps)
	frames.set_animation_loop("default", false)

	var row_y = 0 if _blast_type == BlastType.COSMETIC else 66

	for i in range(6):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * 66, row_y, 64, 64)
		frames.add_frame("default", atlas)

	animated_sprite.sprite_frames = frames
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.play("default")

	if _blast_type == BlastType.COSMETIC:
		hitbox.monitoring = false
		hitbox.monitorable = false
		hitbox.damage = 0.0
	else:
		# Hits everything: player (layer 1) & enemies (layer 2)
		hitbox.collision_mask = 3
		# Total damage applied via Hitbox component on enter
		hitbox.damage = GameConstants.blast_damage_per_second * anim_time


func _on_animation_finished() -> void:
	queue_free()


func _physics_process(_delta: float) -> void:
	_clear_bullets_in_radius()


func _clear_bullets_in_radius() -> void:
	if not BulletManager:
		return

	var radius := _blast_radius()
	var radius_sq := radius * radius

	for child in BulletManager.get_children():
		if not (child is Bullet):
			continue

		var bullet := child as Bullet
		if not bullet.is_active():
			continue
		if bullet.is_flash_projectile():
			continue
		if global_position.distance_squared_to(bullet.global_position) >= radius_sq:
			continue

		bullet.deactivate()
		BulletManager.spawn_blast(bullet.global_position, BULLET_BLAST_TYPE)


func _blast_radius() -> float:
	var shape_node := hitbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node and shape_node.shape is CircleShape2D:
		return (shape_node.shape as CircleShape2D).radius
	return 32.0
