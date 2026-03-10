extends GutTest

var _input: InputComponent


func before_each() -> void:
	_input = PlayerInputComponent.new()
	add_child_autofree(_input)


func after_each() -> void:
	_input.queue_free()

# -- Intention mapping tests --


func test_no_input_returns_zero_direction() -> void:
	assert_eq(
		_input.get_movement_direction(),
		Vector2.ZERO,
		"Direction should be zero with no input",
	)


func test_no_input_returns_not_firing() -> void:
	assert_false(_input.is_firing(), "Should not be firing with no input")


func test_interact_signal_exists() -> void:
	assert_has_signal(_input, "interact_pressed")


func test_interact_pressed_event_emits_signal() -> void:
	watch_signals(_input)
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	_input._unhandled_input(event)
	assert_signal_emitted(_input, "interact_pressed")


func test_interact_release_event_does_not_emit_signal() -> void:
	watch_signals(_input)
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = false
	_input._unhandled_input(event)
	assert_signal_not_emitted(_input, "interact_pressed")


func test_non_interact_press_does_not_emit_signal() -> void:
	watch_signals(_input)
	var event := InputEventAction.new()
	event.action = "fire"
	event.pressed = true
	_input._unhandled_input(event)
	assert_signal_not_emitted(_input, "interact_pressed")

# End of Intention mapping tests
