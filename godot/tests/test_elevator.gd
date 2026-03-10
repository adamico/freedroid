extends GutTest

const ELEVATOR_SCENE := preload("res://entities/elevator/elevator.tscn")
const PLAYER_SCENE := preload("res://entities/player/player.tscn")

var _elevator: Elevator
var _player: Player


func before_each() -> void:
	_elevator = ELEVATOR_SCENE.instantiate() as Elevator
	_elevator.lift_index = 7
	_elevator.global_position = Vector2.ZERO
	add_child_autofree(_elevator)

	_player = PLAYER_SCENE.instantiate() as Player
	_player.global_position = Vector2(32, 32) # Elevator tile centre when elevator is at (0, 0)
	_player.velocity = Vector2.ZERO
	add_child_autofree(_player)


func test_try_activate_blocks_when_player_moving_too_fast() -> void:
	watch_signals(_elevator)
	watch_signals(GlobalState)

	_player.velocity = Vector2(2.0, 0.0) # speed_sq = 4 > 1 threshold
	_elevator._try_activate(_player)

	assert_signal_not_emitted(_elevator, "elevator_activated")
	assert_signal_not_emitted(GlobalState, "elevator_requested")


func test_try_activate_blocks_when_player_not_near_tile_center() -> void:
	watch_signals(_elevator)
	watch_signals(GlobalState)

	_player.velocity = Vector2.ZERO
	_player.global_position = Vector2(80, 80) # too far from centre at (32, 32)
	_elevator._try_activate(_player)

	assert_signal_not_emitted(_elevator, "elevator_activated")
	assert_signal_not_emitted(GlobalState, "elevator_requested")


func test_try_activate_emits_expected_payload_to_elevator_and_global_state() -> void:
	watch_signals(_elevator)
	watch_signals(GlobalState)

	var elevator_payload := [-1]
	var global_payload := [-1]
	_elevator.elevator_activated.connect(func(idx: int): elevator_payload[0] = idx)
	GlobalState.elevator_requested.connect(func(idx: int): global_payload[0] = idx)

	_player.velocity = Vector2.ZERO
	_player.global_position = Vector2(32, 32)
	_elevator._try_activate(_player)

	assert_signal_emitted(_elevator, "elevator_activated")
	assert_signal_emitted(GlobalState, "elevator_requested")
	assert_eq(elevator_payload[0], 7)
	assert_eq(global_payload[0], 7)


func test_interact_only_activates_while_player_is_inside_trigger() -> void:
	var activations := [0]
	_elevator.elevator_activated.connect(func(_idx: int): activations[0] += 1)

	_player.velocity = Vector2.ZERO
	_player.global_position = Vector2(32, 32)

	_elevator._on_body_entered(_player)
	_player.input.interact_pressed.emit()
	assert_eq(activations[0], 1)

	_elevator._on_body_exited(_player)
	_player.input.interact_pressed.emit()
	assert_eq(activations[0], 1)
