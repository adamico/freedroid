extends GutTest

var _original_scene: Node
var _test_scene: Node


func before_each() -> void:
	_original_scene = get_tree().current_scene


func after_each() -> void:
	if is_instance_valid(_test_scene):
		_test_scene.queue_free()
		await get_tree().process_frame
	_test_scene = null
	if is_instance_valid(_original_scene):
		get_tree().current_scene = _original_scene


func _set_test_current_scene(scene: Node) -> void:
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	_test_scene = scene


func test_request_elevator_emits_payload() -> void:
	watch_signals(GlobalState)
	var payload := [-1]
	GlobalState.elevator_requested.connect(func(idx: int): payload[0] = idx)

	GlobalState.request_elevator(4)

	assert_signal_emitted(GlobalState, "elevator_requested")
	assert_eq(payload[0], 4)


func test_detect_current_level_from_main_child_level() -> void:
	watch_signals(GlobalState)
	var main := Node.new()
	main.name = "Main"
	var level := Node2D.new()
	level.name = "level_05"
	var probe := Node.new()
	level.add_child(probe)
	main.add_child(level)
	_set_test_current_scene(main)

	GlobalState.detect_current_level(probe)

	assert_eq(GlobalState.current_level_name, "level_05")
	assert_signal_emitted(GlobalState, "current_level_updated")


func test_detect_current_level_when_current_scene_is_level() -> void:
	var level := Node2D.new()
	level.name = "level_09"
	_set_test_current_scene(level)

	GlobalState.detect_current_level(level)

	assert_eq(GlobalState.current_level_name, "level_09")


func test_detect_current_level_from_ancestor_fallback() -> void:
	var scene := Node.new()
	scene.name = "Sandbox"
	var level := Node2D.new()
	level.name = "level_12"
	var branch := Node.new()
	var probe := Node.new()
	branch.add_child(probe)
	level.add_child(branch)
	scene.add_child(level)
	_set_test_current_scene(scene)

	GlobalState.detect_current_level(probe)

	assert_eq(GlobalState.current_level_name, "level_12")
