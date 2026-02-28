## Per-level droid spawning configuration.
class_name DroidSpawnData
extends Resource

@export var level_number: int = 0
@export var min_random_droids: int = 0
@export var max_random_droids: int = 0
## Allowed droid type names (e.g., "476", "999") for random spawning.
@export var allowed_droid_types: PackedStringArray = PackedStringArray()
## Special forces: fixed-position droids.
## Each entry is a Dictionary with keys: type (String), x (int), y (int), fixed (bool), marker (bool).
@export var special_forces: Array[Dictionary] = []
