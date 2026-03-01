## Damageable collision area attached to entities that can be hurt.
## Place as a child of the droid/player with a CollisionShape2D child.
## Automatically routes damage to a sibling HealthComponent if present.
class_name HurtboxComponent
extends Area2D

## If true, incoming hits are ignored (e.g. invincibility frames).
@export var invincible := false

signal hurt(hitbox: HitboxComponent)

@export var health_component: HealthComponent


func _ready() -> void:
	# Hurtboxes are detected by hitboxes, not the other way around.
	monitoring = false
	monitorable = true


func receive_hit(hitbox: HitboxComponent) -> void:
	if invincible:
		return
	hurt.emit(hitbox)
	if health_component:
		health_component.take_damage(hitbox.damage)
