extends GutTest


func _make_level_with_patrol_point() -> LevelData:
	var level := LevelData.new()
	var wp := WaypointData.new()
	wp.position = Vector2i(0, 0)
	wp.connections = PackedInt32Array([0])
	level.waypoints = [wp]
	return level


func _spawn_ai_rig() -> Dictionary:
	var actor := Node2D.new()
	actor.global_position = Vector2.ZERO
	add_child_autofree(actor)

	var input := AIInputComponent.new()
	actor.add_child(input)

	var patrol := WaypointPatrolComponent.new()
	patrol.level_data = _make_level_with_patrol_point()
	actor.add_child(patrol)

	var ai := AIComponent.new()
	ai.input = input
	ai.patrol = patrol
	ai.actor = actor
	actor.add_child(ai)

	var player := CharacterBody2D.new()
	player.add_to_group("player")
	player.global_position = Vector2(50, 0)
	add_child_autofree(player)

	ai.target = player
	if ai.get("_los_raycast"):
		(ai.get("_los_raycast") as RayCast2D).add_exception(player)

	return {
		"actor": actor,
		"input": input,
		"patrol": patrol,
		"ai": ai,
		"player": player,
	}


func test_passive_ai_stays_idle_and_uses_patrol_direction() -> void:
	var rig := _spawn_ai_rig()
	var ai := rig["ai"] as AIComponent
	var input := rig["input"] as AIInputComponent

	ai.aggression = 0
	ai._physics_process(0.016)

	assert_eq(ai.current_state, AIComponent.State.IDLE)
	assert_eq(input.current_is_firing, false)


func test_aggressive_ai_transitions_to_chase_and_attack() -> void:
	var rig := _spawn_ai_rig()
	var ai := rig["ai"] as AIComponent
	var input := rig["input"] as AIInputComponent
	var player := rig["player"] as CharacterBody2D

	ai.aggression = 10
	ai.attack_radius = 40.0
	ai.chase_radius = 120.0

	player.global_position = Vector2(80, 0) # chase range
	ai._physics_process(0.016)
	assert_eq(ai.current_state, AIComponent.State.CHASE)
	assert_false(input.current_is_firing)
	assert_ne(input.current_movement_direction, Vector2.ZERO)

	player.global_position = Vector2(10, 0) # attack range
	ai._physics_process(0.016)
	assert_eq(ai.current_state, AIComponent.State.ATTACK)
	assert_true(input.current_is_firing)


func test_idle_with_missing_patrol_falls_back_to_zero_movement() -> void:
	var rig := _spawn_ai_rig()
	var ai := rig["ai"] as AIComponent
	var input := rig["input"] as AIInputComponent

	ai.aggression = 0
	ai.patrol = null
	ai._physics_process(0.016)

	assert_eq(ai.current_state, AIComponent.State.IDLE)
	assert_eq(input.current_movement_direction, Vector2.ZERO)
