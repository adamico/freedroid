## Drives sprite frame based on energy ratio and time, mirroring
## AnimateInfluence() / AnimateEnemys() from the original C code.
class_name AnimationComponent
extends Sprite2D

## Animation speed multiplier (original uses 3.0).
@export var speed_scale := 3.0

## Slicing variables to replace hframes/vframes when margins are involved
@export var sprite_size := Vector2(64, 64)
@export var margin := Vector2(2, 2)
@export var frame_count := 8
@export var current_row := 0

var _phase := 0.0


func _ready() -> void:
	region_enabled = true


## Advance the animation phase. Call every frame.
## `energy_ratio`: current energy / max energy, range [0..1].
func process_animation(delta: float, energy_ratio: float) -> void:
	_phase += energy_ratio * delta * frame_count * speed_scale
	_phase = wrapf(_phase, 0.0, float(frame_count))

	var anim_frame = int(_phase)

	var target_x = anim_frame * (sprite_size.x + margin.x)
	var target_y = current_row * (sprite_size.y + margin.y)

	region_rect = Rect2(target_x, target_y, sprite_size.x, sprite_size.y)
