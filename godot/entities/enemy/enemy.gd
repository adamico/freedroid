class_name Enemy
extends DroidEntity

func _on_died() -> void:
	print("Enemy has been destroyed!")
	super._on_died()
