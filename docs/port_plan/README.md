# Freedroid → Godot 4 Port Plan

This directory contains the phased implementation plan for porting Freedroid from C/SDL2 to Godot 4.

## Architecture

- [architecture.md](architecture.md) — Architectural mapping (singletons, components, tilemap, takeover)
- [data_migration.md](data_migration.md) — Static conversion of legacy files to `.tres` resources

## Phases

| Phase | File | Summary |
|---|---|---|
| 1 | [phase_1_foundation.md](phase_1_foundation.md) | Godot project setup & static data conversion |
| 2 | [phase_2_components.md](phase_2_components.md) | Component library & map rendering |
| 3 | [phase_3_player.md](phase_3_player.md) | Player entity & interactivity |
| 4 | [phase_4_combat.md](phase_4_combat.md) | Enemy AI & combat |
| 5 | [phase_5_takeover.md](phase_5_takeover.md) | Takeover minigame (UI) |
| 6 | [phase_6_polish.md](phase_6_polish.md) | Audio, polish & state sync |
