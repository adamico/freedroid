## Animated door that opens when the player enters its detection zone.
## Uses an AnimatableBody2D so it can block movement when closed.
## The door cycles through 5 tile phases (closed → open) at a configurable rate.
class_name Door
extends AnimatableBody2D

## 0 = horizontal, 1 = vertical
@export var orientation: int = 0
## Level color row index (0–6) from LevelData.color.
@export var color: int = 0
## Time per animation phase in seconds (from GameConstantsData.time_for_door_phase).
@export var phase_time: float = 0.3

const FRAME_SCALE := 60.0

enum DoorState { CLOSED, OPENING, OPEN, CLOSING }

var _state: DoorState = DoorState.CLOSED
## Current animation phase: 0 = fully closed, 4 = fully open.
var _phase: int = 0
var _timer: float = 0.0
var _bodies_inside: int = 0

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _detection: Area2D = $DetectionArea
@onready var _sprite: Sprite2D = $DoorSprite


func _ready() -> void:
	_detection.body_entered.connect(_on_detection_body_entered)
	_detection.body_exited.connect(_on_detection_body_exited)

	_sprite.texture = load("res://assets/tilesets/classic_map_blocks.png")
	_sprite.region_enabled = true
	_update_sprite_region()

	_set_blocked(true)


func _physics_process(delta: float) -> void:
	match _state:
		DoorState.OPENING:
			_timer += delta * FRAME_SCALE
			if _timer >= phase_time:
				_timer = 0.0
				_phase += 1
				if _phase >= 4:
					_phase = 4
					_state = DoorState.OPEN
					_set_blocked(false)
				_update_sprite_region()
		DoorState.CLOSING:
			_timer += delta * FRAME_SCALE
			if _timer >= phase_time:
				_timer = 0.0
				_phase -= 1
				if _phase <= 0:
					_phase = 0
					_state = DoorState.CLOSED
					_set_blocked(true)
				_update_sprite_region()


func _update_sprite_region() -> void:
	# From legacy defs.h:
	# Horizontal: H_ZUTUERE=18, H_HALBTUERE1=19, H_HALBTUERE2=20, H_HALBTUERE3=21, H_GANZTUERE=22
	# Vertical:   V_ZUTUERE=27, V_HALBTUERE1=28, V_HALBTUERE2=29, V_HALBTUERE3=30, V_GANZTUERE=31
	var base_index: int = 27 if orientation == 1 else 18
	var tile_idx: int = base_index + _phase

	# classic_map_blocks.png uses 64x64 tiles with 2px separation.
	var x_offset := tile_idx * (64 + 2)
	var y_offset := color * (64 + 2)
	_sprite.region_rect = Rect2(x_offset, y_offset, 64, 64)


func _on_detection_body_entered(body: Node2D) -> void:
	if body is Player:
		_bodies_inside += 1
		if _state == DoorState.CLOSED or _state == DoorState.CLOSING:
			_state = DoorState.OPENING
			_timer = 0.0


func _on_detection_body_exited(body: Node2D) -> void:
	if body is Player:
		_bodies_inside = maxi(_bodies_inside - 1, 0)
		if _bodies_inside == 0 and (_state == DoorState.OPEN or _state == DoorState.OPENING):
			_state = DoorState.CLOSING
			_timer = 0.0


func _set_blocked(blocked: bool) -> void:
	_collision.set_deferred("disabled", not blocked)
	set_collision_layer_value(1, blocked)


## Returns the current phase (0–4) for visual representation.
func get_phase() -> int:
	return _phase


## Returns the current state for testing.
func get_state() -> DoorState:
	return _state
