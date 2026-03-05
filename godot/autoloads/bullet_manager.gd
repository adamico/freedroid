extends Node2D

var _bullet_scene: PackedScene = preload("res://entities/projectiles/bullet.tscn")
var _blast_scene: PackedScene = preload("res://entities/projectiles/blast.tscn")


func _ready() -> void:
	name = "BulletManager"
	z_index = 100 # Ensure bullets and blasts appear on top of Level TileMaps


func spawn_bullet(
		bullet_data: BulletData,
		pos: Vector2,
		direction: Vector2,
		spawn_offset: float,
		gun_id: int,
		is_player: bool,
) -> void:
	if not _bullet_scene:
		push_warning("BulletManager: tried to fire but bullet_scene is null.")
		return

	var bullet := _bullet_scene.instantiate() as Node2D
	bullet.data = bullet_data

	add_child(bullet)
	print("BulletManager: spawned bullet at", pos)

	bullet.global_position = pos + direction * spawn_offset
	if bullet.has_method("setup"):
		bullet.setup(direction, gun_id, is_player)


func spawn_blast(pos: Vector2, type: int) -> void:
	if not _blast_scene:
		push_warning("BulletManager: tried to spawn blast but blast_scene is null.")
		return

	var blast = _blast_scene.instantiate() as Node2D
	blast.global_position = pos
	if blast.has_method("setup"):
		blast.setup(type)

	call_deferred("add_child", blast)
