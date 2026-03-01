class_name Enemy
extends CharacterBody2D

@export var droid_data: DroidData

@onready var ai: AIComponent = $AIComponent
@onready var movement: MovementComponent = $MovementComponent
@onready var health: HealthComponent = $HealthComponent
@onready var animation: AnimationComponent = $AnimationComponent
@onready var digits: DigitDisplayComponent = $AnimationComponent/DigitDisplayComponent
@onready var weapon: WeaponComponent = $WeaponComponent


func _ready() -> void:
	assert(droid_data != null, "Enemy must have a DroidData resource assigned.")

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

	var dir := Vector2.ZERO
	if ai and ai.has_method("get_movement_direction"):
		dir = ai.get_movement_direction()

	movement.apply_input(dir, delta)
	movement.apply_friction(dir, delta)
	movement.clamp_speed()

	if ai and ai.has_method("is_firing") and ai.is_firing() and dir != Vector2.ZERO:
		weapon.try_fire(global_position, dir)

	velocity = movement.velocity
	move_and_slide()
	movement.velocity = velocity

	var energy_ratio := health.energy / health.max_energy if health.max_energy > 0.0 else 0.0
	animation.process_animation(delta, energy_ratio)


func _on_died() -> void:
	print("Enemy has been destroyed!")
	queue_free()
