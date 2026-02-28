## Mission metadata from the .mission file.
class_name MissionData
extends Resource

@export var mission_name: String = ""
@export var ruleset_file: String = ""
@export var ship_file: String = ""
@export var lift_file: String = ""
@export var crew_file: String = ""
@export var start_comment: String = ""
@export var title_picture: String = ""
@export var title_song: String = ""
@export var end_title_song: String = ""
@export var end_title_text: String = ""
## Array of briefing text pages (each page is a String).
@export var briefing_pages: PackedStringArray = PackedStringArray()
## Possible start points. Each entry: { level: int, x: int, y: int }.
@export var start_points: Array[Dictionary] = []
