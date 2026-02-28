# Phase 4: Enemy AI & Combat

## Steps

- [ ] Assemble `Enemy.tscn` by composing shared components onto a `CharacterBody2D` host.
- [ ] Add `WaypointAIComponent` for patrol/aggression behavior.
- [ ] Build `Bullet.tscn` from `MovementComponent` + `HitboxComponent`.
- [ ] Build `Blast.tscn` from `AnimatedSprite2D` + `HitboxComponent`.
- [ ] Wire up damage routing: `HitboxComponent` → `HealthComponent.take_damage()` → `died` signal → blast/score.
