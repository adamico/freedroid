extends SceneTree

func _initialize() -> void:
	var scn = load("res://entities/elevator/elevator.tscn")
	var inst = scn.instantiate()
	print("Script on Elevator: ", inst.get_script())
	if inst.get_script():
		print("Properties: ", inst.get_property_list().map(func(p): return p.name))
	quit()
