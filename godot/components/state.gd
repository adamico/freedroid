## Base class for states used by StateMachineComponent.
## Override the virtual methods to define per-state behaviour.
class_name State
extends Node

## Reference to the owning state machine. Set automatically.
var state_machine: Node


## Called when this state becomes active.
func enter() -> void:
	pass


## Called when this state is being replaced by another.
func exit() -> void:
	pass


## Called every frame while this state is active.
func process(_delta: float) -> void:
	pass


## Called every physics frame while this state is active.
func physics_process(_delta: float) -> void:
	pass


## Called for unhandled input while this state is active.
func handle_input(_event: InputEvent) -> void:
	pass
