class_name Player
extends DroidEntity

var _god_mode_enabled: bool = false

func _init() -> void:
	if not droid_data:
		droid_data = preload("res://data/converted/droids/droid_001.tres")


func _ready() -> void:
	super._ready()
	if GlobalState:
		GlobalState.detect_current_level(self)

		if health:
			health.is_player = true
			GlobalState.update_player_energy(health.energy)
			health.energy_changed.connect(GlobalState.update_player_energy)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if Input.is_action_just_pressed("god_mode"):
		_toggle_god_mode()

	if GlobalState:
		var grid_pos = Vector2(
			int(global_position.x / GameConstantsData.TILE_SIZE),
			int(global_position.y / GameConstantsData.TILE_SIZE),
		)
		GlobalState.update_player_pos(grid_pos)


func _toggle_god_mode() -> void:
	_god_mode_enabled = not _god_mode_enabled

	if health:
		health.god_mode_invulnerable = _god_mode_enabled

	var hurtbox := get_node_or_null("HurtboxComponent") as HurtboxComponent
	if hurtbox:
		hurtbox.invincible = _god_mode_enabled

	print("[Cheat] god_mode=%s" % _god_mode_enabled)
