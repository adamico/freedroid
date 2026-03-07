extends SceneTree

func _init() -> void:
	var main_tscn = load("res://main.tscn") as PackedScene
	if main_tscn:
		print("main.tscn loaded successfully")
	else:
		print("Failed to load main.tscn")

	var ui_scene = load("res://ui/lift_ui.tscn") as PackedScene
	if ui_scene:
		print("lift_ui.tscn loaded successfully")
		var ui = ui_scene.instantiate()
		if ui:
			print("Instantiated LiftUI")
			ui.open(0)
			print("LiftUI opened lift 0")
	else:
		print("Failed to load lift_ui.tscn")

	quit()
