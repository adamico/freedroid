## Thin host script for the player entity.
## Composes reusable components and drives move_and_slide for wall collisions.
## Reads intent from PlayerInputComponent and wires it to sibling components.
class_name Player
extends CharacterBody2D

@export var input: InputComponent

@onready var movement: MovementComponent = $MovementComponent
@onready var health: HealthComponent = $HealthComponent
@onready var animation: AnimationComponent = $AnimationComponent
@onready var digits: DigitDisplayComponent = $AnimationComponent/DigitDisplayComponent
@onready var weapon: WeaponComponent = $WeaponComponent

var bullet_scene: PackedScene = preload("res://entities/projectiles/bullet.tscn")
var droid_data: DroidData = preload("res://data/converted/droids/droid_001.tres")
var bullet_data: BulletData = preload("res://data/converted/bullets/bullet_001.tres")


func _ready() -> void:
	movement.max_speed = droid_data.maxspeed
	movement.acceleration = droid_data.accel

	health.max_energy = droid_data.maxenergy
	health.lose_health_rate = droid_data.lose_health
	health.health = droid_data.maxenergy
	health.energy = droid_data.maxenergy

	weapon.bullet_data = bullet_data

	digits.set_digits(droid_data.droid_name)

	health.died.connect(_on_died)
	weapon.fired.connect(_on_weapon_fired)


func _physics_process(delta: float) -> void:
	health.apply_permanent_drain(delta)

	# Read intent from input component and drive movement + weapon.
	var dir := input.get_movement_direction()
	var aim_dir := input.get_aim_direction()
	movement.apply_input(dir, delta)
	movement.apply_friction(dir, delta)
	movement.clamp_speed()

	if input.is_firing() and aim_dir != Vector2.ZERO:
		weapon.try_fire(global_position, aim_dir)

	velocity = movement.velocity
	move_and_slide()
	# Write back the velocity after collisions so MovementComponent stays in sync.
	movement.velocity = velocity

	var energy_ratio := health.energy / health.max_energy if health.max_energy > 0.0 else 0.0
	animation.process_animation(delta, energy_ratio)


func _on_died() -> void:
	print("Player has been destroyed!")


func _on_weapon_fired(bul_data: BulletData, pos: Vector2, direction: Vector2) -> void:
	if not bullet_scene:
		push_warning("Player tried to fire but bullet_scene is null.")
		return
	print("Spawning bullet for Player at ", pos, " heading ", direction)
	var bullet := bullet_scene.instantiate() as Node2D
	bullet.data = bul_data

	get_parent().add_child(bullet)

	bullet.global_position = pos
	if bullet.has_method("setup"):
		bullet.setup(direction)
