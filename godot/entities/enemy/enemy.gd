class_name Enemy
extends CharacterBody2D

@export var droid_data: DroidData
@export var input: InputComponent
@export var bullet_scene: PackedScene

@onready var movement: MovementComponent = $MovementComponent
@onready var health: HealthComponent = $HealthComponent
@onready var animation: AnimationComponent = $AnimationComponent
@onready var digits: DigitDisplayComponent = $AnimationComponent/DigitDisplayComponent
@onready var weapon: WeaponComponent = $WeaponComponent


func _ready() -> void:
	assert(droid_data != null, "Enemy must have a DroidData resource assigned.")
	assert(bullet_scene != null, "Enemy must have a bullet_scene assigned.")

	movement.max_speed = droid_data.maxspeed
	movement.acceleration = droid_data.accel
	health.max_energy = droid_data.maxenergy
	health.lose_health_rate = droid_data.lose_health
	health.health = droid_data.maxenergy
	health.energy = droid_data.maxenergy

	health.died.connect(_on_died)
	weapon.fired.connect(_on_weapon_fired)

	var bullet_id := str(droid_data.gun).pad_zeros(3)
	var bullet_path := "res://data/converted/bullets/bullet_%s.tres" % bullet_id
	if ResourceLoader.exists(bullet_path):
		weapon.bullet_data = load(bullet_path)
	else:
		push_warning("Enemy: Could not find bullet data for gun ID: %s" % droid_data.gun)

	digits.set_digits(droid_data.droid_name)


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
	print("Enemy has been destroyed!")
	queue_free()


func _on_weapon_fired(bullet_data: BulletData, pos: Vector2, direction: Vector2) -> void:
	if not bullet_scene:
		push_warning("Enemy tried to fire but bullet_scene is null.")
		return
	# TODO: Create a BulletManager so entities don't spawn their own bullets onto the main scene tree directly
	# For now, just spawn it in the current level.
	print("Spawning bullet for Enemy at ", pos, " heading ", direction)
	var bullet := bullet_scene.instantiate() as Node2D
	bullet.data = bullet_data

	# Add to the same parent as the enemy (the level)
	get_parent().add_child(bullet)

	# Setting global position must happen *after* adding to tree if not top level,
	# but it's safe here.
	bullet.global_position = pos
	if bullet.has_method("setup"):
		bullet.setup(direction)
