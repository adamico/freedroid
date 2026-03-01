## Generic state machine. Add State nodes as children; one is active at a time.
## Maps to the original status field (MOBILE, WEAPON, TRANSFERMODE, etc.).
class_name StateMachineComponent
extends Node

## Path to the initial state child node.
@export var initial_state: State

signal state_changed(old_name: String, new_name: String)

var current_state: State


func _ready() -> void:
	for child in get_children():
		if child is State:
			child.state_machine = self
	if initial_state:
		current_state = initial_state
		current_state.enter()


func _process(delta: float) -> void:
	if current_state:
		current_state.process(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_process(delta)


func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)


## Transition to a different state by its node name.
func transition_to(state_name: String) -> void:
	var new_state: State = null
	for child in get_children():
		if child is State and child.name == state_name:
			new_state = child
			break
	if new_state == null:
		push_warning("StateMachineComponent: state '%s' not found." % state_name)
		return
	if new_state == current_state:
		return
	var old_name := ""
	if current_state:
		old_name = current_state.name
		current_state.exit()
	current_state = new_state
	current_state.enter()
	state_changed.emit(old_name, current_state.name)


## Returns the name of the currently active state.
func get_current_state_name() -> String:
	if current_state:
		return current_state.name
	return ""
