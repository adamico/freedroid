@tool
extends EditorPlugin

const GameConstantsData := preload("res://data/game_constants_data.gd")
const BulletData := preload("res://data/bullet_data.gd")
const DroidData := preload("res://data/droid_data.gd")
const WaypointData := preload("res://data/waypoint_data.gd")
const LevelData := preload("res://data/level_data.gd")
const LiftEntryData := preload("res://data/lift_entry_data.gd")
const ElevatorData := preload("res://data/elevator_data.gd")
const DroidSpawnData := preload("res://data/droid_spawn_data.gd")
const MissionData := preload("res://data/mission_data.gd")

const OUTPUT_DIR := "res://data/converted/"

var _button: Button


func _enter_tree() -> void:
	_button = Button.new()
	_button.text = "Convert Legacy Data"
	_button.pressed.connect(_on_convert_pressed)
	add_control_to_container(CONTAINER_TOOLBAR, _button)


func _exit_tree() -> void:
	if _button:
		remove_control_from_container(CONTAINER_TOOLBAR, _button)
		_button.queue_free()
		_button = null


func _on_convert_pressed() -> void:
	print("=== Freedroid Legacy Data Converter ===")
	_ensure_dirs()

	var ruleset_path := _resolve_legacy_path("freedroid.ruleset")
	var mission_path := _resolve_legacy_path("Paradroid.mission")
	var maps_path := _resolve_legacy_path("Paradroid.maps")
	var elevators_path := _resolve_legacy_path("Paradroid.elevators")
	var droids_path := _resolve_legacy_path("Paradroid.droids")

	# --- Ruleset ---
	var ruleset_text := _read_file(ruleset_path)
	if ruleset_text.is_empty():
		printerr("Failed to read ruleset file: ", ruleset_path)
		return
	_parse_game_constants(ruleset_text)
	_parse_bullets(ruleset_text)
	_parse_droids(ruleset_text)

	# --- Mission ---
	var mission_text := _read_file(mission_path)
	if mission_text.is_empty():
		printerr("Failed to read mission file: ", mission_path)
		return
	_parse_mission(mission_text)

	# --- Maps ---
	var maps_text := _read_file(maps_path)
	if maps_text.is_empty():
		printerr("Failed to read maps file: ", maps_path)
		return
	_parse_maps(maps_text)

	# --- Elevators ---
	var elevators_text := _read_file(elevators_path)
	if elevators_text.is_empty():
		printerr("Failed to read elevators file: ", elevators_path)
		return
	_parse_elevators(elevators_text)

	# --- Crew/Droids ---
	var droids_text := _read_file(droids_path)
	if droids_text.is_empty():
		printerr("Failed to read droids file: ", droids_path)
		return
	_parse_droid_spawns(droids_text)

	print("=== Conversion complete! ===")
	EditorInterface.get_resource_filesystem().scan()

# =========================================================================
# Utility
# =========================================================================


func _resolve_legacy_path(filename: String) -> String:
	# Project root is godot/, legacy files are in ../map/
	# We resolve this to an absolute path so FileAccess can
	# open files outside the Godot project directory.
	var project_dir := ProjectSettings.globalize_path("res://")
	# Strip trailing slash, then get the parent directory
	var parent_dir := project_dir.rstrip("/").get_base_dir()
	var legacy_path := parent_dir.path_join("map").path_join(filename)
	print("  Legacy path: ", legacy_path)
	return legacy_path


func _read_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		printerr("Cannot open file: ", path, " Error: ", FileAccess.get_open_error())
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _ensure_dirs() -> void:
	for subdir in ["bullets", "droids", "levels", "spawns", "missions"]:
		DirAccess.make_dir_recursive_absolute(OUTPUT_DIR + subdir)


func _save_resource(res: Resource, path: String) -> void:
	var err := ResourceSaver.save(res, path)
	if err != OK:
		printerr("Failed to save: ", path, " Error: ", err)
	else:
		print("  Saved: ", path)


