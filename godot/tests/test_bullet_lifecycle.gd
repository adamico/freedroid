extends GutTest

const BULLET_SCENE := preload("res://entities/projectiles/bullet.tscn")


func _make_bullet_data(speed: float, range_dist: float) -> BulletData:
	var data := BulletData.new()
	data.damage = 10
	data.speed = speed
	data.range_dist = range_dist
	return data


func test_setup_switches_collision_mask_by_shooter_side() -> void:
	var bullet := BULLET_SCENE.instantiate() as Bullet
	bullet.data = _make_bullet_data(0.0, 0.0)
	add_child_autofree(bullet)

	bullet.setup(Vector2.RIGHT, 1, true)
	assert_eq(bullet.hitbox.collision_mask, 2, "Player bullet should target enemy layer")

	bullet.setup(Vector2.RIGHT, 1, false)
	assert_eq(bullet.hitbox.collision_mask, 3, "Enemy bullet should target player and enemy layers")


func test_animation_frame_progresses_during_physics_step() -> void:
	var bullet := BULLET_SCENE.instantiate() as Bullet
	bullet.data = _make_bullet_data(0.0, 0.0)
	add_child_autofree(bullet)
	bullet.setup(Vector2.RIGHT, 1, false)

	var initial_x := bullet.sprite.region_rect.position.x
	bullet._physics_process(0.06) # > 1/20 sec, enough to advance one frame
	var progressed_x := bullet.sprite.region_rect.position.x

	assert_gt(progressed_x, initial_x, "Bullet sprite frame should advance over time")


func test_range_expiry_queues_bullet_for_cleanup() -> void:
	var bullet := BULLET_SCENE.instantiate() as Bullet
	bullet.data = _make_bullet_data(10.0, 5.0)
	add_child_autofree(bullet)
	bullet.setup(Vector2.RIGHT, 1, false)

	bullet._physics_process(1.0)
	assert_true(bullet.is_queued_for_deletion(), "Bullet should queue_free once it exceeds range")
