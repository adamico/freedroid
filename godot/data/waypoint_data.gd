## A single waypoint within a level.
class_name WaypointData
extends Resource

@export var position: Vector2i = Vector2i.ZERO
@export var connections: PackedInt32Array = PackedInt32Array()