## Extract a float value after a label string on the same line.
func _extract_float(text: String, label: String) -> float:
	var idx := text.find(label)
	if idx == -1:
		printerr("Label not found: ", label)
		return 0.0
	var after := text.substr(idx + label.length())
	var line_end := after.find("\n")
	if line_end != -1:
		after = after.substr(0, line_end)
	return after.strip_edges().to_float()


## Extract an int value after a label string on the same line.
func _extract_int(text: String, label: String) -> int:
	var idx := text.find(label)
	if idx == -1:
		printerr("Label not found: ", label)
		return 0
	var after := text.substr(idx + label.length())
	var line_end := after.find("\n")
	if line_end != -1:
		after = after.substr(0, line_end)
	return after.strip_edges().to_int()


## Extract a string value after a label, up to end of line.
func _extract_string(text: String, label: String) -> String:
	var idx := text.find(label)
	if idx == -1:
		return ""
	var after := text.substr(idx + label.length())
	var line_end := after.find("\n")
	if line_end != -1:
		after = after.substr(0, line_end)
	return after.strip_edges()


## Find all occurrences of a delimiter and split text into sections.
func _split_sections(text: String, delimiter: String) -> PackedStringArray:
	var result: PackedStringArray = []
	var search_from := 0
	while true:
		var idx := text.find(delimiter, search_from)
		if idx == -1:
			break
		# Content starts after the delimiter line
		var content_start := text.find("\n", idx)
		if content_start == -1:
			break
		content_start += 1
		# Find next occurrence or end
		var next_idx := text.find(delimiter, content_start)
		var section_end := next_idx if next_idx != -1 else text.length()
		result.append(text.substr(content_start, section_end - content_start))
		search_from = content_start
	return result


## Extract text between two marker strings.
func _extract_between(text: String, start_marker: String, end_marker: String) -> String:
	var start_idx := text.find(start_marker)
	if start_idx == -1:
		return ""
	start_idx += start_marker.length()
	var end_idx := text.find(end_marker, start_idx)
	if end_idx == -1:
		return text.substr(start_idx)
	return text.substr(start_idx, end_idx - start_idx).strip_edges()

# =========================================================================
# Ruleset: Game Constants
# =========================================================================


func _parse_game_constants(text: String) -> void:
	print("Parsing game constants...")
	var section := _extract_between(
		text,
		"*** Start of General Game Constants Section: ***",
		"*** End of General Game Constants Section: ***",
	)

	var res := GameConstantsData.new()
	res.collision_lose_energy_calibrator = _extract_float(
		section,
		"Energy-Loss-factor for Collisions of Influ with hostile robots=",
	)
	res.blast_radius = _extract_float(
		section,
		"Radius of explosions (as far as damage is concerned) in multiples of tiles=",
	)
	res.blast_damage_per_second = _extract_float(
		section,
		"Amount of damage done by contact to a blast per second of time=",
	)
	res.droid_radius = _extract_float(section, "Droid radius:")
	res.time_for_door_phase = _extract_float(
		section,
		"Time for the doors to move by one subphase of their movement=",
	)
	res.deathcount_drain_speed = _extract_float(section, "Deathcount drain speed =")
	res.alert_threshold = _extract_int(section, "First alert threshold =")
	res.alert_bonus_per_sec = _extract_float(section, "Alert bonus per second =")

	# Blast animation times are outside the constants section
	res.blast_one_animation_time = _extract_float(
		text,
		"Time in seconds for the animation of blast one :",
	)
	res.blast_two_animation_time = _extract_float(
		text,
		"Time in seconds for the animation of blast two :",
	)

	_save_resource(res, OUTPUT_DIR + "game_constants.tres")

# =========================================================================
# Ruleset: Bullets
# =========================================================================


