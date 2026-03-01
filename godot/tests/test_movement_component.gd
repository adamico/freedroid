extends GutTest

var _movement: MovementComponent


func before_each() -> void:
	_movement = MovementComponent.new()
	_movement.max_speed = 5.0
	_movement.acceleration = 10.0
	_movement.friction = 7.0
	add_child(_movement)


func after_each() -> void:
	_movement.queue_free()


func test_initial_velocity_is_zero() -> void:
	assert_eq(_movement.velocity, Vector2.ZERO)


func test_apply_input_increases_velocity() -> void:
	_movement.apply_input(Vector2.RIGHT, 0.5)
	assert_gt(_movement.velocity.x, 0.0)
	assert_eq(_movement.velocity.y, 0.0)


func test_apply_input_diagonal() -> void:
	var dir := Vector2(1, 1).normalized()
	_movement.apply_input(dir, 0.5)
	assert_gt(_movement.velocity.x, 0.0)
	assert_gt(_movement.velocity.y, 0.0)


func test_clamp_speed_limits_velocity() -> void:
	_movement.velocity = Vector2(1000.0, -1000.0)
	_movement.clamp_speed()
	assert_eq(_movement.velocity.x, 300.0) # 5.0 * 60.0
	assert_eq(_movement.velocity.y, -300.0)


func test_friction_reduces_velocity_to_zero() -> void:
	_movement.velocity = Vector2(1.0, 0.0)
	# Apply friction with no active input, enough delta to stop
	_movement.apply_friction(Vector2.ZERO, 10.0)
	assert_eq(_movement.velocity.x, 0.0)


func test_friction_only_affects_inactive_axes() -> void:
	_movement.velocity = Vector2(3.0, 3.0)
	# Active input on X, no input on Y
	_movement.apply_friction(Vector2(1, 0), 10.0)
	# X should be unchanged, Y should be zeroed
	assert_eq(_movement.velocity.x, 3.0)
	assert_eq(_movement.velocity.y, 0.0)


func test_get_velocity_returns_current() -> void:
	_movement.velocity = Vector2(2.0, 3.0)
	assert_eq(_movement.get_velocity(), Vector2(2.0, 3.0))
