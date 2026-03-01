class_name Blast
extends Area2D

@export var data: BlastData
@export var hitbox: HitboxComponent
@export var animated_sprite: AnimatedSprite2D


func _ready() -> void:
	if not data:
		push_warning("Blast spawned without BlastData!")
		return

	hitbox.damage = data.damage

	# Connect to animation finished to destroy the blast
	animated_sprite.animation_finished.connect(_on_animation_finished)
	# Play the blast animation (assuming the frames are setup correctly in the AnimatedSprite2D)
	animated_sprite.play("default")


func _on_animation_finished() -> void:
	queue_free()