func _parse_bullets(text: String) -> void:
	print("Parsing bullet data...")
	var section := _extract_between(
		text,
		"*** Start of Bullet Data Section: ***",
		"*** End of Bullet Data Section: ***",
	)

	# Read global calibrators
	var speed_cal := _extract_float(section, "Common factor for all bullet's speed values:")
	var damage_cal := _extract_float(section, "Common factor for all bullet's damage values:")

	# Split into individual bullet subsections
	var bullet_sections := _split_sections(
		section,
		"** Start of new bullet specification subsection **",
	)

	for i in range(bullet_sections.size()):
		var bs := bullet_sections[i]
		var bullet := BulletData.new()
		bullet.recharging_time = _extract_float(
			bs,
			"Time is takes to recharge this bullet/weapon in seconds :",
		)
		bullet.speed = _extract_float(bs, "Flying speed of this bullet type :") * speed_cal
		bullet.damage = roundi(
			_extract_int(
				bs,
				"Damage cause by a hit of this bullet type :",
			) * damage_cal,
		)
		bullet.blast_type = _extract_int(
			bs,
			"Type of blast this bullet causes when crashing e.g. against a wall :",
		)
		_save_resource(bullet, OUTPUT_DIR + "bullets/bullet_%03d.tres" % i)

	print("  Found %d bullet types" % bullet_sections.size())

# =========================================================================
# Ruleset: Droids
# =========================================================================


func _parse_droids(text: String) -> void:
	print("Parsing droid data...")
	var section := _extract_between(
		text,
		"*** Start of Robot Data Section: ***",
		"*** End of Robot Data Section: ***",
	)

	# Read global calibrators
	var speed_cal := _extract_float(section, "Common factor for all droids maxspeed values:")
	var accel_cal := _extract_float(
		section,
		"Common factor for all droids acceleration values:",
	)
	var energy_cal := _extract_float(
		section,
		"Common factor for all droids maximum energy values:",
	)
	var eloss_cal := _extract_float(
		section,
		"Common factor for all droids energyloss values:",
	)
	var aggr_cal := _extract_float(section, "Common factor for all droids aggression values:")
	var score_cal := _extract_float(section, "Common factor for all droids score values:")

	var robot_sections := _split_sections(section, "** Start of new Robot: **")

	for i in range(robot_sections.size()):
		var rs := robot_sections[i]
		var droid := DroidData.new()

		droid.droid_name = _extract_string(rs, "Droidname:")
		droid.maxspeed = _extract_float(rs, "Maximum speed of this droid:") * speed_cal
		droid.droid_class = _extract_int(rs, "Class of this droid:")
		droid.accel = _extract_float(
			rs,
			"Maximum acceleration of this droid:",
		) * accel_cal
		droid.maxenergy = _extract_float(
			rs,
			"Maximum energy of this droid:",
		) * energy_cal
		droid.lose_health = _extract_float(
			rs,
			"Rate of energyloss under influence control:",
		) * eloss_cal
		droid.gun = _extract_int(rs, "Weapon type this droid uses:")
		droid.aggression = roundi(
			_extract_int(rs, "Aggression rate of this droid:") * aggr_cal,
		)
		droid.flashimmune = _extract_int(
			rs,
			"Is this droid immune to disruptor blasts?",
		) != 0
		droid.score = roundi(
			_extract_int(
				rs,
				"Score gained for destroying one of this type:",
			) * score_cal,
		)
		droid.height = _extract_float(rs, "Height of this droid :")
		droid.weight = _extract_int(rs, "Weight of this droid :")
		droid.drive = _extract_int(rs, "Drive of this droid :")
		droid.brain = _extract_int(rs, "Brain of this droid :")
		droid.sensor1 = _extract_int(rs, "Sensor 1 of this droid :")
		droid.sensor2 = _extract_int(rs, "Sensor 2 of this droid :")
		droid.sensor3 = _extract_int(rs, "Sensor 3 of this droid :")
		droid.notes = _extract_string(rs, "Notes concerning this droid :")

		_save_resource(droid, OUTPUT_DIR + "droids/droid_%s.tres" % droid.droid_name)

	print("  Found %d droid types" % robot_sections.size())

# =========================================================================
# Mission file
# =========================================================================


