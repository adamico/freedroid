class_name Player
extends DroidEntity

func _init() -> void:
	if not droid_data:
		droid_data = preload("res://data/converted/droids/droid_001.tres")


func _ready() -> void:
	super._ready()
	if GlobalState:
		GlobalState.detect_current_level(self)

		if health:
			GlobalState.update_player_energy(health.energy)
			health.energy_changed.connect(GlobalState.update_player_energy)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if GlobalState:
		var grid_pos = Vector2(
			int(global_position.x / GameConstantsData.TILE_SIZE),
			int(global_position.y / GameConstantsData.TILE_SIZE),
		)
		GlobalState.update_player_pos(grid_pos)
