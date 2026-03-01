## Displays 3 digits sliced from digits.png using a custom region based on classic dimensions.
class_name DigitDisplayComponent
extends Node2D

@export var digits_texture: Texture2D
@export var digit_size := Vector2(16, 18)
@export var margin := Vector2(2, 2)
@export var enemy_row := false

@onready var sprite1: Sprite2D = $Digit1
@onready var sprite2: Sprite2D = $Digit2
@onready var sprite3: Sprite2D = $Digit3


func _ready() -> void:
	if digits_texture:
		sprite1.texture = digits_texture
		sprite2.texture = digits_texture
		sprite3.texture = digits_texture


func set_digits(number_string: String) -> void:
	if not digits_texture:
		return

	# Pad with leading zeroes to always be length 3
	var padded = number_string.pad_zeros(3)
	if padded.length() > 3:
		padded = padded.right(3)

	_set_digit_sprite(sprite1, padded[0])
	_set_digit_sprite(sprite2, padded[1])
	_set_digit_sprite(sprite3, padded[2])


func _set_digit_sprite(sprite: Sprite2D, digit_char: String) -> void:
	if not digit_char.is_valid_int():
		sprite.visible = false
		return

	sprite.visible = true
	var digit_val = digit_char.to_int()

	sprite.region_enabled = true
	var row_offset = 1 if enemy_row else 0

	# digits.png layout: columns 0-9 for 0-9. Rows: 0=influencer, 1=enemy
	var target_x = digit_val * (digit_size.x + margin.x)
	var target_y = row_offset * (digit_size.y + margin.y)

	sprite.region_rect = Rect2(target_x, target_y, digit_size.x, digit_size.y)
