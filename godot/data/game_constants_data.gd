## Global game constants extracted from freedroid.ruleset.
class_name GameConstantsData
extends Resource

## Size of a single map tile in pixels.
const TILE_SIZE := 64.0
## Maximum random wait time (seconds) at a waypoint before moving again.
const ENEMY_MAX_WAIT := 2.0

@export var alert_bonus_per_sec: float = 0.0
@export var alert_threshold: int = 0
@export var blast_damage_per_second: float = 0.0
@export var blast_one_animation_time: float = 0.0
@export var blast_radius: float = 0.0
@export var blast_two_animation_time: float = 0.0
@export var bump_force: float = 0.0
@export var collision_lose_energy_calibrator: float = 0.0
@export var deathcount_drain_speed: float = 0.0
@export var droid_radius: float = 0.0
@export var time_for_door_phase: float = 0.0
