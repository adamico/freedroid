extends Node

signal enemy_killed_updated(new_count: int)
signal player_energy_updated(new_energy: float)
signal player_pos_updated(new_pos: Vector2)
signal current_level_updated(new_level: String)
signal elevator_requested(lift_index: int)

var enemies_killed: int = 0
var player_energy: float = 0.0
var player_grid_pos: Vector2 = Vector2.ZERO
var current_level_name: String = "Unknown"


func request_elevator(lift_index: int) -> void:
	elevator_requested.emit(lift_index)


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


## Walk the scene tree from `from_node` to find and set the current level name.
func detect_current_level(from_node: Node) -> void:
	var root = from_node.get_tree().current_scene
	if root and root.name == "Main":
		for child in root.get_children():
			if child.name.begins_with("level_"):
				set_current_level(child.name)
				return
	elif root and root.name.begins_with("level_"):
		set_current_level(root.name)
		return

	var curr = from_node
	while is_instance_valid(curr):
		if curr.name.begins_with("level_"):
			set_current_level(curr.name)
			return
		curr = curr.get_parent()
