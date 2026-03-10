extends GutTest

var _health: HealthComponent


func before_each() -> void:
	_health = HealthComponent.new()
	_health.max_energy = 100.0
	_health.lose_health_rate = 0.0
	add_child_autofree(_health)
	# _ready sets health and energy to max_energy
	assert_not_null(_health)


func after_each() -> void:
	_health.queue_free()


func test_initial_energy_equals_max() -> void:
	assert_eq(_health.energy, 100.0)
	assert_eq(_health.health, 100.0)


func test_take_damage_reduces_energy() -> void:
	_health.take_damage(30.0)
	assert_eq(_health.energy, 70.0)


func test_take_damage_emits_signal() -> void:
	watch_signals(_health)
	_health.take_damage(10.0)
	assert_signal_emitted(_health, "damaged")
	assert_signal_emitted(_health, "energy_changed")


func test_take_damage_zero_does_nothing() -> void:
	watch_signals(_health)
	_health.take_damage(0.0)
	assert_eq(_health.energy, 100.0)
	assert_signal_not_emitted(_health, "damaged")


func test_die_when_energy_zero() -> void:
	watch_signals(_health)
	_health.take_damage(100.0)
	assert_eq(_health.energy, 0.0)
	assert_signal_emitted(_health, "died")
	assert_false(_health.is_alive())


func test_overkill_clamps_to_zero() -> void:
	_health.take_damage(999.0)
	assert_eq(_health.energy, 0.0)


func test_heal_restores_energy() -> void:
	_health.take_damage(50.0)
	_health.heal(20.0)
	assert_eq(_health.energy, 70.0)


func test_heal_clamps_to_health() -> void:
	_health.take_damage(10.0)
	_health.heal(999.0)
	assert_eq(_health.energy, _health.health)


func test_heal_emits_signal() -> void:
	_health.take_damage(50.0)
	watch_signals(_health)
	_health.heal(10.0)
	assert_signal_emitted(_health, "healed")
	assert_signal_emitted(_health, "energy_changed")


func test_permanent_drain_reduces_player_health() -> void:
	_health.is_player = true
	_health.lose_health_rate = 10.0
	_health.process_time_tick(1.0) # 1 second
	assert_eq(_health.health, 90.0)
	# energy should follow if it was above health
	assert_eq(_health.energy, 90.0)


func test_permanent_drain_heals_enemy_energy() -> void:
	_health.is_player = false
	_health.lose_health_rate = 10.0
	_health.energy = 50.0 # simulate some damage
	_health.process_time_tick(1.0) # 1 second
	assert_eq(_health.health, 100.0) # cap should not change
	assert_eq(_health.energy, 60.0) # energy should heal by 10


func test_permanent_drain_zero_rate_does_nothing() -> void:
	_health.lose_health_rate = 0.0
	_health.process_time_tick(1.0)
	assert_eq(_health.health, 100.0)
	assert_eq(_health.energy, 100.0)
