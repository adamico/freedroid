## Console Area2D trigger. Emits a signal when the player activates it.
## The console menu UI will be implemented in a later phase.
class_name Console
extends Area2D

## Emitted when the player successfully activates this console.
signal console_activated

## Facing direction: 0=left, 1=right, 2=up, 3=down
## Matches KONSOLE_L / KONSOLE_R / KONSOLE_O / KONSOLE_U.
@export var facing: int = 0

## Speed threshold — player must be nearly stopped to use the console.
const SPEED_THRESHOLD := 1.0

var _player_inside: Player = null


func _ready() -> void:
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_inside = body
		_player_inside.input.interact_pressed.connect(_on_player_interacted)


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		if _player_inside:
			if _player_inside.input.interact_pressed.is_connected(_on_player_interacted):
				_player_inside.input.interact_pressed.disconnect(_on_player_interacted)
		_player_inside = null


func _on_player_interacted() -> void:
	if _player_inside:
		if _player_inside.velocity.length_squared() <= SPEED_THRESHOLD:
			print("[Console] Activated — facing=%d" % facing)
			console_activated.emit()
