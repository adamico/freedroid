extends GutTest

const ENEMY_SCENE := preload("res://entities/enemy/enemy.tscn")
const PLAYER_SCENE := preload("res://entities/player/player.tscn")
const GAME_CONSTANTS := preload("res://data/converted/game_constants.tres")


func _make_droid_data(droid_class: int, name_digits: String) -> DroidData:
	var data := DroidData.new()
	data.droid_class = droid_class
	data.maxspeed = 100
	data.accel = 500
	data.maxenergy = 60
	data.lose_health = 0
	data.droid_name = name_digits
	data.gun = 1
	return data


func _spawn_enemy(droid_class: int, position: Vector2) -> DroidEntity:
	var enemy := ENEMY_SCENE.instantiate() as DroidEntity
	enemy.droid_data = _make_droid_data(droid_class, str(droid_class).pad_zeros(3))
	add_child_autofree(enemy)
	enemy.global_position = position
	return enemy


func _spawn_player(droid_class: int, position: Vector2) -> Player:
	var player := PLAYER_SCENE.instantiate() as Player
	player.droid_data = _make_droid_data(droid_class, "001")
	add_child_autofree(player)
	player.global_position = position
	return player


func test_collision_damage_uses_class_diff_and_repeats_on_next_physics_frame() -> void:
	var weak := _spawn_player(1, Vector2.ZERO)
	var strong := _spawn_enemy(3, Vector2.ZERO)

	var first_expected_loss := 2 * GAME_CONSTANTS.collision_lose_energy_calibrator
	var before := weak.health.energy
	weak._handle_droid_collision(strong)
	assert_eq(weak.health.energy, before - first_expected_loss)

	# Same-frame repeat is ignored to avoid duplicate contact handling.
	weak._handle_droid_collision(strong)
	assert_eq(weak.health.energy, before - first_expected_loss)

	# Next physics frame should apply contact damage again (no long cooldown window).
	await get_tree().physics_frame
	weak._handle_droid_collision(strong)
	assert_eq(weak.health.energy, before - first_expected_loss * 2)


func test_enemy_enemy_collision_is_traffic_only_no_damage() -> void:
	var enemy_a := _spawn_enemy(1, Vector2.ZERO)
	var enemy_b := _spawn_enemy(3, Vector2.ZERO)

	var before_a := enemy_a.health.energy
	var before_b := enemy_b.health.energy

	enemy_a._handle_droid_collision(enemy_b)

	assert_eq(enemy_a.health.energy, before_a)
	assert_eq(enemy_b.health.energy, before_b)


func test_overlap_separation_pushes_bodies_apart() -> void:
	var enemy := _spawn_enemy(2, Vector2.ZERO)
	var player := _spawn_player(1, Vector2.ZERO)

	enemy._separate_from_droid(player, Vector2.RIGHT)

	var target_distance := enemy._get_body_radius() + player._get_body_radius() + enemy.player_collision_separation
	assert_true(enemy.global_position.distance_to(player.global_position) >= target_distance - 0.01)


func test_body_radius_uses_shared_legacy_constant() -> void:
	var enemy := _spawn_enemy(2, Vector2.ZERO)
	var player := _spawn_player(1, Vector2.ZERO)
	var expected := GAME_CONSTANTS.droid_radius * GameConstantsData.TILE_SIZE

	assert_eq(enemy._get_body_radius(), expected)
	assert_eq(player._get_body_radius(), expected)


func test_enemy_collision_pause_clears_ai_intent_after_player_contact() -> void:
	var enemy := _spawn_enemy(2, Vector2.ZERO)
	var ai := enemy.get_node("AIComponent") as AIComponent
	var input := enemy.get_node("AIInputComponent") as AIInputComponent

	input.current_movement_direction = Vector2.LEFT
	input.current_aim_direction = Vector2.UP
	input.current_is_firing = true

	enemy._pause_ai_after_player_collision()
	ai._physics_process(0.016)

	assert_eq(input.current_movement_direction, Vector2.ZERO)
	assert_eq(input.current_aim_direction, Vector2.ZERO)
	assert_false(input.current_is_firing)


func test_scene_level_enemy_player_contact_triggers_bump_path() -> void:
	var player := _spawn_player(2, Vector2(260, 200))
	var enemy := _spawn_enemy(2, Vector2(40, 200))
	var ai := enemy.get_node("AIComponent") as AIComponent

	ai.aggression = 10
	ai.attack_radius = 0.0
	ai.chase_radius = 1000.0
	ai.use_modern_chase_state = true

	await get_tree().physics_frame

	var collided := false
	for _step in 240:
		await get_tree().physics_frame
		if enemy._bump_cooldown > 0.0:
			collided = true
			break

	assert_true(collided, "Enemy should physically contact player and trigger droid collision handling")

	var min_distance := enemy._get_body_radius() + player._get_body_radius()
	assert_true(enemy.global_position.distance_to(player.global_position) >= min_distance - 0.5)
	assert_true(ai.get("_collision_pause_remaining") > 0.0)