## Thin host script for the player entity.
## Composes reusable components and drives move_and_slide for wall collisions.
## Reads intent from PlayerInputComponent and wires it to sibling components.
class_name Player
extends CharacterBody2D

@export var droid_data: DroidData
@export var input: InputComponent

@onready var movement: MovementComponent = $MovementComponent
@onready var health: HealthComponent = $HealthComponent
@onready var animation: AnimationComponent = $AnimationComponent
@onready var digits: DigitDisplayComponent = $AnimationComponent/DigitDisplayComponent
@onready var weapon: WeaponComponent = $WeaponComponent


func _ready() -> void:
	assert(droid_data != null, "Player must have a DroidData resource assigned.")

	movement.max_speed = droid_data.maxspeed
	movement.acceleration = droid_data.accel
	health.max_energy = droid_data.maxenergy
	health.lose_health_rate = droid_data.lose_health
	health.health = droid_data.maxenergy
	health.energy = droid_data.maxenergy

	health.died.connect(_on_died)

	digits.set_digits(droid_data.droid_name)


func _physics_process(delta: float) -> void:
	health.apply_permanent_drain(delta)

	# Read intent from input component and drive movement + weapon.
	var dir := input.get_movement_direction()
	movement.apply_input(dir, delta)
	movement.apply_friction(dir, delta)
	movement.clamp_speed()

	if input.is_firing() and dir != Vector2.ZERO:
		weapon.try_fire(global_position, dir)

	velocity = movement.velocity
	move_and_slide()
	# Write back the velocity after collisions so MovementComponent stays in sync.
	movement.velocity = velocity

	var energy_ratio := health.energy / health.max_energy if health.max_energy > 0.0 else 0.0
	animation.process_animation(delta, energy_ratio)


func _on_died() -> void:
	print("Player has been destroyed!")
