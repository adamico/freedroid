## Damage-dealing collision area (for bullets, blasts, etc.).
## Place as a child of the projectile/blast node with a CollisionShape2D child.
## Monitors HurtboxComponent areas to register hits.
class_name HitboxComponent
extends Area2D

## Damage dealt on contact.
@export var damage := 10.0

## Emitted when this hitbox overlaps a HurtboxComponent.
signal hit(hurtbox: Area2D)


func _ready() -> void:
	monitoring = true
	monitorable = false
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent:
		hit.emit(area)
		area.receive_hit(self)
