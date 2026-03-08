## A world entity placed over refresh tiles.
## Restores energy to any DroidEntity standing on it.
class_name Recharger
extends Area2D

const HEAL_RATE := 15.0

var _droids_inside: Array[DroidEntity] = []


func _ready() -> void:
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	# Iterate backwards to safely remove invalid entities if any get destroyed
	for i in range(_droids_inside.size() - 1, -1, -1):
		var droid = _droids_inside[i]
		if not is_instance_valid(droid):
			_droids_inside.remove_at(i)
			continue

		if droid.health and droid.health.energy < droid.health.health:
			droid.health.heal(HEAL_RATE * delta)


func _on_body_entered(body: Node2D) -> void:
	if body is DroidEntity:
		if body not in _droids_inside:
			_droids_inside.append(body)


func _on_body_exited(body: Node2D) -> void:
	if body is DroidEntity:
		_droids_inside.erase(body)
