## All elevator/lift data for the ship.
class_name ElevatorData
extends Resource

@export var area_name: String = ""
@export var lifts: Array[LiftEntryData] = []
## Elevator column rectangles: Array of Rect2i (x, y, w, h).
@export var elevator_rects: Array[Rect2i] = []
## Deck rectangles grouped by deck number.
## Outer key = deck number, inner array = list of Rect2i.
@export var deck_rects: Dictionary = { }