func _parse_mission(text: String) -> void:
	print("Parsing mission data...")
	var section := _extract_between(
		text,
		"*** Start of Mission File ***",
		"*** End of Mission File ***",
	)

	var mission := MissionData.new()
	mission.mission_name = _extract_string(section, "Mission Name:")
	mission.ruleset_file = _extract_string(
		section,
		"Physics ('game.dat') file to use for this mission:",
	)
	mission.ship_file = _extract_string(section, "Ship file to use for this mission:")
	mission.lift_file = _extract_string(section, "Lift file to use for this mission:")
	mission.crew_file = _extract_string(section, "Crew file to use for this mission:")

	# Start comment: text between quotes after the label
	var comment_label := "Influs mission start comment=\""
	var cidx := section.find(comment_label)
	if cidx != -1:
		var after := section.substr(cidx + comment_label.length())
		var end_quote := after.find("\"")
		if end_quote != -1:
			mission.start_comment = after.substr(0, end_quote)

	# Title picture and songs
	mission.title_picture = _extract_string(
		section,
		"The title picture in the graphics subdirectory for this mission is :",
	)
	mission.title_song = _extract_string(
		section,
		"The title song in the sound subdirectory for this mission is :",
	)
	mission.end_title_song = _extract_string(
		section,
		"Song name to play in the end title if the mission is completed:",
	)

	# End title text
	mission.end_title_text = _extract_between(
		section,
		"** Beginning of End Title Text Section **",
		"** End of End Title Text Section **",
	)

	# Start points
	var sp_search := section
	while true:
		var sp_idx := sp_search.find("Possible Start Point :")
		if sp_idx == -1:
			break
		var sp_line := sp_search.substr(sp_idx)
		var line_end := sp_line.find("\n")
		if line_end != -1:
			sp_line = sp_line.substr(0, line_end)
		var point := { }
		# Parse Level=N XPos=N YPos=N
		var level_idx := sp_line.find("Level=")
		var xpos_idx := sp_line.find("XPos=")
		var ypos_idx := sp_line.find("YPos=")
		if level_idx != -1 and xpos_idx != -1 and ypos_idx != -1:
			var lv_str := sp_line.substr(
				level_idx + 6,
				xpos_idx - level_idx - 6,
			)
			point["level"] = lv_str.strip_edges().to_int()
			var x_str := sp_line.substr(
				xpos_idx + 5,
				ypos_idx - xpos_idx - 5,
			)
			point["x"] = x_str.strip_edges().to_int()
			point["y"] = sp_line.substr(ypos_idx + 5).strip_edges().to_int()
			mission.start_points.append(point)
		sp_search = sp_search.substr(sp_idx + 22) # Move past "Possible Start Point :"

	# Briefing pages
	var briefing_search := section
	while true:
		var page_text := _extract_between(
			briefing_search,
			"* New Mission Briefing Text Subsection *",
			"* End of Mission Briefing Text Subsection *",
		)
		if page_text.is_empty():
			break
		mission.briefing_pages.append(page_text)
		var end_marker := "* End of Mission Briefing Text Subsection *"
		var end_idx := briefing_search.find(end_marker)
		if end_idx == -1:
			break
		briefing_search = briefing_search.substr(end_idx + end_marker.length())

	_save_resource(mission, OUTPUT_DIR + "missions/paradroid.tres")
	print(
		"  Mission: %s, %d start points, %d briefing pages" % [
			mission.mission_name,
			mission.start_points.size(),
			mission.briefing_pages.size(),
		],
	)

# =========================================================================
# Maps (levels)
# =========================================================================


