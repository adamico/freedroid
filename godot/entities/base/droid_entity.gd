class_name DroidEntity
extends CharacterBody2D

const BULLET_OFFSET := 32

@export var droid_data: DroidData

@onready var animation: AnimationComponent = $AnimationComponent
@onready var digits: DigitDisplayComponent = $AnimationComponent/DigitDisplayComponent
@onready var health: HealthComponent = $HealthComponent
@onready var movement: MovementComponent = $MovementComponent
@onready var weapon: WeaponComponent = $WeaponComponent

var input: InputComponent
var bullet_data: BulletData
var bullet_scene: PackedScene = preload("res://entities/projectiles/bullet.tscn")


func _ready() -> void:
	# Resolve input component dynamically from children if one exists
	for child in get_children():
		if child is InputComponent:
			input = child as InputComponent
			break

	assert(droid_data != null, "DroidEntity must have a DroidData resource assigned.")

	digits.set_digits(droid_data.droid_name)

	movement.max_speed = droid_data.maxspeed
	movement.acceleration = droid_data.accel
	health.max_energy = droid_data.maxenergy
	health.lose_health_rate = droid_data.lose_health
	health.health = droid_data.maxenergy
	health.energy = droid_data.maxenergy

	# REFACTOR: don't run this block if the droid has no weapon
	# or better, move this logic to the weapon component?
	var bullet_id := str(droid_data.gun).pad_zeros(3)
	var bullet_path := "res://data/converted/bullets/bullet_%s.tres" % bullet_id
	if ResourceLoader.exists(bullet_path):
		bullet_data = load(bullet_path)
	else:
		push_warning("DroidEntity: Could not find bullet data for gun ID: %s" % droid_data.gun)
	weapon.bullet_data = bullet_data
	weapon.fired.connect(_on_weapon_fired)

	health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	health.apply_permanent_drain(delta)

	var dir := Vector2.ZERO
	var aim_dir := Vector2.ZERO
	if input:
		dir = input.get_movement_direction()
		aim_dir = input.get_aim_direction()

	movement.apply_input(dir, delta)
	movement.apply_friction(dir, delta)
	movement.clamp_speed()

	if input and input.is_firing() and aim_dir != Vector2.ZERO:
		weapon.try_fire(global_position, aim_dir)

	velocity = movement.velocity
	move_and_slide()
	movement.velocity = velocity

	var energy_ratio := health.energy / health.max_energy if health.max_energy > 0.0 else 0.0
	animation.process_animation(delta, energy_ratio)


func _on_died() -> void:
	push_error("DroidEntity _on_died() must be implemented by subclasses.")


func _on_weapon_fired(bul_data: BulletData, pos: Vector2, direction: Vector2) -> void:
	if not bullet_scene:
		push_warning(name, " tried to fire but bullet_scene is null.")
		return
	# TODO: Create a BulletManager so entities don't spawn their own bullets
	#onto the main scene tree directly
	# For now, just spawn it in the current level.
	print("Spawning bullet for ", name, " at ", pos, " heading ", direction)
	var bullet := bullet_scene.instantiate() as Node2D
	bullet.data = bul_data

	# Add to the same parent as the entity (the level)
	get_parent().add_child(bullet)

	# Setting global position must happen *after* adding to tree if not top level,
	# but it's safe here.
	bullet.global_position = pos + direction * BULLET_OFFSET
	if bullet.has_method("setup"):
		bullet.setup(direction)
