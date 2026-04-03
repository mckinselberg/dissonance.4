# Scene Onboarding

## Purpose

This note is the fastest way for a new engineer to understand how `res://scenes/main.tscn` is organized after the editor-preview refactor work.

Open `main.tscn` first. The scene tree should now explain most of the playable structure without requiring a read-through of `main_scene_setup.gd`.

## Top-Level Ownership

`Main` now separates content by responsibility:

- `World`: static level shell, architecture, fog volumes, streetscape geometry, world extension builders, and terminus content
- `Gameplay`: player, drone, drone route, takedown/progression anchors, and other runtime-driven actors
- `SceneProps`: authored or editor-generated non-critical props and preview content
- `Zones`: zone volumes that affect the player state model
- `Collectibles`: collectible instances and the collection manager
- `UI`: player-facing interface, including `PlayerHUD` and the baseline `PauseMenu`
- `Debug`: optional debugging overlays and tools

## What To Read In The Editor

If you are trying to understand the game quickly, inspect the tree in this order:

1. `Gameplay/Player`
2. `Gameplay/Drone`
3. `Gameplay/DroneRoute`
4. `Gameplay/FaultRelay`
5. `Zones`
6. `Collectibles`
7. `SceneProps`
8. `World`
9. `UI/PlayerHUD`
10. `UI/PauseMenu`

That order gives you the core loop first, then the authored support structure.

Inside `Gameplay/FaultRelay`, the current takedown foundation is intentionally readable in-editor:

- `ControlBox`, `ControlLight`, and `StatusLabel` define the interact point
- `MaintenanceNote` communicates the boulevard-world clue for the takedown window
- `FaultZone` and `FaultPreview` show where the drone must be lured
- `CrashMarker`, `CrashLight`, and `CrashLabel` define the post-takedown handoff space

## Authored Vs Procedural

The current rule of thumb is:

- authored or `@tool`-generated content should explain the space
- runtime code should mostly wire behavior and light dynamic variation

Examples of content that should be understandable in the editor:

- navigation-shaping geometry
- zone placement
- collectible placement
- main HUD structure
- major landmarks and supporting props

Examples of content that can still stay procedural:

- audio synthesis
- threat and state-model behavior
- motion variation
- optional debug helpers

## Runtime Setup Expectations

`res://scripts/main_scene_setup.gd` still matters, but it should now feel like wiring rather than hidden content construction.

It currently:

- resolves key scene references
- connects the drone to route and player
- applies a small amount of runtime variation
- removes the obsolete rear wall so the extended boulevard stays reachable
- warns when required authored content roots or UI scenes are missing

If you find yourself adding major spatial content only in runtime setup, that is usually a sign the content belongs in the scene tree instead.

If the game now warns about missing `SceneProps`, `Zones`, `Collectibles`, `UI/PlayerHUD`, `UI/PauseMenu`, or `Collectibles/CollectionManager`, treat that as a scene-authoring problem to fix in `main.tscn`, not something to patch by adding more fallback spawning.

## DevHUD

`Debug/DevHUD` is now disabled by default so the production-facing HUD is the first interface visible to new engineers.

If you need the lighting and fog tuning overlay:

1. Select `Debug/DevHUD` in `main.tscn`
2. In the Inspector, enable `debug_overlay_enabled`
3. Run the scene
4. Use `F1` to toggle the overlay

When the overlay is disabled, it does not build its UI or bind its toggle input.

## Pause And Settings Baseline

`UI/PauseMenu` is now the minimum production-facing pause/settings layer for repeated slice playtests.

It currently provides:

- resume
- restart
- mouse sensitivity tuning
- master volume tuning
- fullscreen toggle
- core keyboard rebinding for movement and player actions

The pause menu uses `ui_cancel` and is intended to be the starting point for the broader slice-ready settings flow.

## Current Practical Workflow

For most feature work:

1. Open `main.tscn`
2. Confirm which ownership root your change belongs to
3. Prefer authored scene changes or `@tool` builder changes for spatial content
4. Use runtime scripts for behavior, state, and optional dynamic variation
5. Re-check node paths if you move anything across top-level ownership roots

## Related Docs

- `scene-architecture-contract.md`
- `editor-preview-epic.md`
- `bmad-product-brief.md`
