## Generates the classic TileSet resource from map_blocks.png.
##
## Run headless:
##   godot --headless --path . --script tools/generate_tileset.gd --quit
##
## Or in-editor: load as EditorScript and run via Script > Run.
extends MainLoop

const TILE_SIZE := Vector2i(64, 64)
const SEPARATION := Vector2i(2, 2)
const NUM_COLUMNS := 44 # TileTypes.NUM_MAP_TILES
const NUM_ROWS := 7 # NUM_COLORS

const TEXTURE_PATH := "res://assets/tilesets/classic_map_blocks.png"
const OUTPUT_PATH := "res://assets/tilesets/classic_tileset.tres"

## Tile IDs that are fully solid (full 64×64 collision rect).
## Matches TileTypes constants for walls, corners, junctions, blocks, and consoles.
const SOLID_TILES := [
	1, # ECK_LU
	2, # T_U
	3, # ECK_RU
	4, # T_L
	5, # KREUZ
	6, # T_R
	7, # ECK_LO
	8, # T_O
	9, # ECK_RO
	10, # H_WALL
	11, # V_WALL
	12, # INVISIBLE (blocks movement)
	13, # BLOCK1
	14, # BLOCK2
	15, # BLOCK3
	16, # BLOCK4
	17, # BLOCK5
	23, # KONSOLE_L
	24, # KONSOLE_R
	25, # KONSOLE_O
	26, # KONSOLE_U
]


func _initialize() -> void:
	print("=== TileSet Generator ===")

	# --- Load source texture ---
	var texture := load(TEXTURE_PATH) as Texture2D
	if texture == null:
		printerr("ERROR: Could not load texture at ", TEXTURE_PATH)
		return

	print("  Loaded texture: ", texture.get_size())

	# --- Create TileSet ---
	var tileset := TileSet.new()
	tileset.tile_size = TILE_SIZE

	# Physics layer 0: "walls"
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1) # layer bit 1
	tileset.set_physics_layer_collision_mask(0, 1)

	# Custom data layer 0: "tile_type" (int)
	tileset.add_custom_data_layer()
	tileset.set_custom_data_layer_name(0, "tile_type")
	tileset.set_custom_data_layer_type(0, TYPE_INT)

	# --- Create atlas source ---
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = TILE_SIZE
	atlas.separation = SEPARATION

	var source_id := tileset.add_source(atlas)
	print("  Atlas source ID: ", source_id)

	# --- Create tiles ---
	var tile_count := 0
	for col in range(NUM_COLUMNS):
		for row in range(NUM_ROWS):
			var coords := Vector2i(col, row)
			atlas.create_tile(coords)
			var tile_data := atlas.get_tile_data(coords, 0)

			# Custom data: tile_type = column index (matches TileTypes enum)
			tile_data.set_custom_data("tile_type", col)

			# Collision: full rect for solid tiles
			if col in SOLID_TILES:
				# Collision polygon coordinates are relative to tile center
				var half := Vector2(TILE_SIZE) / 2.0
				var polygon := PackedVector2Array(
					[
						Vector2(-half.x, -half.y),
						Vector2(half.x, -half.y),
						Vector2(half.x, half.y),
						Vector2(-half.x, half.y),
					],
				)
				tile_data.add_collision_polygon(0)
				tile_data.set_collision_polygon_points(0, 0, polygon)

			tile_count += 1

	print("  Created ", tile_count, " tiles (", NUM_COLUMNS, " types x ", NUM_ROWS, " colors)")

	# --- Save ---
	var err := ResourceSaver.save(tileset, OUTPUT_PATH)
	if err != OK:
		printerr("ERROR: Failed to save TileSet: error code ", err)
		return

	print("  Saved to: ", OUTPUT_PATH)
	print("=== Done ===")


func _process(_delta: float) -> bool:
	# Exit immediately after _initialize
	return true
