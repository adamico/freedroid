extends GutTest

const PLAYER_SCENE := preload("res://entities/player/player.tscn")

var _player: Player


func before_each() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	_player.global_position = Vector2(64, 64)
	add_child_autofree(_player)


func after_each() -> void:
	Input.action_release("move_right")


func test_player_scene_movement_updates_component_and_body_velocity() -> void:
	var start_pos := _player.global_position
	Input.action_press("move_right")

	_player._physics_process(1.0 / 60.0)

	assert_gt(_player.movement.velocity.x, 0.0)
	assert_eq(_player.velocity.x, _player.movement.velocity.x)
	assert_gt(_player.global_position.x, start_pos.x)
