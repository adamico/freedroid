## Elevator Area2D trigger. Emits a signal when the player activates it.
## The level/game manager will handle the actual level transition later.
class_name Elevator
extends Area2D

## Emitted when the player successfully activates this elevator.
signal elevator_activated(lift_index: int)

## Index into the ElevatorData.lifts array. Set by the level generator.
@export var lift_index: int = -1

## Speed threshold — player must be nearly stopped to use the elevator.
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
		_try_activate(_player_inside)


## Try to activate — only succeeds if player is slow and near tile centre.
func _try_activate(player: Player) -> void:
	var speed_sq := player.velocity.length_squared()
	if speed_sq > SPEED_THRESHOLD:
		return

	# Check if the player is near the centre of this tile (within droid_radius).
	var centre := global_position + Vector2(32, 32)
	var offset := player.global_position - centre
	if offset.length_squared() > 19.0 * 19.0:
		return

	print("[Elevator] Activated — lift_index=%d" % lift_index)
	elevator_activated.emit(lift_index)