func _parse_maps(text: String) -> void:
	print("Parsing map data...")
	# The area name
	var area_name := _extract_string(text, "Area name=\"")
	if area_name.ends_with("\""):
		area_name = area_name.substr(0, area_name.length() - 1)

	# Split by "Levelnumber:"
	var level_count := 0
	var search_from := 0
	while true:
		var lev_idx := text.find("Levelnumber:", search_from)
		if lev_idx == -1:
			break

		# Find the end of this level (next "end_level" or "*** End of Ship Data ***")
		var end_idx := text.find("end_level", lev_idx)
		if end_idx == -1:
			end_idx = text.length()
		var level_text := text.substr(lev_idx, end_idx - lev_idx)

		var level := LevelData.new()
		level.level_number = _extract_int(level_text, "Levelnumber:")
		level.xlen = _extract_int(level_text, "xlen of this level:")
		level.ylen = _extract_int(level_text, "ylen of this level:")
		level.color = _extract_int(level_text, "color of this level:")

		var name_str := _extract_string(level_text, "Name of this level=")
		level.level_name = name_str

		var comment_label := "Comment of the Influencer" \
		+ " on entering this level=\""
		var comment_str := _extract_string(
			level_text,
			comment_label,
		)
		if comment_str.ends_with("\""):
			comment_str = comment_str.substr(
				0,
				comment_str.length() - 1,
			)
		level.enter_comment = comment_str

		level.background_song = _extract_string(
			level_text,
			"Name of background song for this level=",
		)

		# Parse tile grid
		var grid_start := level_text.find("begin_map")
		var grid_end := level_text.find("begin_waypoints")
		if grid_start != -1 and grid_end != -1:
			var grid_text := level_text.substr(
				grid_start + "begin_map".length(),
				grid_end - grid_start - "begin_map".length(),
			).strip_edges()
			level.grid = _parse_tile_grid(grid_text, level.xlen, level.ylen)

		# Parse waypoints
		var wp_start := level_text.find("begin_waypoints")
		if wp_start != -1:
			var wp_text := level_text.substr(wp_start + "begin_waypoints".length()).strip_edges()
			level.waypoints = _parse_waypoints(wp_text)

		_save_resource(level, OUTPUT_DIR + "levels/level_%02d.tres" % level.level_number)
		level_count += 1
		search_from = end_idx + 1

	print("  Found %d levels" % level_count)


func _parse_tile_grid(text: String, xlen: int, ylen: int) -> PackedInt32Array:
	var grid := PackedInt32Array()
	grid.resize(xlen * ylen)
	var lines := text.split("\n", false)
	for y in range(mini(lines.size(), ylen)):
		var tokens := lines[y].strip_edges().split(" ", false)
		for x in range(mini(tokens.size(), xlen)):
			grid[y * xlen + x] = tokens[x].to_int()
	return grid


func _parse_waypoints(text: String) -> Array[WaypointData]:
	var waypoints: Array[WaypointData] = []
	var lines := text.split("\n", false)
	for line in lines:
		line = line.strip_edges()
		if not line.begins_with("Nr.="):
			continue

		var wp := WaypointData.new()

		# Parse "Nr.=  0 x=  11 y=   1\t connections:  5  1  2  3"
		var x_idx := line.find("x=")
		var y_idx := line.find("y=")
		var conn_idx := line.find("connections:")

		if x_idx == -1 or y_idx == -1:
			continue

		var x_end := y_idx
		var y_end := conn_idx if conn_idx != -1 else line.length()

		wp.position.x = line.substr(x_idx + 2, x_end - x_idx - 2).strip_edges().to_int()
		wp.position.y = line.substr(y_idx + 2, y_end - y_idx - 2).strip_edges().to_int()

		if conn_idx != -1:
			var conn_str := line.substr(conn_idx + "connections:".length()).strip_edges()
			var conn_tokens := conn_str.split(" ", false)
			var connections := PackedInt32Array()
			for token in conn_tokens:
				connections.append(token.strip_edges().to_int())
			wp.connections = connections

		waypoints.append(wp)

	return waypoints

# =========================================================================
# Elevators
# =========================================================================


