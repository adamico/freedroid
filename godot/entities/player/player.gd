class_name Player
extends DroidEntity

func _init() -> void:
	if not droid_data:
		droid_data = preload("res://data/converted/droids/droid_001.tres")


func _on_died() -> void:
	print("Player has been destroyed!")
