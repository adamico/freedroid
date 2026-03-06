## Manages energy (current HP) and health (max HP cap that degrades over time).
## Attach to any entity that can take damage or be healed.
class_name HealthComponent
extends Node

signal energy_changed(new_value: float)
signal died
signal healed(amount: float)
signal damaged(amount: float)

## Maximum energy the batteries can hold (from DroidData.maxenergy).
@export var max_energy: float = 100.0
## Rate at which health (the cap) permanently degrades per second.
## Mirrors DroidData.lose_health. Set to 0 to disable.
@export var lose_health_rate: float = 0.0

## The current max-energy cap. Decreases over time via lose_health_rate.
## Energy can never exceed this value.
var health: float
## Current energy level. Clamped to [0, health] via setter.
var energy: float:
	set(value):
		var old := energy
		energy = clampf(value, 0.0, health)
		if energy != old:
			energy_changed.emit(energy)
		if energy <= 0.0 and old > 0.0:
			died.emit()


func _ready() -> void:
	health = max_energy
	energy = max_energy


func take_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	energy -= amount
	damaged.emit(amount)


func heal(amount: float) -> void:
	if amount <= 0.0:
		return
	var old := energy
	energy += amount
	var actual := energy - old
	if actual > 0.0:
		healed.emit(actual)

## Whether this health component belongs to the player.
## If true, health permanently drains. If false, energy heals over time.
@export var is_player: bool = false


## Call every frame to apply the permanent health drain or energy heal.
## Mirrors original logic — player health cap shrinks, enemy energy heals.
func process_time_tick(delta: float) -> void:
	if lose_health_rate <= 0.0:
		return

	if is_player:
		health -= lose_health_rate * delta
		if energy > health:
			energy = health
	else:
		if energy < health:
			energy += lose_health_rate * delta


func is_alive() -> bool:
	return energy > 0.0
