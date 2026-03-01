extends GutTest

var _door: Door


func before_each() -> void:
	_door = Door.new()

	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(64, 64)
	col.shape = shape
	_door.add_child(col)

	var detect := Area2D.new()
	detect.name = "DetectionArea"
	detect.monitoring = true
	detect.monitorable = false
	_door.add_child(detect)

	var detect_col := CollisionShape2D.new()
	var detect_shape := RectangleShape2D.new()
	detect_shape.size = Vector2(96, 96)
	detect_col.shape = detect_shape
	detect.add_child(detect_col)

	add_child(_door)


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
