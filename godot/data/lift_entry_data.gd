## A single lift/elevator entrance.
class_name LiftEntryData
extends Resource

@export var label: int = 0
@export var deck: int = 0
@export var position: Vector2i = Vector2i.ZERO
@export var level_up: int = -1 ## Index into lifts array, -1 = none
@export var level_down: int = -1 ## Index into lifts array, -1 = none
@export var lift_row: int = 0