func _parse_elevators(text: String) -> void:
	print("Parsing elevator data...")
	var elev := ElevatorData.new()

	# Area name (from maps, but we can also get it here)
	elev.area_name = "U.S.S. Paradroid"

	# Parse elevator column rectangles
	var erect_section := _extract_between(
		text,
		"*** Beginning of elevator rectangles ***",
		"*** End of elevator rectangles ***",
	)
	var erect_lines := erect_section.split("\n", false)
	for line in erect_lines:
		line = line.strip_edges()
		if not line.begins_with("Elevator Number="):
			continue
		var x := _extract_int(line, "ElRowX=")
		var y := _extract_int(line, "ElRowY=")
		var w := _extract_int(line, "ElRowW=")
		var h := _extract_int(line, "ElRowH=")
		elev.elevator_rects.append(Rect2i(x, y, w, h))

	# Parse deck rectangles
	var drect_section := _extract_between(
		text,
		"*** Beginning of deck rectangles ***",
		"*** End of deck rectangle section ***",
	)
	var drect_lines := drect_section.split("\n", false)
	for line in drect_lines:
		line = line.strip_edges()
		if not line.begins_with("DeckNr="):
			continue
		var deck_nr := _extract_int(line, "DeckNr=")
		var x := _extract_int(line, "DeckX=")
		var y := _extract_int(line, "DeckY=")
		var w := _extract_int(line, "DeckW=")
		var h := _extract_int(line, "DeckH=")
		if not elev.deck_rects.has(deck_nr):
			elev.deck_rects[deck_nr] = []
		elev.deck_rects[deck_nr].append(Rect2i(x, y, w, h))

	# Parse lift entries
	var lift_section := _extract_between(
		text,
		"*** Beginning of Lift Data ***",
		"*** End of Lift Connection Data ***",
	)
	var lift_lines := lift_section.split("\n", false)
	for line in lift_lines:
		line = line.strip_edges()
		if not line.begins_with("Label="):
			continue
		var lift := LiftEntryData.new()
		lift.label = _extract_int(line, "Label=")
		lift.deck = _extract_int(line, "Deck=")
		lift.position.x = _extract_int(line, "PosX=")
		lift.position.y = _extract_int(line, "PosY=")
		lift.level_up = _extract_int(line, "LevelUp=")
		lift.level_down = _extract_int(line, "LevelDown=")
		lift.lift_row = _extract_int(line, "LiftRow=")
		elev.lifts.append(lift)

	_save_resource(elev, OUTPUT_DIR + "elevators.tres")
	print(
		"  %d lifts, %d elevator columns, %d decks" % [
			elev.lifts.size(),
			elev.elevator_rects.size(),
			elev.deck_rects.size(),
		],
	)

# =========================================================================
# Droid spawns (crew file)
# =========================================================================


func _parse_droid_spawns(text: String) -> void:
	print("Parsing droid spawn data...")
	var section := _extract_between(
		text,
		"*** Beginning of Droid Data ***",
		"*** End of Droid Data ***",
	)

	var level_sections := _split_sections(section, "** Beginning of new Level **")
	var count := 0

	for ls in level_sections:
		var spawn := DroidSpawnData.new()
		spawn.level_number = _extract_int(ls, "Level=")
		spawn.max_random_droids = _extract_int(ls, "Maximum number of Random Droids=")
		spawn.min_random_droids = _extract_int(ls, "Minimum number of Random Droids=")

		# Parse allowed types
		var lines := ls.split("\n", false)
		for line in lines:
			line = line.strip_edges()
			if line.begins_with("Allowed Type of Random Droid for this level:"):
				var type_str := line.substr(
					"Allowed Type of Random Droid for this level:".length(),
				).strip_edges()
				spawn.allowed_droid_types.append(type_str)
			elif line.contains("SpecialForce:") or line.contains("specialForce:"):
				# Parse special force: "S**pecialForce: Type=999 X=1 Y=1 Fixed=1 Marker=1"
				# Note: the file has a typo "S**pecialForce" in level 6
				var sf := { }
				if line.find("Type=") != -1:
					sf["type"] = _extract_string(
						line,
						"Type=",
					).split(" ")[0]
				else:
					sf["type"] = ""
				if line.find("X=") != -1:
					sf["x"] = _extract_int(line, "X=")
				else:
					sf["x"] = 0
				if line.find("Y=") != -1:
					sf["y"] = _extract_int(line, "Y=")
				else:
					sf["y"] = 0
				if line.find("Fixed=") != -1:
					sf["fixed"] = _extract_int(
						line,
						"Fixed=",
					) != 0
				else:
					sf["fixed"] = false
				if line.find("Marker=") != -1:
					sf["marker"] = _extract_int(
						line,
						"Marker=",
					) != 0
				else:
					sf["marker"] = false
				spawn.special_forces.append(sf)

		_save_resource(spawn, OUTPUT_DIR + "spawns/spawn_level_%02d.tres" % spawn.level_number)
		count += 1

	print("  Found %d level spawn configs" % count)
