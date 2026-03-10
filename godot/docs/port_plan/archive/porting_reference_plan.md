# Porting Reference Document Plan

## Purpose

Create a single implementation-first reference document that helps contributors work in Godot without repeatedly consulting legacy C code for already-ported behavior.

The reference should answer:

- What is already implemented in Godot?
- Where is that implementation located?
- What behavior is canonical now?
- What remains unported or only partially ported?

## Why This Exists

Current phase documents are strong for roadmap sequencing, but they are not optimized for day-to-day implementation lookup. A dedicated reference reduces context-switching to legacy files and lowers onboarding time.

## Scope

Include:

- Features that are already implemented or partially implemented in Godot.
- Canonical Godot ownership for each feature (scene, component, autoload, data resource).
- Known deviations from legacy behavior.
- Test coverage status and representative tests.
- Open gaps (without requiring legacy deep-dives for known behavior).

Exclude:

- Detailed migration procedures (stay in `data_migration.md`).
- High-level architecture rationale (stay in `architecture.md`).
- Long-form design proposals for future systems.

## Document Location and Naming

Proposed path for the final reference:

- `docs/port_plan/porting_reference.md`

This file (`porting_reference_plan.md`) defines how that reference is produced and maintained.

## Information Model (Per Feature)

Each feature entry in `porting_reference.md` should use a fixed template:

1. Feature name
2. Status: `implemented`, `partial`, or `not started`
3. Canonical Godot implementation
4. Data dependencies
5. Runtime flow summary
6. Behavioral notes (including intentional divergence)
7. Tests
8. Remaining gaps
9. Legacy mapping (minimal, only for unresolved gaps)

### Canonical Godot Implementation

Must list exact paths, for example:

- `components/weapon_component.gd`
- `entities/projectiles/bullet.gd`
- `autoloads/bullet_manager.gd`

This is the primary mechanism for reducing legacy code dependence.

## Authoring Rules

- Treat Godot implementation as the source of truth when status is `implemented`.
- Keep legacy references short and optional when behavior is already clear in Godot.
- Use legacy references only when status is `partial` or unresolved.
- Prefer precise file paths over prose.
- Keep entries compact and update-friendly.

## Rollout Plan

### Step 1: Create the Reference Skeleton

Create `docs/port_plan/porting_reference.md` with:

- Purpose and usage guidance
- Global status legend
- Feature table of contents
- Empty sections for feature categories

### Step 2: Seed Implemented Feature Entries

Start with high-usage systems:

1. Player movement and input
2. Droid stats
3. Projectile stats
4. Projectile lifecycle and collision routing
5. Health/damage flow
6. Doors/elevators interaction flow
7. Enemy waypoint patrol baseline

### Step 3: Add Test Cross-References

For each seeded feature, add:

- Existing test files in `tests/`
- Missing test notes where behavior is currently unverified

### Step 4: Mark Divergences Explicitly

Capture intentional differences from legacy behavior in a dedicated `Divergences` subsection per feature.

### Step 5: Maintenance Workflow

When a feature PR lands:

1. Update code.
2. Update related tests.
3. Update corresponding `porting_reference.md` entry in the same PR.

## Starter Feature Inventory

Initial categories for `porting_reference.md`:

- Core runtime and autoload coordination
- Entity components (movement, health, weapon, hit/hurt)
- Projectiles and effects
- Level loading and tile interactions
- Enemy AI and state machine behavior
- UI and takeover systems
- Save/config and progression systems

## Ownership

- Primary owner: active porting contributor touching the feature.
- Review expectation: PR reviewers verify reference updates for behavior-affecting changes.

## Quality Bar

A feature entry is considered complete when:

- Status is set and justified.
- Canonical Godot files are listed.
- Runtime behavior is described in 5-10 lines.
- Test references exist (or explicit missing-test note exists).
- Legacy mapping is absent or minimal when feature is implemented.

## Definition of Done (For The Reference Initiative)

The initiative is complete when:

- `docs/port_plan/porting_reference.md` exists.
- All currently implemented gameplay-critical systems have entries.
- Team can answer routine behavior questions from this reference without opening legacy C files in most cases.

## Open Decisions

- Whether to split one large reference file into category files once it grows.
- Whether to require reference updates as a CI lint/checklist gate.
- Whether to add a compact changelog section at the top of the reference.
