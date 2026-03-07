extends CanvasLayer

class_name LiftUI

signal floor_selected(target_lift: LiftEntryData)
signal canceled()

const ELEVATORS_DATA := preload("res://data/converted/elevators.tres") as ElevatorData
const ShipOnTex := preload("res://assets/graphics/classic_theme/ship_on.png")
const ShipOffTex := preload("res://assets/graphics/classic_theme/ship_off.png")

@onready var bg_rect := $CenterContainer/Control/ShipBg as TextureRect
@onready var overlays_parent := $CenterContainer/Control/ShipBg/Overlays as Control
@onready var blink_timer := $BlinkTimer as Timer

var _reachable_lifts: Array[LiftEntryData] = []
var _selected_idx: int = 0
var _initial_selected_idx: int = 0
var _active_overlays: Array[TextureRect] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide()
	bg_rect.texture = ShipOffTex
	blink_timer.timeout.connect(_on_blink)


func open(start_lift_index: int) -> void:
	if start_lift_index < 0 or start_lift_index >= ELEVATORS_DATA.lifts.size():
		printerr("Invalid lift index: ", start_lift_index)
		return

	# Gather all reachable lifts in this column
	_reachable_lifts.clear()
	var current = ELEVATORS_DATA.lifts[start_lift_index]
	var head = current

	# Go all the way down
	while head.level_down != -1:
		head = ELEVATORS_DATA.lifts[head.level_down]

	# Now collect going up
	while head != null:
		_reachable_lifts.append(head)
		if head.level_up != -1:
			head = ELEVATORS_DATA.lifts[head.level_up]
		else:
			head = null

	# Find our starting index in the reachable list
	_selected_idx = 0
	for i in range(_reachable_lifts.size()):
		if _reachable_lifts[i] == current:
			_selected_idx = i
			break
	_initial_selected_idx = _selected_idx

	_build_overlays()

	get_tree().paused = true
	show()
	blink_timer.start(0.2)


func _build_overlays() -> void:
	for child in overlays_parent.get_children():
		child.queue_free()
	_active_overlays.clear()

	for i in range(_reachable_lifts.size()):
		var lift = _reachable_lifts[i]
		var deck_id = lift.deck
		if not ELEVATORS_DATA.deck_rects.has(deck_id):
			continue

		# In Godot 4, dictionary keys might be parsed as floats or ints
		var rects = ELEVATORS_DATA.deck_rects[deck_id]
		# Sometimes keys are auto-cast to string from JSON, but in tres they can be ints.
		# If it fails, we fall back to string lookup.
		if typeof(rects) == TYPE_NIL and ELEVATORS_DATA.deck_rects.has(str(deck_id)):
			rects = ELEVATORS_DATA.deck_rects[str(deck_id)]

		for r in rects:
			var rect = r as Rect2i
			var texture = TextureRect.new()
			var atlas = AtlasTexture.new()
			atlas.atlas = ShipOnTex
			atlas.region = rect
			texture.texture = atlas
			texture.position = rect.position

			overlays_parent.add_child(texture)
			# Store a reference to metadata so we know which deck this belongs to
			texture.set_meta("list_idx", i)
			_active_overlays.append(texture)

	_update_selection()


func _update_selection() -> void:
	# Make all visible, but later blink the selected one
	for texture in _active_overlays:
		texture.modulate.a = 1.0


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("move_up"):
		get_viewport().set_input_as_handled()
		if _selected_idx < _reachable_lifts.size() - 1:
			_selected_idx += 1
			_update_selection()
	elif event.is_action_pressed("move_down"):
		get_viewport().set_input_as_handled()
		if _selected_idx > 0:
			_selected_idx -= 1
			_update_selection()
	elif event.is_action_pressed("interact") or event.is_action_pressed("fire") \
	or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_confirm_selection()


func _on_blink() -> void:
	if not visible:
		return

	for texture in _active_overlays:
		if texture.get_meta("list_idx") == _selected_idx:
			texture.modulate.a = 1.0 if texture.modulate.a < 0.5 else 0.0
		else:
			texture.modulate.a = 1.0


func _confirm_selection() -> void:
	if _selected_idx == _initial_selected_idx:
		_cancel()
		return

	hide()
	blink_timer.stop()
	floor_selected.emit(_reachable_lifts[_selected_idx])


func _cancel() -> void:
	hide()
	blink_timer.stop()
	get_tree().paused = false
	canceled.emit()
