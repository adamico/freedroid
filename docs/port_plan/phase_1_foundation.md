# Phase 1: Core Foundation, Assets, and Static Conversion

## Steps

- [x] Set up a Godot 4 project using the Forward+ or Compatibility renderer.
- [x] Configure project inputs mapping legacy bindings to the Godot `InputMap`.
- [ ] Build the `RulesetParser.gd` and `MissionParser.gd` `@tool` Editor scripts.
- [ ] Run these tools to bake all legacy `.mission` and `.ruleset` configs into permanent `.tres` static Godot resources.
- [ ] Provide a basic Editor UI plugin to trigger the conversion.
