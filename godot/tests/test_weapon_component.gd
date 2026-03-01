extends GutTest

var _weapon: WeaponComponent
var _bullet: BulletData


func before_each() -> void:
	_bullet = BulletData.new()
	_bullet.recharging_time = 0.5
	_bullet.speed = 8.0
	_bullet.damage = 10

	_weapon = WeaponComponent.new()
	_weapon.bullet_data = _bullet
	add_child(_weapon)


func after_each() -> void:
	_weapon.queue_free()


func test_can_fire_initially() -> void:
	assert_true(_weapon.can_fire())


func test_fire_emits_signal() -> void:
	watch_signals(_weapon)
	var result: bool = _weapon.try_fire(Vector2.ZERO, Vector2.RIGHT)
	assert_true(result)
	assert_signal_emitted(_weapon, "fired")


func test_cooldown_prevents_rapid_fire() -> void:
	_weapon.try_fire(Vector2.ZERO, Vector2.RIGHT)
	assert_false(_weapon.can_fire())
	var result: bool = _weapon.try_fire(Vector2.ZERO, Vector2.RIGHT)
	assert_false(result)


func test_can_fire_after_cooldown() -> void:
	_weapon.try_fire(Vector2.ZERO, Vector2.RIGHT)
	# Simulate time passing beyond the cooldown
	_weapon.reset_cooldown()
	assert_true(_weapon.can_fire())


func test_cannot_fire_without_bullet_data() -> void:
	_weapon.bullet_data = null
	assert_false(_weapon.can_fire())


func test_cooldown_override() -> void:
	_weapon.cooldown_override = 1.0
	_weapon.try_fire(Vector2.ZERO, Vector2.RIGHT)
	assert_almost_eq(_weapon.get_cooldown_remaining(), 1.0, 0.01)
