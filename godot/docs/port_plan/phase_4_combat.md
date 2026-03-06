# Phase 4: Enemy AI & Combat

## Steps

- [x] Assemble `Enemy.tscn` by composing shared components onto a `CharacterBody2D` host.
- [x] Add `AIComponent` for behavior.
- [x] Build `Bullet.tscn` from `MovementComponent` + `HitboxComponent`.
- [x] Build `Blast.tscn` from `AnimatedSprite2D` + `HitboxComponent`.
- [x] Wire up damage routing: `HitboxComponent` → `HealthComponent.take_damage()` → `died` signal → blast/score.
