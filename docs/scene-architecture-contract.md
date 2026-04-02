# Scene Architecture Contract

## Purpose

This document defines how scenes, nodes, and runtime setup should be organized in `Dissonance Surveillance Boulevard` so new engineers and AI agents can understand the game from the Godot 4.6 editor before reading procedural setup code.

## Current Findings

The project already has a strong base scene and some reusable packed scenes:

- `res://scenes/main.tscn`
- `res://scenes/drone.tscn`
- `res://scenes/streetlight.tscn`
- `res://scenes/tower_block.tscn`

The project also uses runtime or `@tool` generation for several systems:

- props
- zone volumes
- collectibles
- HUD
- mist extensions
- world extension content
- building interior content
- boulevard terminus content

This mixed approach is workable, but ownership is not yet obvious enough for onboarding or production scaling.

## Architecture Principles

### 1. Editor-Visible By Default

If a system is important for spatial understanding, it should be visible in the 3D editor.

Examples:

- geometry that affects navigation
- zone volumes
- collectible placement
- major gameplay landmarks
- authored UI scenes

### 2. Procedural For Behavior, Not For Discovery

Procedural code should primarily handle:

- runtime behavior
- variation
- tuning
- effects
- optional rebuilds

It should not be the only place where engineers can discover core level layout.

### 3. Stable Node Contracts

Frequently accessed nodes should have stable names and stable ownership.

Examples already in good shape:

- `Player/Head/Camera3D`
- `Player/FootstepPlayer`
- `Drone/RedLight`
- `StreetLight/LampLight`
- `DroneRoute/RoutePoint_*`

### 4. Small Scene Responsibilities

Each scene or builder should have one clear reason to exist:

- playable level shell
- reusable prop
- enemy scene
- UI scene
- editor preview builder

## Target Root Scene Structure

`main.tscn` should converge on the following top-level layout:

- `Main`
- `World`
- `Gameplay`
- `SceneProps`
- `Zones`
- `Collectibles`
- `UI`
- `Debug`

Suggested ownership:

- `World`: terrain, architecture, fog volumes, world extension, building interior, terminus
- `Gameplay`: player, drone, drone route, runtime managers
- `SceneProps`: non-critical authored props and preview builders
- `Zones`: all `ZoneArea3D` volumes
- `Collectibles`: collectible instances and collection manager
- `UI`: player HUD and future menus
- `Debug`: dev HUD, route gizmos, editor aids

## Authored Vs Procedural Policy

### Must Be Authored Or Editor-Generated

- level-critical geometry
- collision that shapes player routing
- zone placement
- collectible placement
- persistent UI scenes
- anchor nodes used by multiple systems

### May Remain Procedural

- audio synthesis
- motion variation
- light randomization
- fog drift variation
- one-click editor rebuild tools
- debug visualizations

## Node Contract Rules

### Hard Contracts

These names should be treated as stable unless the architecture document is updated:

- `Player`
- `Player/Head`
- `Player/Head/Camera3D`
- `Player/FootstepPlayer`
- `Drone`
- `DroneRoute`
- `StreetLights`
- `FogVolumes`
- `WorldEnvironment`
- `DirectionalLight3D`

### Soft Contracts

These may evolve, but only behind an owning scene or builder:

- props under `SceneProps`
- zone nodes under `Zones`
- collectibles under `Collectibles`
- debug helpers under `Debug`

## Current Risks

### Runtime Ownership Drift

`main_scene_setup.gd` currently spawns props, zones, collectibles, and HUD at runtime. This creates a mismatch between editor understanding and runtime truth.

### Hidden Tuning Overrides

Scene-authored values for fog and lighting are partially overridden at startup, which makes the editor a less reliable preview.

### String-Based Coupling

Some gameplay and UI access depends on string property lookups. This is acceptable in the prototype, but should move toward clearer APIs or typed references in production-facing systems.

## Required Refactors

### Refactor 1: Scene Props Ownership

Move boulevard prop generation into either:

- authored child scenes, or
- an `@tool` builder under `SceneProps`

### Refactor 2: Zone Ownership

All zone volumes should live under a dedicated `Zones` root and be visible in-editor.

### Refactor 3: Collectible Ownership

All collectibles should live under a dedicated `Collectibles` root and be previewable in-editor.

### Refactor 4: HUD Ownership

The player HUD should become a packed scene under `UI`, even if some sub-controls remain code-built during the transition.

### Refactor 5: Scene Defaults Ownership

Move startup-only tuning overrides into:

- scene-authored values
- exported variables
- config resources

Use runtime overrides only when they are intentionally dynamic.

## Validation Rules

Every scene architecture change should verify:

- the project still opens in Godot 4.6
- `res://scenes/main.tscn` still runs
- all critical nodes are visible and understandable in the editor
- drone setup still finds route and player references
- zone registration still works
- collectible counting still works
- procedural audio still plays

## Definition Of Done

This contract is considered implemented when:

- a new engineer can open `main.tscn` and understand the level structure from the scene tree
- important gameplay spaces are visible in the 3D editor
- the majority of scene understanding no longer depends on reading `main_scene_setup.gd`
