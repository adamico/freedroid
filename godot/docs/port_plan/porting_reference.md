# Porting Reference (Implementation-First)

## Purpose

This document is the implementation reference for the current Godot port.
For features marked implemented, Godot code paths listed here are canonical.

## Status Legend

- implemented: behavior is present and should be treated as Godot source of truth
- partial: behavior exists but is incomplete or has known gaps
- not started: tracked but not implemented yet

## Feature Index

- Core runtime and autoload coordination
- Input and movement
- Droid stats resources
- Projectile stats resources
- Projectiles and collision routing
- Health and damage flow
- Doors and elevators interaction flow
- Enemy waypoint patrol baseline

## Core Runtime And Autoload Coordination

### Global runtime state and event bus

1. Feature name: Global runtime state and event bus
2. Status: implemented
3. Canonical Godot implementation:
   - autoloads/global_state.gd
4. Data dependencies:
   - Level scene naming convention level_xx
5. Runtime flow summary:
   - Global state exposes signals for enemy kills, player energy, player position, level changes, and elevator requests.
   - Gameplay systems call update methods to mutate state and emit notifications.
   - Elevator usage is routed through request_elevator for manager-level handling.
   - Current level can be detected by scanning scene tree ancestry and root children.
6. Behavioral notes:
   - This currently acts as both signal hub and mutable state store.
7. Tests:
   - tests/test_global_state.gd
8. Remaining gaps:
   - None for detect_current_level and elevator_requested signal payload; covered by focused global-state tests.
9. Legacy mapping:
   - Minimal mapping needed for implemented flow.

## Input And Movement

### Player input intent mapping

1. Feature name: Player input intent mapping
2. Status: implemented
3. Canonical Godot implementation:
   - components/input_component.gd
   - components/player_input_component.gd
4. Data dependencies:
   - Input actions: move_left, move_right, move_up, move_down, fire, interact
5. Runtime flow summary:
   - PlayerInputComponent reads directional axes through Input.get_vector.
   - Firing intent is represented by fire action pressed state.
   - Interact intent is emitted as interact_pressed from unhandled input.
6. Behavioral notes:
   - Intent is separated from movement integration and weapon cooldown logic.
7. Tests:
   - tests/test_player_input_component.gd
8. Remaining gaps:
   - None for interact timing transition edges; covered by explicit input action event tests.
9. Legacy mapping:
   - Not required for implemented behavior.

### Movement integration and speed model

1. Feature name: Movement integration and speed model
2. Status: implemented
3. Canonical Godot implementation:
   - components/movement_component.gd
4. Data dependencies:
   - DroidData.maxspeed
   - DroidData.accel
   - friction export values per entity
5. Runtime flow summary:
   - apply_input adds acceleration scaled by frame normalization.
   - apply_friction decelerates inactive axes to zero without sign flip drift.
   - clamp_speed limits per-axis velocity, matching legacy-style axis clamping.
   - Entities consume velocity and apply it through body-specific movement.
6. Behavioral notes:
   - Speed clamping is per axis instead of radial vector magnitude clamping.
7. Tests:
   - tests/test_movement_component.gd
   - tests/test_player_movement_integration.gd
8. Remaining gaps:
   - None for scene-level movement integration; covered by player scene loop integration test.
9. Legacy mapping:
   - Not required for implemented behavior.

## Droid Stats Resources

### Droid stat schema

1. Feature name: Droid stat schema
2. Status: implemented
3. Canonical Godot implementation:
   - data/droid_data.gd
4. Data dependencies:
   - Converted droid resource files under data/converted
5. Runtime flow summary:
   - DroidData resource defines exported stats for movement, health, weapon, AI, and score-related values.
   - Entities consume these values during setup for movement, health, and combat behavior.
6. Behavioral notes:
   - Resource fields are pre-baked during conversion and treated as runtime config.
7. Tests:
   - tests/test_data_resources.gd
8. Remaining gaps:
   - None for converted droid required-field validation; covered by dedicated resource validation tests.
9. Legacy mapping:
   - Optional and only needed when converter semantics change.

## Projectile Stats Resources

### Bullet stat schema

1. Feature name: Bullet stat schema
2. Status: implemented
3. Canonical Godot implementation:
   - data/bullet_data.gd
4. Data dependencies:
   - Converted bullet resource files under data/converted/bullets
5. Runtime flow summary:
   - BulletData defines recharging_time, speed, damage, blast_type, range_dist, and optional texture data.
   - Weapon and projectile systems consume this resource for cooldown and flight behavior.
6. Behavioral notes:
   - Cooldown fallback behavior is handled by weapon component when data is missing.
7. Tests:
   - Indirectly covered by weapon and combat tests.
   - tests/test_weapon_component.gd
   - tests/test_combat_routing.gd
   - tests/test_data_resources.gd
8. Remaining gaps:
   - None for converted bullet required-field validation; covered by dedicated resource validation tests.
9. Legacy mapping:
   - Optional and only needed for converter updates.

## Projectiles And Collision Routing

### Weapon fire and cooldown pipeline

1. Feature name: Weapon fire and cooldown pipeline
2. Status: implemented
3. Canonical Godot implementation:
   - components/weapon_component.gd
   - autoloads/bullet_manager.gd
4. Data dependencies:
   - BulletData.recharging_time
   - Converted bullet resources
5. Runtime flow summary:
   - WeaponComponent gates firing with cooldown and bullet_data presence.
   - try_fire normalizes direction and delegates spawn to BulletManager.
   - setup can resolve bullet resource from gun id naming convention.
   - fired signal is emitted after successful spawn request.
6. Behavioral notes:
   - BulletManager is a central spawn service and z-order owner for bullets/blasts.
