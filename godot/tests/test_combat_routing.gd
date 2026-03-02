extends GutTest

var enemy_scene = preload("res://entities/enemy/Enemy.tscn")
var bullet_scene = preload("res://entities/projectiles/Bullet.tscn")
var blast_scene = preload("res://entities/projectiles/Blast.tscn")

var enemy: Node
var bullet: Node
var blast: Node


func before_each():
	enemy = enemy_scene.instantiate()
	# Mock complete DroidData to bypass assertions and initialization
	var mock_data = DroidData.new()
	mock_data.maxspeed = 100
	mock_data.accel = 500
	mock_data.maxenergy = 50
	mock_data.lose_health = 0
	mock_data.droid_name = "123"
	enemy.droid_data = mock_data

	add_child_autofree(enemy)


func test_bullet_damages_enemy():
	bullet = bullet_scene.instantiate()
	var mock_bullet_data = BulletData.new()
	mock_bullet_data.damage = 15
	mock_bullet_data.speed = 0
	mock_bullet_data.range = 100
	bullet.data = mock_bullet_data

	add_child_autofree(bullet)

	# Manually trigger the collision since we're not running physics ticks
	# We simulate the bullet's hitbox intersecting the enemy's hurtbox
	var enemy_hurtbox = enemy.get_node("HurtboxComponent")
	var bullet_hitbox = bullet.get_node("HitboxComponent")

	bullet_hitbox._on_area_entered(enemy_hurtbox)

	# Enemy started with 50 health, took 15 damage -> should have 35 remaining
	var health_comp = enemy.get_node("HealthComponent")
	assert_eq(health_comp.energy, 35.0, "Enemy should have taken 15 damage from the bullet")


func test_blast_damages_enemy():
	blast = blast_scene.instantiate()
	var mock_blast_data = BlastData.new()
	mock_blast_data.damage = 25
	blast.data = mock_blast_data

	add_child_autofree(blast)

	var enemy_hurtbox = enemy.get_node("HurtboxComponent")
	var blast_hitbox = blast.get_node("HitboxComponent")

	blast_hitbox._on_area_entered(enemy_hurtbox)

	var health_comp = enemy.get_node("HealthComponent")
	assert_eq(health_comp.energy, 25.0, "Enemy should have taken 25 damage from the blast")
