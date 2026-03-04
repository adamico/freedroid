class_name Enemy
extends DroidEntity

func _on_died() -> void:
	print("Enemy has been destroyed!")
	if GlobalState:
		GlobalState.increment_enemies_killed()
	super._on_died()
