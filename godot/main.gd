extends Node

# TODO: Move this to a LevelManager
const START_CONFIGS = [
	{ "level": 4, "x": 1, "y": 1 },
	{ "level": 5, "x": 3, "y": 1 },
	{ "level": 6, "x": 2, "y": 1 },
	{ "level": 7, "x": 2, "y": 1 },
]

var player_scene: PackedScene = preload("res://entities/player/player.tscn")


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

	var level_node := level_scene.instantiate()
	level_node.name = "level_%02d" % level_num
	add_child(level_node)

	# Add LevelSpawner to the level so it starts spawning droids
	var spawner := LevelSpawner.new()
	spawner.name = "LevelSpawner"
	level_node.add_child(spawner)

	# Instance player
	var player := player_scene.instantiate() as Node2D

	# Calculate player starting position
	var half := GameConstantsData.TILE_SIZE / 2.0
	var grid_pos := Vector2(start_config["x"], start_config["y"])
	var spawn_pos := grid_pos * GameConstantsData.TILE_SIZE + Vector2(half, half)

	player.global_position = spawn_pos
	level_node.add_child(player)

	# Update global state to ensure the HUD and other systems know the current state
	GlobalState.detect_current_level(player)
	GlobalState.update_player_pos(Vector2(start_config["x"], start_config["y"]))
