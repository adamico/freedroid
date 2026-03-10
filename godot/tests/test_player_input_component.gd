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

# End of Intention mapping tests
