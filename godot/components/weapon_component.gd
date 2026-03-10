## Handles weapon cooldown logic and emits a signal when a shot is fired.
## The parent entity or a bullet manager listens for `fired` to spawn projectiles.
class_name WeaponComponent
extends Node

signal fired(bullet_data: BulletData, position: Vector2, direction: Vector2)

@export var bullet_data: BulletData
@export var cooldown_override := -1.0
@export var spawn_offset: float = 32.0

var _cooldown_remaining := 0.0
var _gun_id: int = 0

const FLASH_GUN_ID := 3
const FLASH_RAYCAST_MASK := 1 | 4 # Hit walls and doors only.
const FLASH_DURATION := 0.1
const FLASH_OVERLAY_NAME := "LegacyFlashOverlay"


func setup(gun_id: int) -> void:
	_gun_id = gun_id

	var bullet_id := str(gun_id).pad_zeros(3)
	var bullet_path := "res://data/converted/bullets/bullet_%s.tres" % bullet_id
	if ResourceLoader.exists(bullet_path):
		bullet_data = load(bullet_path)
	else:
		push_warning("WeaponComponent: Could not find bullet data for gun ID: %d" % gun_id)


func _process(delta: float) -> void:
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)


func _get_cooldown() -> float:
	if cooldown_override > 0.0:
		return cooldown_override
	if bullet_data:
		return bullet_data.recharging_time
	return 0.5 # fallback


func can_fire() -> bool:
	return _cooldown_remaining <= 0.0 and bullet_data != null


func try_fire(position: Vector2, direction: Vector2) -> bool:
	if not can_fire():
		return false
	_cooldown_remaining = _get_cooldown()

	var dir_norm = direction.normalized()
	if _gun_id == FLASH_GUN_ID:
		_play_legacy_flash_visual()
		_apply_legacy_flash_damage(position)
	else:
		_spawn_bullet(position, dir_norm)

	fired.emit(bullet_data, position, dir_norm)
	return true


func _spawn_bullet(pos: Vector2, direction: Vector2) -> void:
	if BulletManager:
		BulletManager.spawn_bullet(
			bullet_data,
			pos,
			direction,
			spawn_offset,
			_gun_id,
			get_parent().is_in_group("player"),
		)
	else:
		push_warning("BulletManager not found!")


func _apply_legacy_flash_damage(origin: Vector2) -> void:
	if not bullet_data:
		return

	var shooter := get_parent() as Node
	var shooter_pos := origin
	if shooter is Node2D:
		shooter_pos = (shooter as Node2D).global_position

	for target in get_tree().get_nodes_in_group("enemy"):
		_apply_flash_damage_to_target(target, shooter, shooter_pos)

	var player := get_tree().get_first_node_in_group("player")
	if player:
		_apply_flash_damage_to_target(player, shooter, shooter_pos)


func _apply_flash_damage_to_target(target: Node, shooter: Node, shooter_pos: Vector2) -> void:
	if not (target is Node2D):
		return
	if not is_instance_valid(target):
		return
	if _is_target_flash_immune(target):
		return
	if not _is_same_level(shooter, target):
		return
	if not _has_line_of_sight(shooter_pos, (target as Node2D).global_position, shooter, target):
		return

	var hurtbox := target.get_node_or_null("HurtboxComponent") as HurtboxComponent
	if hurtbox == null or hurtbox.invincible:
		return
	if hurtbox.health_component:
		hurtbox.health_component.take_damage(bullet_data.damage)


func _is_target_flash_immune(target: Node) -> bool:
	if not (target is DroidEntity):
		return false
	var droid := target as DroidEntity
	return droid.droid_data != null and droid.droid_data.flashimmune


func _is_same_level(source: Node, target: Node) -> bool:
	return _find_level_root(source) == _find_level_root(target)


func _find_level_root(node: Node) -> Node:
	var curr := node
	while curr:
		if curr.name.begins_with("level_"):
			return curr
		curr = curr.get_parent()
	return null


func _has_line_of_sight(from_pos: Vector2, to_pos: Vector2, shooter: Node, target: Node) -> bool:
	var world := get_viewport().world_2d
	if world == null:
		return false

	var query := PhysicsRayQueryParameters2D.create(from_pos, to_pos)
	query.collision_mask = FLASH_RAYCAST_MASK
	query.exclude = []
	if shooter is CollisionObject2D:
		query.exclude.append((shooter as CollisionObject2D).get_rid())
	if target is CollisionObject2D:
		query.exclude.append((target as CollisionObject2D).get_rid())

	var hit := world.direct_space_state.intersect_ray(query)
	return hit.is_empty()


func _play_legacy_flash_visual() -> void:
	var overlay := _get_or_create_flash_overlay()
	if overlay == null:
		return

	overlay.visible = true
	var quarter := FLASH_DURATION / 4.0
	var tween := create_tween()
	tween.tween_callback(func() -> void:
		overlay.color = Color(1.0, 1.0, 1.0, 0.85)
	)
	tween.tween_interval(quarter)
	tween.tween_callback(func() -> void:
		overlay.color = Color(0.0, 0.0, 0.0, 0.6)
	)
	tween.tween_interval(quarter)
	tween.tween_callback(func() -> void:
		overlay.color = Color(1.0, 1.0, 1.0, 0.85)
	)
	tween.tween_interval(quarter)
	tween.tween_callback(func() -> void:
		overlay.color = Color(0.0, 0.0, 0.0, 0.6)
	)
	tween.tween_interval(quarter)
	tween.tween_callback(func() -> void:
		overlay.visible = false
		overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	)


func _get_or_create_flash_overlay() -> ColorRect:
	var root := get_tree().root
	if root == null:
		return null

	var existing := root.get_node_or_null(FLASH_OVERLAY_NAME)
	if existing and existing is CanvasLayer:
		return (existing as CanvasLayer).get_node_or_null("FlashRect") as ColorRect

	var layer := CanvasLayer.new()
	layer.name = FLASH_OVERLAY_NAME
	layer.layer = 100

	var rect := ColorRect.new()
	rect.name = "FlashRect"
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.offset_left = 0.0
	rect.offset_top = 0.0
	rect.offset_right = 0.0
	rect.offset_bottom = 0.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color(1.0, 1.0, 1.0, 0.0)
	rect.visible = false

	layer.add_child(rect)
	root.add_child(layer)
	return rect


func reset_cooldown() -> void:
	_cooldown_remaining = 0.0


func get_cooldown_remaining() -> float:
	return _cooldown_remaining
