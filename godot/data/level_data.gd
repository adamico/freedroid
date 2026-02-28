## Intermediate level data: semantic tile grid + waypoints.
## Phase 2 will consume this to build TileMapLayer scenes.
class_name LevelData
extends Resource

@export var level_number: int = 0
@export var level_name: String = ""
@export var xlen: int = 0
@export var ylen: int = 0
@export var color: int = 0
@export var enter_comment: String = ""
@export var background_song: String = ""
## Flat row-major grid of semantic tile IDs (see TileTypes).
## Length = xlen * ylen. Access: grid[y * xlen + x].
@export var grid: PackedInt32Array = PackedInt32Array()
@export var waypoints: Array[WaypointData] = []
