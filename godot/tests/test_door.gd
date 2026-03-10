extends GutTest

var _door: Door


func before_each() -> void:
	var door_scene = load("res://entities/door/door.tscn")
	_door = door_scene.instantiate()
	add_child_autofree(_door)


func after_each() -> void:
	_door.queue_free()


func test_initial_state_is_closed() -> void:
	assert_eq(_door.get_state(), Door.DoorState.CLOSED)
	assert_eq(_door.get_phase(), 0)


func test_door_starts_opening() -> void:
	var player := Player.new()
	_door.get_node("DetectionArea").body_entered.emit(player)
	assert_eq(_door.get_state(), Door.DoorState.OPENING)
	player.free()


func test_door_starts_closing_after_open() -> void:
	var player := Player.new()
	_door.set("_state", Door.DoorState.OPEN)
	_door.set("_bodies_inside", 1)
	_door.get_node("DetectionArea").body_exited.emit(player)
	assert_eq(_door.get_state(), Door.DoorState.CLOSING)
	player.free()


func test_opening_advances_phases() -> void:
	var player := Player.new()
	_door.get_node("DetectionArea").body_entered.emit(player)
	_door.phase_time = 0.01
	for i in 10:
		_door.call("_physics_process", 0.02)
	assert_eq(_door.get_phase(), 4)
	assert_eq(_door.get_state(), Door.DoorState.OPEN)
	player.free()


func test_closing_reduces_phases() -> void:
	_door.set("_state", Door.DoorState.OPEN)
	_door.set("_phase", 4)
	_door.phase_time = 0.01
	_door.set("_state", Door.DoorState.CLOSING)
	for i in 10:
		_door.call("_physics_process", 0.02)
	assert_eq(_door.get_phase(), 0)
	assert_eq(_door.get_state(), Door.DoorState.CLOSED)


func test_region_mapping_respects_orientation_and_color() -> void:
	_door.orientation = Door.Orientation.HORIZONTAL
	_door.set("_phase", 0)
	_door.set_color(2)
	var sprite := _door.get_node("DoorSprite") as Sprite2D
	assert_eq(sprite.region_rect.position.x, 18.0 * 66.0)
	assert_eq(sprite.region_rect.position.y, 2.0 * 66.0)

	_door.orientation = Door.Orientation.VERTICAL
	_door.call("_update_sprite_region")
	assert_eq(sprite.region_rect.position.x, 27.0 * 66.0)
	assert_eq(sprite.region_rect.position.y, 2.0 * 66.0)


func test_collision_layer_toggles_when_door_fully_opens_and_closes() -> void:
	_door.phase_time = 0.01
	_door.set("_state", Door.DoorState.OPENING)
	_door.set("_phase", 0)
	for i in 10:
		_door.call("_physics_process", 0.02)

	assert_eq(_door.get_state(), Door.DoorState.OPEN)
	assert_false(_door.get_collision_layer_value(1))

	_door.set("_state", Door.DoorState.CLOSING)
	for i in 10:
		_door.call("_physics_process", 0.02)

	assert_eq(_door.get_state(), Door.DoorState.CLOSED)
	assert_true(_door.get_collision_layer_value(1))
