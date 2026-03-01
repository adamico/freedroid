extends GutTest

var _sm: StateMachineComponent
var _state_a: Node
var _state_b: Node


func before_each() -> void:
	_sm = StateMachineComponent.new()

	_state_a = State.new()
	_state_a.name = "Mobile"
	_state_b = State.new()
	_state_b.name = "Weapon"

	_sm.add_child(_state_a)
	_sm.add_child(_state_b)
	_sm.initial_state = _state_a

	add_child(_sm) # triggers _ready


func after_each() -> void:
	_sm.queue_free()


func test_starts_in_initial_state() -> void:
	assert_eq(_sm.get_current_state_name(), "Mobile")
	assert_eq(_sm.current_state, _state_a)


func test_transition_changes_state() -> void:
	_sm.transition_to("Weapon")
	assert_eq(_sm.get_current_state_name(), "Weapon")
	assert_eq(_sm.current_state, _state_b)


func test_transition_emits_signal() -> void:
	watch_signals(_sm)
	_sm.transition_to("Weapon")
	assert_signal_emitted(_sm, "state_changed")


func test_transition_to_same_state_does_nothing() -> void:
	watch_signals(_sm)
	_sm.transition_to("Mobile")
	assert_signal_not_emitted(_sm, "state_changed")


func test_transition_to_unknown_state_warns() -> void:
	# Should not crash, just warn
	_sm.transition_to("NonExistent")
	assert_eq(_sm.get_current_state_name(), "Mobile")


func test_all_children_have_state_machine_ref() -> void:
	assert_eq(_state_a.state_machine, _sm)
	assert_eq(_state_b.state_machine, _sm)
