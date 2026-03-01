## Drives sprite frame based on energy ratio and time, mirroring
## AnimateInfluence() / AnimateEnemys() from the original C code.
class_name AnimationComponent
extends Sprite2D

## Animation speed multiplier (original uses 3.0).
@export var speed_scale := 3.0

var _phase := 0.0


## Advance the animation phase. Call every frame.
## `energy_ratio`: current energy / max energy, range [0..1].
func process_animation(delta: float, energy_ratio: float) -> void:
	_phase += energy_ratio * delta * hframes * speed_scale
	_phase = wrapf(_phase, 0.0, float(hframes))
	frame = int(_phase)
