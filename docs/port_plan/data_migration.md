# Resource & Data Migration (Static Conversion)

The original codebase uses custom string-parsing at runtime (in `init.c`). For Godot 4, we perform a **static conversion** into native `.tres` resources ahead of time.

## Static Data Conversion Tool (`@tool`)

- **`RulesetParser.gd`** — Reads legacy `freedroid.ruleset`, extracts droid templates, saves `DroidData` `.tres` resources (maxspeed, score, aggression, etc.).
- **`MissionParser.gd`** — Parses `.mission` map files, translates ASCII grids into serialized level `.tres` files.

## Saving as Built-in Resources

- Uses `ResourceSaver.save(resource, "res://data/droids/droid_001.tres")`.
- Runtime game **only** loads `.tres` files — legacy string configs are ignored.

## Graphics / Audio

- Convert `.jpg`/`.bmp` to `.png` or import directly via Godot's native loaders.
- Set `texture_filter = nearest` in Project Settings for pixel art fidelity.

## Animations

- Sprite sheet subdivision (`InfluencerSurfacePointer[ENEMYPHASES]`) → `Sprite2D.hframes`/`vframes` + `AnimationPlayer`.
