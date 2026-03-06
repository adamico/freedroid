class_name DroidEntity
extends CharacterBody2D

const GameConstants := preload("res://data/converted/game_constants.tres")

signal entity_died

@export var droid_data: DroidData
@export var input: InputComponent

@onready var animation: AnimationComponent = $AnimationComponent
@onready var digits: DigitDisplayComponent = $AnimationComponent/DigitDisplayComponent
@onready var health: HealthComponent = $HealthComponent
@onready var movement: MovementComponent = $MovementComponent
@onready var weapon: WeaponComponent = $WeaponComponent

var _bump_cooldown: float = 0.0


func _ready() -> void:
	assert(droid_data != null, "DroidEntity must have a DroidData resource assigned.")

	digits.set_digits(droid_data.droid_name)

	movement.max_speed = droid_data.maxspeed
	movement.acceleration = droid_data.accel
	health.max_energy = droid_data.maxenergy
	health.lose_health_rate = droid_data.lose_health
	health.health = droid_data.maxenergy
	health.energy = droid_data.maxenergy

	weapon.setup(droid_data.gun)

	var ai := get_node_or_null("AIComponent") as AIComponent
	if ai:
		ai.aggression = droid_data.aggression

	var patrol := get_node_or_null("WaypointPatrolComponent") as WaypointPatrolComponent
	if patrol and patrol.level_data == null:
		patrol.level_data = _detect_level_data()
		print(
			"[DroidEntity] %s: patrol.level_data = %s (waypoints: %d)" % [
				droid_data.droid_name,
				patrol.level_data,
				patrol.level_data.waypoints.size() if patrol.level_data else 0,
			],
		)

	health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	health.process_time_tick(delta)
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

	var pushed_velocity := Vector2.ZERO
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is DroidEntity:
			var other_droid := collider as DroidEntity
			_handle_droid_collision(other_droid)
			pushed_velocity += collision.get_normal() * GameConstants.bump_force

	movement.velocity = velocity + pushed_velocity

	if _bump_cooldown > 0.0:
		_bump_cooldown -= delta

	var energy_ratio := health.energy / health.max_energy if health.max_energy > 0.0 else 0.0
	animation.process_animation(delta, energy_ratio)


func _handle_droid_collision(other: DroidEntity) -> void:
	if _bump_cooldown > 0.0:
		return
	_bump_cooldown = 0.5

	if not other.droid_data or not self.droid_data:
		return

	var class_diff = other.droid_data.droid_class - self.droid_data.droid_class
	if class_diff > 0:
		var dmg = class_diff * GameConstants.collision_lose_energy_calibrator
		health.take_damage(dmg)
	elif class_diff < 0:
		var dmg = -class_diff * GameConstants.collision_lose_energy_calibrator
		other.health.take_damage(dmg)


func _on_died() -> void:
	if BulletManager:
		BulletManager.spawn_blast(global_position, 1)
	else:
		push_warning("BulletManager not found!")
	if is_in_group("enemy") and GlobalState:
		GlobalState.increment_enemies_killed()
	entity_died.emit()
	queue_free()


func _detect_level_data() -> LevelData:
	var curr := get_parent()
	while is_instance_valid(curr):
		if curr.name.begins_with("level_"):
			var level_num := curr.name.substr(6).to_int()
			var path := "res://data/converted/levels/level_%02d.tres" % level_num
			if ResourceLoader.exists(path):
				return load(path) as LevelData
			return null
		curr = curr.get_parent()
	return null
