extends CanvasLayer

@onready var grid_label = %GridPosLabel
@onready var level_label = %LevelIDLabel
@onready var energy_label = %EnergyLabel
@onready var killed_label = %KilledLabel


func _ready() -> void:
	if GlobalState:
		_connect_and_update(
			GlobalState.enemy_killed_updated,
			GlobalState.enemies_killed,
			func(c): _update_label(killed_label, "Killed: %d" % c)
		)
		_connect_and_update(
			GlobalState.player_energy_updated,
			GlobalState.player_energy,
			func(e): _update_label(energy_label, "Energy: %d" % int(e))
		)
		_connect_and_update(
			GlobalState.player_pos_updated,
			GlobalState.player_grid_pos,
			func(p): _update_label(grid_label, "Pos: %d, %d" % [int(p.x), int(p.y)])
		)
		_connect_and_update(
			GlobalState.current_level_updated,
			GlobalState.current_level_name,
			func(l): _update_label(level_label, "Level: %s" % l)
		)


func _connect_and_update(
		state_signal: Signal,
		initial_value: Variant,
		update_callback: Callable,
) -> void:
	state_signal.connect(update_callback)
	update_callback.call(initial_value)


func _update_label(label: Label, text: String) -> void:
	if label:
		label.text = text
