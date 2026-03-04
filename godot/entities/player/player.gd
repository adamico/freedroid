class_name Player
extends DroidEntity

func _init() -> void:
	if not droid_data:
		droid_data = preload("res://data/converted/droids/droid_001.tres")


func _ready() -> void:
	super._ready()
	if GlobalState:
		_detect_current_level()

		if health:
			GlobalState.update_player_energy(health.energy)
			health.energy_changed.connect(GlobalState.update_player_energy)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if GlobalState:
		var grid_pos = Vector2(int(global_position.x / 64), int(global_position.y / 64))
		GlobalState.update_player_pos(grid_pos)


func _detect_current_level() -> void:
	var root = get_tree().current_scene
	if root and root.name == "Main":
		for child in root.get_children():
			if child.name.begins_with("level_"):
				GlobalState.set_current_level(child.name)
				return
	elif root and root.name.begins_with("level_"):
		GlobalState.set_current_level(root.name)
		return

	var curr = self
	while is_instance_valid(curr):
		if curr.name.begins_with("level_"):
			GlobalState.set_current_level(curr.name)
			return
		curr = curr.get_parent()


func _on_died() -> void:
	print("Player has been destroyed!")
	super._on_died()
