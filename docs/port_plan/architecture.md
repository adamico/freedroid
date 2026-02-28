# Architectural Mapping

The legacy game relies heavily on global state and raw SDL rendering. Godot 4 requires shifting to a Scene-based component architecture utilizing the Scene Tree, Autoloads, and the physics engine.

## Global State → Autoloads (Singletons)

Global structs (`GameConfig`, `Me`, `CurLevel`, `AllEnemys`) become Autoload singletons:

- **`GameManager.gd`** — Score, alert levels, death counts, game loop orchestration.
- **`LevelManager.gd`** — Loads pre-converted level resources, tracks active level, instantiates scenes.
- **`AudioManager.gd`** — Managed audio pool mapping `AudioStreamPlayer` nodes.
- **`ConfigManager.gd`** — Resolutions, graphical scales, settings.

## Game Entities → Composition via Components

Entities are **thin host nodes** (`CharacterBody2D` or `Area2D`) composed of reusable component scripts attached as children (ECS-lite).

- **Player** — `CharacterBody2D` + `PlayerInputComponent` + shared components.
- **Enemy** — `CharacterBody2D` + `WaypointAIComponent` + same shared components.
- **Bullets** — `Area2D` + `MovementComponent` + `HitboxComponent`.
- **Blasts** — `Area2D` + `AnimatedSprite2D` + `HitboxComponent`, auto-frees on animation end.

## Reusable Component Library (`res://components/`)

Each component is a standalone `.gd` script extending `Node`. Components communicate via signals.

| Component | Responsibility | Replaces (C legacy) |
|---|---|---|
| `HealthComponent` | Tracks `energy`, `max_energy`, emits `died` | `enemy.energy`, `Me.energy` |
| `MovementComponent` | Velocity/acceleration on parent body | `Me.speed`, `maxspeed`, `accel` |
| `WeaponComponent` | Fires bullets, `firewait` cooldown | `Me.firewait`, `Bulletmap[]` |
| `HitboxComponent` | `Area2D` overlap → routes damage | `CheckBulletCollisions()` |
| `HurtboxComponent` | Damageable volume | Droid collision shapes |
| `PlayerInputComponent` | `InputMap` → `MovementComponent` | `input.c` key polling |
| `WaypointAIComponent` | Waypoint patrol, aggression | `MoveEnemys()`, `nextwaypoint` |
| `StateMachineComponent` | FSM: `MOBILE`, `TRANSFERMODE`, etc. | `Me.status` enum |
| `AnimationComponent` | `Sprite2D` phase from direction/state | `phase`, `ENEMYPHASES` |
| `FlashComponent` | Temp invincibility / flash VFX | `flashimmune`, `FLASH_DURATION` |

## Map → TileMapLayer

- Pre-converted `.tres` level resources loaded by `LevelManager` into `TileMapLayer`.
- `GetMapBrick()` → `TileMapLayer.get_cell_atlas_coords()`.
- Interactive tiles (Doors, Consoles, Elevators) as separate `Area2D` scenes.

## Takeover Minigame → Control GUI

- `TakeoverMinigame.tscn` — `CanvasLayer` / `Control` full-screen UI, pauses scene tree.
- Grid of cables/blocks → `GridContainer` or custom UI matrix.
- Capsules → instanced `TextureRect` widgets.

## Source File Reference Map

When porting, use this table to find the relevant C source for each Godot subsystem:

| Category | C files | Port target |
|---|---|---|
| **Core logic** | `bullet.c`, `enemy.c`, `influ.c`, `ship.c` | Entity components (`MovementComponent`, `WeaponComponent`, `WaypointAIComponent`, etc.) |
| **Map / Levels** | `map.c`, `map.h` | `TileMapLayer`, `LevelManager.gd` |
| **Takeover** | `takeover.c`, `takeover.h` | `TakeoverMinigame.tscn` (Control UI) |
| **Data / Init** | `init.c`, `maped.h` | `@tool` converter scripts (`RulesetParser.gd`, `MissionParser.gd`) |
| **Data structs** | `struct.h`, `defs.h`, `vars.h` | `DroidData.tres`, `BulletData.tres` resources |
| **Rendering** | `graphics.c`, `view.c` | *Not ported* — Godot scene tree handles rendering |
| **Input** | `input.c` | `PlayerInputComponent.gd` + Godot `InputMap` |
| **Sound** | `sound.c` | `AudioManager.gd` |
| **Menus / Text** | `menu.c`, `text.c`, `text.h` | Godot Control nodes / theme |
| **Highscore** | `highscore.c` | `GameManager.gd` (save/load via `ConfigFile`) |
| **Utilities** | `misc.c` | Inline into relevant scripts |
| **Third-party** | `BFont.*`, `SDL_rotozoom.*`, `getopt.*` | *Not ported* — Godot native equivalents |
