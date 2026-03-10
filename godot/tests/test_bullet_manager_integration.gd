extends GutTest

const ENEMY_SCENE := preload("res://entities/enemy/enemy.tscn")
const PLAYER_SCENE := preload("res://entities/player/player.tscn")
const BLAST_SCENE := preload("res://entities/projectiles/blast.tscn")

var _enemy: Node
var _player: Node


func after_each() -> void:
	Input.action_release("fire")
	Input.action_release("move_right")
	_clear_bullet_manager_children()


func _clear_bullet_manager_children() -> void:
	if not BulletManager:
		return
	for child in BulletManager.get_children():
		child.queue_free()
	await get_tree().process_frame


func _spawned_bullets() -> Array:
	var bullets: Array = []
	if not BulletManager:
		return bullets
	for child in BulletManager.get_children():
		if child is Bullet:
			bullets.append(child)
	return bullets


func _spawned_blasts() -> Array:
	var blasts: Array = []
	if not BulletManager:
		return blasts
	for child in BulletManager.get_children():
		if child is Blast:
			blasts.append(child)
	return blasts


func _mock_bullet_data() -> BulletData:
	var data := BulletData.new()
	data.damage = 10
	data.speed = 0.0
	data.range_dist = 100.0
	return data


func _mock_enemy_data() -> DroidData:
	var data := DroidData.new()
	data.maxspeed = 100
	data.accel = 500
	data.maxenergy = 50
	data.lose_health = 0
	data.droid_name = "123"
	data.gun = 1
	return data


func test_enemy_scene_fire_spawns_bullet_with_expected_side_effects() -> void:
	assert_not_null(BulletManager, "BulletManager autoload must be present for this integration test")

	_enemy = ENEMY_SCENE.instantiate()
	_enemy.droid_data = _mock_enemy_data()
	add_child_autofree(_enemy)
	_enemy.global_position = Vector2(100, 80)

	var ai_input := _enemy.get_node("AIInputComponent") as AIInputComponent
	ai_input.current_is_firing = true
	ai_input.current_aim_direction = Vector2.RIGHT

	var initial_count := _spawned_bullets().size()
	_enemy._physics_process(1.0 / 60.0)

	var bullets := _spawned_bullets()
	assert_eq(bullets.size(), initial_count + 1, "Enemy fire should create one bullet in BulletManager")

	var bullet := bullets[bullets.size() - 1] as Bullet
	var expected_pos: Vector2 = _enemy.global_position + Vector2.RIGHT * _enemy.weapon.spawn_offset
	assert_almost_eq(bullet.global_position.x, expected_pos.x, 0.01)
	assert_almost_eq(bullet.global_position.y, expected_pos.y, 0.01)
	assert_eq(bullet.data, _enemy.weapon.bullet_data, "Spawned bullet should receive weapon bullet data")

	var bullet_hitbox := bullet.get_node("HitboxComponent") as HitboxComponent
	assert_eq(bullet_hitbox.collision_mask, 3, "Enemy-fired bullet should target player and enemy layers")

	_enemy._physics_process(1.0 / 60.0)
	assert_eq(_spawned_bullets().size(), initial_count + 1, "Cooldown should prevent immediate second spawn")


func test_player_scene_fire_spawns_bullet_with_player_mask() -> void:
	assert_not_null(BulletManager, "BulletManager autoload must be present for this integration test")

	_player = PLAYER_SCENE.instantiate()
	add_child_autofree(_player)
	_player.global_position = Vector2(48, 48)

	Input.action_press("move_right")
	Input.action_press("fire")

	var initial_count := _spawned_bullets().size()
	_player._physics_process(1.0 / 60.0)

	var bullets := _spawned_bullets()
	assert_eq(bullets.size(), initial_count + 1, "Player fire should create one bullet in BulletManager")

	var bullet := bullets[bullets.size() - 1] as Bullet
	var bullet_hitbox := bullet.get_node("HitboxComponent") as HitboxComponent
	assert_eq(bullet_hitbox.collision_mask, 2, "Player-fired bullet should target enemy layer")