7. Tests:
   - tests/test_weapon_component.gd
   - tests/test_bullet_manager_integration.gd
8. Remaining gaps:
   - None for scene-level BulletManager spawn side effects; covered by integration test (enemy/player spawn path, spawn offset, shooter collision mask, and cooldown gating).
9. Legacy mapping:
   - Not required for implemented behavior.

### Bullet lifecycle and damage handoff

1. Feature name: Bullet lifecycle and damage handoff
2. Status: implemented
3. Canonical Godot implementation:
   - entities/projectiles/bullet.gd
   - components/hitbox_component.gd
   - components/hurtbox_component.gd
   - autoloads/bullet_manager.gd
4. Data dependencies:
   - BulletData.speed
   - BulletData.range_dist
   - BulletData.damage
5. Runtime flow summary:
   - Bullet setup stores normalized direction, configures collision mask by shooter side, and configures animation profile by gun id.
   - Physics step moves bullet at constant speed and tracks traveled distance.
   - Bullet self-destroys on range exhaustion or on collision events.
   - Hitbox routes damage to Hurtbox, which applies it to HealthComponent.
   - Body collisions trigger blast spawn and bullet cleanup.
6. Behavioral notes:
   - Bullet flight uses manual position updates in Area2D physics process.
7. Tests:
   - tests/test_combat_routing.gd
   - tests/test_bullet_lifecycle.gd
8. Remaining gaps:
   - None for shooter mask switching, animation frame progression, or range-expiry cleanup; covered by dedicated lifecycle tests.
9. Legacy mapping:
   - Not required for implemented behavior.

## Health And Damage Flow

### Health pool, damage, heal, and depletion

1. Feature name: Health pool, damage, heal, and depletion
2. Status: implemented
3. Canonical Godot implementation:
   - components/health_component.gd
   - components/hurtbox_component.gd
   - components/hitbox_component.gd
4. Data dependencies:
   - DroidData.maxenergy
   - DroidData.lose_health
   - HitboxComponent.damage
5. Runtime flow summary:
   - HealthComponent initializes health cap and current energy to max.
   - Damage clamps energy and emits changed, damaged, and died signals when relevant.
   - Heal clamps to current health cap and emits healed and changed signals.
   - process_time_tick handles player permanent cap drain and enemy energy regeneration behavior.
6. Behavioral notes:
   - is_player switches time-tick behavior between cap drain and regeneration.
7. Tests:
   - tests/test_health_component.gd
   - tests/test_combat_routing.gd
   - tests/test_combat_exchange_integration.gd
8. Remaining gaps:
   - None for multi-entity chained combat exchanges over time; covered by integration test.
9. Legacy mapping:
   - Not required for implemented behavior.

## Doors And Elevators Interaction Flow

### Door open/close state machine

1. Feature name: Door open/close state machine
2. Status: implemented
3. Canonical Godot implementation:
   - entities/door/door.gd
4. Data dependencies:
   - Door phase timing
   - Tile atlas layout for door phases by orientation and color
5. Runtime flow summary:
   - Door tracks bodies in detection area and transitions between closed, opening, open, and closing states.
   - Opening and closing advance visual phase by timer.
   - Collision blocking toggles based on fully closed or fully open state.
6. Behavioral notes:
   - Visual region mapping is tied to classic_map_blocks atlas indices.
7. Tests:
   - tests/test_door.gd
8. Remaining gaps:
   - None for color/orientation region mapping and collision-layer toggling edge cases; covered by door edge-case tests.
9. Legacy mapping:
   - Not required for implemented behavior.

### Elevator activation routing

1. Feature name: Elevator activation routing
2. Status: partial
3. Canonical Godot implementation:
   - entities/elevator/elevator.gd
   - autoloads/global_state.gd
4. Data dependencies:
   - Elevator lift_index assignment
   - Player velocity and tile-center proximity checks
5. Runtime flow summary:
   - Elevator subscribes to player interact intent while player is in trigger area.
   - Activation requires low movement speed and proximity to elevator center.
   - On success, elevator emits elevator_activated and forwards request through GlobalState.
   - Main consumes GlobalState.elevator_requested to open LiftUI, then applies level transition in _change_level after floor selection.
6. Behavioral notes:
   - Transition handling appears intended for higher-level manager logic.
7. Tests:
   - tests/test_elevator.gd
8. Remaining gaps:
   - None for activation preconditions, signal emission payload, or consumer-path documentation.
9. Legacy mapping:
   - Keep minimal mapping only while transition handling remains partial.

## Enemy Waypoint Patrol Baseline

### Patrol movement and target selection

1. Feature name: Patrol movement and target selection
2. Status: partial
3. Canonical Godot implementation:
   - components/waypoint_patrol_component.gd
   - components/ai_component.gd
   - data/waypoint_data.gd
   - data/level_data.gd
4. Data dependencies:
   - LevelData.waypoints and connections
   - GameConstantsData tile and wait constants
   - Enemy aggression and sight checks
5. Runtime flow summary:
   - Patrol selects closest waypoint, steers toward target, and snaps to center on arrival.
   - Arrival logic handles both near-center and overshoot detection using velocity and dot product checks.
   - Wait timer is randomized, then next waypoint is selected from connections or fallback random choice.
   - AIComponent integrates LOS and aggression logic and delegates idle movement to patrol.
6. Behavioral notes:
   - Visibility and attack/chase switching are coupled with patrol through shared AI state updates.
7. Tests:
   - tests/test_waypoint_patrol_component.gd
   - tests/test_ai_component.gd
8. Remaining gaps:
   - None for deterministic waypoint arrival/overshoot/next-waypoint selection or AI transition coverage related to patrol fallback paths.
9. Legacy mapping:
   - Keep minimal references while parity verification is still in progress.