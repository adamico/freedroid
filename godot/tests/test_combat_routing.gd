extends GutTest

var enemy_scene = preload("res://entities/enemy/enemy.tscn")
var player_scene = preload("res://entities/player/player.tscn")
var bullet_scene = preload("res://entities/projectiles/bullet.tscn")
var blast_scene = preload("res://entities/projectiles/blast.tscn")

var enemy: Node
var bullet: Node
var blast: Node


func _make_enemy_data(gun_id: int = 1, flash_immune: bool = false) -> DroidData:
	var data := DroidData.new()
	data.maxspeed = 100
	data.accel = 500
	data.maxenergy = 50
	data.lose_health = 0
	data.droid_name = "123"
	data.gun = gun_id
	data.flashimmune = flash_immune
	return data


func _spawn_enemy(gun_id: int = 1, flash_immune: bool = false) -> DroidEntity:
	var e := enemy_scene.instantiate() as DroidEntity
	e.droid_data = _make_enemy_data(gun_id, flash_immune)
	add_child_autofree(e)
	return e


func before_each():
	enemy = _spawn_enemy()


func test_bullet_damages_enemy():
	bullet = bullet_scene.instantiate()
	var mock_bullet_data = BulletData.new()
	mock_bullet_data.damage = 15
	mock_bullet_data.speed = 0
	mock_bullet_data.range_dist = 100
	bullet.data = mock_bullet_data

	add_child_autofree(bullet)

	# Manually trigger the collision since we're not running physics ticks
	# We simulate the bullet's hitbox intersecting the enemy's hurtbox
	var enemy_hurtbox = enemy.get_node("HurtboxComponent")
	var bullet_hitbox = bullet.get_node("HitboxComponent")

	bullet_hitbox.area_entered.emit(enemy_hurtbox)

	# Enemy started with 50 health, took 15 damage -> should have 35 remaining
	var health_comp = enemy.get_node("HealthComponent")
	assert_eq(health_comp.energy, 35.0, "Enemy should have taken 15 damage from the bullet")


func test_blast_damages_enemy():
	blast = blast_scene.instantiate()
	blast.setup(1) # DAMAGING

	add_child_autofree(blast)

	var enemy_hurtbox = enemy.get_node("HurtboxComponent")
	var blast_hitbox = blast.get_node("HitboxComponent")

	blast_hitbox.area_entered.emit(enemy_hurtbox)

	var health_comp = enemy.get_node("HealthComponent")
	# DAMAGING blast does 60 DPS * 0.4s = 24 damage
	# 50 - 24 = 26
	assert_eq(health_comp.energy, 26.0, "Enemy should have taken 24 damage from the blast")


func test_flash_gun_damages_non_immune_enemy_without_spawning_bullet():
	assert_not_null(BulletManager, "BulletManager autoload must exist")

	var shooter := _spawn_enemy(3, true)
	var target := _spawn_enemy(1, false)
	shooter.global_position = Vector2(64, 64)
	target.global_position = Vector2(128, 64)

	var target_health := target.get_node("HealthComponent") as HealthComponent
	var bullets_before := BulletManager.get_child_count()

	var fired := shooter.weapon.try_fire(shooter.global_position, Vector2.RIGHT)
	assert_true(fired, "Flash shooter should fire when off cooldown")
	assert_eq(target_health.energy, 10.0, "Legacy flash should apply one-shot damage to vulnerable targets")
	assert_eq(BulletManager.get_child_count(), bullets_before, "Legacy flash path should not spawn a normal bullet")


func test_flash_gun_respects_flashimmune():
	var shooter := _spawn_enemy(3, true)
	var immune_target := _spawn_enemy(1, true)
	shooter.global_position = Vector2(64, 64)
	immune_target.global_position = Vector2(128, 64)

	var immune_health := immune_target.get_node("HealthComponent") as HealthComponent
	var before := immune_health.energy

	shooter.weapon.try_fire(shooter.global_position, Vector2.RIGHT)
	assert_eq(immune_health.energy, before, "Flash-immune droids should not take flash damage")


func test_flash_gun_can_damage_player_when_player_not_flashimmune():
	var shooter := _spawn_enemy(3, true)
	var player := player_scene.instantiate() as Player
	add_child_autofree(player)
	shooter.global_position = Vector2(64, 64)
	player.global_position = Vector2(128, 64)

	var player_health := player.get_node("HealthComponent") as HealthComponent
	var before := player_health.energy

	shooter.weapon.try_fire(shooter.global_position, Vector2.RIGHT)
	assert_lt(player_health.energy, before, "Player should take flash damage when not flash-immune")


func test_flash_gun_can_damage_non_immune_shooter():
	var shooter := _spawn_enemy(3, false)
	shooter.global_position = Vector2(64, 64)

	var shooter_health := shooter.get_node("HealthComponent") as HealthComponent
	var before := shooter_health.energy

	shooter.weapon.try_fire(shooter.global_position, Vector2.RIGHT)
	assert_eq(shooter_health.energy, before - 40.0, "Legacy flash applies to shooter unless shooter is flash-immune")
