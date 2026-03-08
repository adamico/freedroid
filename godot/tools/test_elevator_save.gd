extends SceneTree

func _initialize() -> void:
	var scn = load("res://entities/elevator/elevator.tscn")
	var parent = Node.new()
	parent.name = "Root"

	var inst = scn.instantiate()
	parent.add_child(inst)
	inst.owner = parent

	inst.set("lift_index", 42)

	var packed = PackedScene.new()
	packed.pack(parent)
	ResourceSaver.save(packed, "res://tools/test_elevator_save.tscn")
	print("Saved to tools/test_elevator_save.tscn")
	quit()
