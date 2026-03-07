extends Node

# TODO: Move this to a LevelManager
const START_CONFIGS = [
	{ "level": 4, "x": 1, "y": 1 },
	{ "level": 5, "x": 3, "y": 1 },
	{ "level": 6, "x": 2, "y": 1 },
	{ "level": 7, "x": 2, "y": 1 },
]

var player_scene: PackedScene = preload("res://entities/player/player.tscn")
var lift_ui_scene: PackedScene = preload("res://ui/lift_ui.tscn")

var current_level_node: Node
var lift_ui: LiftUI


func _ready() -> void:
	# Randomly select a starting configuration
	var start_config = START_CONFIGS[randi() % START_CONFIGS.size()]

	var level_num: int = start_config["level"]
	var level_path := "res://levels/level_%02d.tscn" % level_num

	# Load and instance the level
	var level_scene := load(level_path) as PackedScene
	if not level_scene:
		push_error("Failed to load starting level: ", level_path)
		return

	current_level_node = level_scene.instantiate()
	current_level_node.name = "level_%02d" % level_num
	add_child(current_level_node)

	# Add LevelSpawner to the level so it starts spawning droids
	var spawner := LevelSpawner.new()
	spawner.name = "LevelSpawner"
	current_level_node.add_child(spawner)

	# Instance player
	var player := player_scene.instantiate() as Node2D

	# Calculate player starting position
	var half := GameConstantsData.TILE_SIZE / 2.0
	var grid_pos := Vector2(start_config["x"], start_config["y"])
	var spawn_pos := grid_pos * GameConstantsData.TILE_SIZE + Vector2(half, half)

	player.global_position = spawn_pos
	current_level_node.add_child(player)

	# Update global state to ensure the HUD and other systems know the current state
	GlobalState.detect_current_level(player)
	GlobalState.update_player_pos(Vector2(start_config["x"], start_config["y"]))

	# Initialize Lift UI
	lift_ui = lift_ui_scene.instantiate()
	add_child(lift_ui)
	lift_ui.floor_selected.connect(_on_floor_selected)

	GlobalState.elevator_requested.connect(_on_elevator_requested)


func _on_elevator_requested(lift_index: int) -> void:
	lift_ui.open(lift_index)


func _on_floor_selected(target_lift: LiftEntryData) -> void:
	call_deferred("_change_level", target_lift)


func _change_level(target_lift: LiftEntryData) -> void:
	get_tree().paused = false

	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player = players[0]

	if player.get_parent():
		player.get_parent().remove_child(player)
	self.add_child(player)

	if is_instance_valid(current_level_node):
		current_level_node.queue_free()

	var level_path := "res://levels/level_%02d.tscn" % target_lift.deck
	var level_scene := load(level_path) as PackedScene
	if not level_scene:
		push_error("Failed to load level: ", level_path)
		return

	current_level_node = level_scene.instantiate()
	current_level_node.name = "level_%02d" % target_lift.deck
	add_child(current_level_node)
	move_child(current_level_node, 0)

	var spawner := LevelSpawner.new()
	spawner.name = "LevelSpawner"
	current_level_node.add_child(spawner)

	self.remove_child(player)
	current_level_node.add_child(player)

	var half := GameConstantsData.TILE_SIZE / 2.0
	var grid_pos := Vector2(target_lift.position.x, target_lift.position.y)
	var spawn_pos := grid_pos * GameConstantsData.TILE_SIZE + Vector2(half, half)
	player.global_position = spawn_pos

	GlobalState.detect_current_level(player)
	GlobalState.update_player_pos(grid_pos)
