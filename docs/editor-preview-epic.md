# Editor Preview Epic

## Goal

Make the core playable scene understandable directly inside the Godot 4.6 3D editor so new engineers do not need to reverse-engineer procedural setup code before making changes.

## Problem

The project currently mixes scene-authored content with runtime-generated setup. This is efficient for prototyping, but it creates onboarding friction:

- props are not all visible in the authored scene
- zone volumes are created at runtime
- collectibles are created at runtime
- the HUD is created at runtime
- some authored values are changed at startup

As a result, the editor is not yet a trustworthy preview of gameplay structure.

## Outcome

After this epic:

- engineers can open `main.tscn` and immediately see the main boulevard layout
- core gameplay spaces are visible in the 3D editor
- zone ownership is obvious
- collectible routes are obvious
- UI ownership is obvious
- runtime code focuses on behavior and wiring, not hidden content placement

## Scope

In scope:

- refactoring current POC scene/content ownership where it blocks editor visibility
- scene visibility and ownership
- editor preview builders
- packed scene extraction where useful
- low-risk Godot 4.6 workflow improvements

Out of scope:

- full art overhaul
- major mechanic redesign
- narrative content expansion
- replacing procedural audio

## Proposed Implementation

This epic is also the first concrete refactor step for the current POC.

### Epic 1: Dedicated Scene Roots

Add or formalize these roots inside `main.tscn`:

- `World`
- `Gameplay`
- `SceneProps`
- `Zones`
- `Collectibles`
- `UI`
- `Debug`

Acceptance criteria:

- top-level ownership is readable from the scene tree
- future builder scripts attach only to their intended root

### Epic 2: Previewable Props

Replace runtime-only boulevard prop spawning with one of:

- an `@tool` `ScenePropsBuilder`
- authored prop scenes under `SceneProps`

Acceptance criteria:

- alcoves, puddles, utility props, and skyline additions are visible in-editor
- collision and visuals stay aligned

### Epic 3: Previewable Zones

Move runtime zone creation into editor-visible `ZoneArea3D` nodes or an `@tool` zone builder.

Recommended implementation:

- `Zones` root with authored `ZoneArea3D` children
- optional editor gizmo material or helper mesh for readability

Acceptance criteria:

- all player-affecting zones are visible in-editor
- zone labels and priorities are inspectable in the Inspector

### Epic 4: Previewable Collectibles

Move collectible placement into:

- authored collectible instances under `Collectibles`, or
- an `@tool` collectible builder that creates previewable children

Acceptance criteria:

- the full collectible route is visible in-editor
- collectible count remains easy to maintain

### Epic 5: HUD As A Scene

Convert the runtime HUD creation into a packed scene:

- `res://scenes/player_hud.tscn`

Code may still populate dynamic data, but the UI hierarchy should be inspectable in the editor.

Acceptance criteria:

- anchors, containers, and visual structure are visible in the 2D editor
- HUD can still be wired to player and collection manager at runtime

### Epic 6: Runtime Defaults Cleanup

Reduce hidden startup overrides in `main_scene_setup.gd`.

Move defaults into:

- node-authored values
- exported variables
- config resources

Acceptance criteria:

- editor preview more closely matches play mode
- runtime setup script mostly performs reference wiring and optional dynamic variance

## Suggested Task Breakdown

1. Create root ownership nodes in `main.tscn`
2. Introduce `SceneProps` preview strategy
3. Introduce `Zones` preview strategy
4. Introduce `Collectibles` preview strategy
5. Extract HUD into packed scene
6. Remove or reduce startup-only visual overrides
7. Add a short onboarding note with expected scene tree layout

## Godot 4.6 Implementation Notes

- Use `@tool` only where editor rebuild behavior is intentional and predictable.
- Guard editor builders against duplicate child generation.
- Prefer dedicated container roots over adding generated children directly to `Main`.
- Keep `.tscn` text edits minimal and verify node paths after each scene restructuring step.
- Use exported toggles such as `rebuild_in_editor` or `auto_build_in_editor` to keep preview behavior explicit.

## Risks

### Duplicate Content

If editor builders and runtime builders both remain active, the scene may spawn duplicate props, zones, or collectibles.

Mitigation:

- migrate one subsystem at a time
- retire old runtime spawning as each subsystem becomes editor-visible

### Scene Fragility

`main.tscn` is hand-authored and large.

Mitigation:

- make small scene edits
- verify node paths after each step
- avoid broad structural rewrites in one pass

### Preview/Runtime Drift

Editor previews may still differ if runtime code continues overriding authored values.

Mitigation:

- centralize defaults
- document which values are allowed to change dynamically

## Definition Of Done

This epic is complete when:

- a new engineer can open `main.tscn` in Godot 4.6 and understand the playable layout
- props, zones, collectibles, and HUD ownership are visible without pressing Play
- runtime setup no longer hides major content structure
