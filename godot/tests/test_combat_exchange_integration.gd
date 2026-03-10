extends GutTest

const ENEMY_SCENE := preload("res://entities/enemy/enemy.tscn")

var _enemy_a: DroidEntity
var _enemy_b: DroidEntity
var _pos_a := Vector2(80, 80)
var _pos_b := Vector2(200, 80)


func after_each() -> void:
	_clear_bullet_manager_children()


func _clear_bullet_manager_children() -> void:
	if not BulletManager:
		return
	for child in BulletManager.get_children():
		child.queue_free()
	await get_tree().process_frame


func _make_droid_data(name_digits: String) -> DroidData:
	var data := DroidData.new()
	data.maxspeed = 100
	data.accel = 500
	data.maxenergy = 50
	data.lose_health = 0
	data.droid_name = name_digits
	data.gun = 1
	return data


func _make_bullet_data(damage: int, cooldown: float) -> BulletData:
	var data := BulletData.new()
	data.damage = damage
	data.recharging_time = cooldown
	data.speed = 0.0
	data.range_dist = 100.0
	return data


func _spawn_enemy(pos: Vector2, digits: String) -> DroidEntity:
	var enemy := ENEMY_SCENE.instantiate() as DroidEntity
	enemy.droid_data = _make_droid_data(digits)
	add_child_autofree(enemy)
	enemy.global_position = pos
	enemy.weapon.spawn_offset = 0.0
	return enemy


func test_multi_entity_chained_combat_exchanges_over_time() -> void:
	assert_not_null(BulletManager, "BulletManager autoload must exist for this integration test")

	_enemy_a = _spawn_enemy(_pos_a, "111")
	_enemy_b = _spawn_enemy(_pos_b, "222")

	_enemy_a.weapon.bullet_data = _make_bullet_data(20, 0.1)
	_enemy_b.weapon.bullet_data = _make_bullet_data(5, 0.1)

	var input_a := _enemy_a.get_node("AIInputComponent") as AIInputComponent
	var input_b := _enemy_b.get_node("AIInputComponent") as AIInputComponent

	var hurtbox_a := _enemy_a.get_node("HurtboxComponent") as HurtboxComponent
	var hurtbox_b := _enemy_b.get_node("HurtboxComponent") as HurtboxComponent

	var hits_on_a := 0
	var hits_on_b := 0

	for exchange_idx in 3:
		var bullets_before := BulletManager.get_child_count()

		input_a.current_is_firing = true
		input_a.current_aim_direction = Vector2.RIGHT
		input_b.current_is_firing = true
		input_b.current_aim_direction = Vector2.LEFT

		_enemy_a.weapon._process(0.11)
		_enemy_b.weapon._process(0.11)

		_enemy_a._physics_process(0.11)
		_enemy_b._physics_process(0.11)

		var bullets_after := BulletManager.get_child_count()
		assert_eq(
			bullets_after,
			bullets_before + 2,
			"Each round should spawn one bullet per active enemy",
		)

		for child in BulletManager.get_children():
			if not (child is Bullet):
				continue
			var bullet := child as Bullet
			if bullet.is_queued_for_deletion():
				continue
			if bullet.global_position.distance_to(_pos_a) < 0.1:
				bullet.hitbox.area_entered.emit(hurtbox_b)
				hits_on_b += 1
			elif bullet.global_position.distance_to(_pos_b) < 0.1:
				bullet.hitbox.area_entered.emit(hurtbox_a)
				hits_on_a += 1

		await get_tree().process_frame

	assert_eq(hits_on_b, 3, "Enemy B should be hit three times in chained exchange")
	assert_eq(hits_on_a, 3, "Enemy A should be hit three times in chained exchange")

	assert_eq(_enemy_a.health.energy, 35.0, "Enemy A should lose 15 total energy over three rounds")

	await get_tree().process_frame
	assert_false(is_instance_valid(_enemy_b), "Enemy B should be freed after dying")
