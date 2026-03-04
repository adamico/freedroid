extends Node

signal enemy_killed_updated(new_count: int)
signal player_energy_updated(new_energy: float)
signal player_pos_updated(new_pos: Vector2)
signal current_level_updated(new_level: String)

var enemies_killed: int = 0
var player_energy: float = 0.0
var player_grid_pos: Vector2 = Vector2.ZERO
var current_level_name: String = "Unknown"


func increment_enemies_killed() -> void:
	enemies_killed += 1
	enemy_killed_updated.emit(enemies_killed)


func update_player_energy(energy: float) -> void:
	player_energy = energy
	player_energy_updated.emit(player_energy)


func update_player_pos(pos: Vector2) -> void:
	if player_grid_pos != pos:
		player_grid_pos = pos
		player_pos_updated.emit(player_grid_pos)


func set_current_level(level_name: String) -> void:
	if current_level_name != level_name:
		current_level_name = level_name
		current_level_updated.emit(current_level_name)
