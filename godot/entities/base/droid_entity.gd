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
var _last_collision_damage_frame: int = -1
var _cached_body_radius: float = -1.0

## Fallback bump used when game constants do not provide a value.
@export var min_collision_bump_force: float = 72.0
## Small positional nudge to break persistent overlap with the player.
@export var player_collision_separation: float = 4.0
@export var debug_logs: bool = false


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
		if debug_logs:
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
	var effective_bump_force := maxf(GameConstants.bump_force, min_collision_bump_force)
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is DroidEntity:
			var other_droid := collider as DroidEntity
			if is_in_group("player") and other_droid.is_in_group("enemy"):
				continue
			_handle_droid_collision(other_droid)

			var away := global_position - other_droid.global_position
			if away.length_squared() > 0.0001:
				away = away.normalized()
			else:
				away = collision.get_normal()

			pushed_velocity += away * effective_bump_force
			if is_in_group("enemy") and other_droid.is_in_group("player"):
				_pause_ai_after_player_collision()
				_reverse_patrol_after_player_collision()
			_separate_from_droid(other_droid, away)

	movement.velocity = velocity + pushed_velocity

	if _bump_cooldown > 0.0:
		_bump_cooldown -= delta

	var energy_ratio := health.energy / health.max_energy if health.max_energy > 0.0 else 0.0
	animation.process_animation(delta, energy_ratio)


func _handle_droid_collision(other: DroidEntity) -> void:
	# Legacy parity: only player-enemy contact transfers collision damage.
	# Enemy-enemy body contact is traffic resolution only.
	if not (is_in_group("player") or other.is_in_group("player")):
		return

	if not other.droid_data or not self.droid_data:
		return

	# Legacy parity allows repeated contact damage over time; we only guard
	# against duplicate handling in the same physics frame.
	var frame := Engine.get_physics_frames()
	if _last_collision_damage_frame == frame:
		return
	_last_collision_damage_frame = frame
	_bump_cooldown = maxf(_bump_cooldown, 0.1)

	var class_diff = other.droid_data.droid_class - self.droid_data.droid_class
	if class_diff > 0:
		var dmg = class_diff * GameConstants.collision_lose_energy_calibrator
		health.take_damage(dmg)
	elif class_diff < 0:
		var dmg = -class_diff * GameConstants.collision_lose_energy_calibrator
		other.health.take_damage(dmg)


func _separate_from_droid(other: DroidEntity, fallback_away: Vector2) -> void:
	var delta := global_position - other.global_position
	var distance := delta.length()
	var min_distance := _get_body_radius() + other._get_body_radius()

	if distance >= min_distance:
		return

	var away := fallback_away
	if distance > 0.0001:
		away = delta / distance
	elif away.length_squared() > 0.0001:
		away = away.normalized()
	else:
		away = Vector2.RIGHT

	var overlap := (min_distance - distance) + player_collision_separation
	global_position += away * overlap


func _get_body_radius() -> float:
	if _cached_body_radius > 0.0:
		return _cached_body_radius

	var legacy_radius := GameConstants.droid_radius * GameConstantsData.TILE_SIZE
	if legacy_radius > 0.0:
		_cached_body_radius = legacy_radius
		return _cached_body_radius

	var body_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape and body_shape.shape is CircleShape2D:
		_cached_body_radius = (body_shape.shape as CircleShape2D).radius
	else:
		_cached_body_radius = 16.0

	return _cached_body_radius


func _pause_ai_after_player_collision() -> void:
	var ai := get_node_or_null("AIComponent") as AIComponent
	if ai:
		ai.pause_after_player_collision()


func _reverse_patrol_after_player_collision() -> void:
	var patrol := get_node_or_null("WaypointPatrolComponent") as WaypointPatrolComponent
	if not patrol:
		return

	var wait_duration := 0.5
	var ai := get_node_or_null("AIComponent") as AIComponent
	if ai:
		wait_duration = ai.collision_pause_duration

	patrol.reverse_course_after_collision(wait_duration)


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