func test_player_and_enemy_bullets_destroy_each_other_and_spawn_one_blast() -> void:
	assert_not_null(BulletManager, "BulletManager autoload must be present for this integration test")
	await _clear_bullet_manager_children()

	var data := _mock_bullet_data()
	BulletManager.spawn_bullet(data, Vector2(200, 200), Vector2.RIGHT, 0.0, 1, true)
	BulletManager.spawn_bullet(data, Vector2(207, 200), Vector2.LEFT, 0.0, 1, false)

	var bullets := _spawned_bullets()
	assert_eq(bullets.size(), 2, "Test setup should spawn two bullets")

	(bullets[0] as Bullet)._physics_process(1.0 / 60.0)
	await get_tree().process_frame

	assert_eq(_spawned_bullets().size(), 0, "Opposite-side bullets should mutually destroy on contact")
	assert_eq(_spawned_blasts().size(), 1, "Bullet-bullet collision should spawn exactly one blast")


func test_same_side_bullets_also_destroy_each_other() -> void:
	assert_not_null(BulletManager, "BulletManager autoload must be present for this integration test")
	await _clear_bullet_manager_children()

	var data := _mock_bullet_data()
	BulletManager.spawn_bullet(data, Vector2(240, 220), Vector2.RIGHT, 0.0, 1, true)
	BulletManager.spawn_bullet(data, Vector2(247, 220), Vector2.LEFT, 0.0, 1, true)

	var bullets := _spawned_bullets()
	assert_eq(bullets.size(), 2, "Test setup should spawn two same-side bullets")

	(bullets[0] as Bullet)._physics_process(1.0 / 60.0)
	await get_tree().process_frame

	assert_eq(_spawned_bullets().size(), 0, "Same-side bullets should also mutually destroy for legacy parity")
	assert_eq(_spawned_blasts().size(), 1, "Same-side bullet collision should spawn one blast")


func test_damaging_blast_destroys_bullet_and_spawns_bullet_blast() -> void:
	assert_not_null(BulletManager, "BulletManager autoload must be present for this integration test")
	await _clear_bullet_manager_children()

	var data := _mock_bullet_data()
	BulletManager.spawn_bullet(data, Vector2(320, 240), Vector2.RIGHT, 0.0, 1, true)

	var blast := BLAST_SCENE.instantiate() as Blast
	blast.setup(Blast.BlastType.DAMAGING)
	blast.global_position = Vector2(320, 240)
	add_child_autofree(blast)
	await get_tree().process_frame

	assert_eq(_spawned_bullets().size(), 1, "Test setup should start with one bullet")
	blast._physics_process(1.0 / 60.0)
	await get_tree().process_frame

	assert_eq(_spawned_bullets().size(), 0, "Damaging blast should clear bullets in blast radius")
	assert_eq(_spawned_blasts().size(), 1, "Blast-bullet collision should spawn one bullet blast")


func test_cosmetic_blast_also_destroys_bullet_for_legacy_parity() -> void:
	assert_not_null(BulletManager, "BulletManager autoload must be present for this integration test")
	await _clear_bullet_manager_children()

	var data := _mock_bullet_data()
	BulletManager.spawn_bullet(data, Vector2(360, 240), Vector2.RIGHT, 0.0, 1, true)

	var blast := BLAST_SCENE.instantiate() as Blast
	blast.setup(Blast.BlastType.COSMETIC)
	blast.global_position = Vector2(360, 240)
	add_child_autofree(blast)
	await get_tree().process_frame

	assert_eq(_spawned_bullets().size(), 1, "Test setup should start with one bullet")
	blast._physics_process(1.0 / 60.0)
	await get_tree().process_frame

	assert_eq(_spawned_bullets().size(), 0, "Cosmetic blast should also clear bullets in blast radius")
	assert_eq(_spawned_blasts().size(), 1, "Cosmetic blast collision should still spawn one bullet blast")
