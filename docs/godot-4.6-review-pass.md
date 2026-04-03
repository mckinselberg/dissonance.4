# Godot 4.6 Review Pass

## Purpose

This note captures the current repo-level review of the Godot 4.6 onboarding experience after the scene ownership and editor-preview refactor work.

This was a code-and-scene review pass, not an editor-open screenshot pass.

## Overall Assessment

The project is now much closer to the intended onboarding experience.

Strengths:

- the top of `main.tscn` now reads as a real ownership model
- player, drone, route, HUD, zones, collectibles, and authored content roots are visible in-editor
- major hidden runtime-owned structures have been pulled into the scene tree
- the docs now explain both the ownership contract and the practical onboarding path

At this point, the biggest remaining issues are clarity and production hardening, not structural invisibility.

## Lingering Confusion Points

### 1. Top-Level Content Roots Still Mix Spatial And Logical Ownership

`SceneProps`, `Zones`, and `Collectibles` are top-level siblings of `World` and `Gameplay`.

That is a good onboarding compromise, but it can still raise a question for new engineers:

- are these part of the world
- or part of gameplay
- or temporary preview-only roots

Recommendation:

- keep them where they are for now
- treat them as authored content roots referenced by gameplay
- make that language explicit anywhere the root contract is documented

### 2. `World` Contains Both Hand-Authored Geometry And Builder-Owned Content

`World` is now much cleaner, but it still mixes:

- directly authored geometry
- `@tool` or procedural world-building helpers
- extension content like `WorldExtension` and `BoulevardTerminus`

This is acceptable for the POC-to-production transition, but it is the next place a new engineer may hesitate.

Recommendation:

- in the next production milestone, decide whether `World` should gain sub-roots such as:
- `World/StaticGeometry`
- `World/Extensions`
- `World/Atmosphere`

### 3. Runtime Fallback Creation Still Exists

`main_scene_setup.gd` still creates content roots or scenes if they are missing.

That is useful for resilience during refactor work, but it can hide scene mistakes in production if left in place too long.

Recommendation:

- keep fallback creation during the current transition
- replace fallback creation with validation warnings once the vertical-slice content pipeline is stable

### 4. `DevHUD` Is Safer Now, But Still Present In The Main Scene

`Debug/DevHUD` is disabled by default, which is the right move.

The remaining question is whether it should stay in `main.tscn` permanently or move to a more explicit debug-only workflow later.

Recommendation:

- keep it for the vertical slice
- revisit after the slice when debug tooling can be formalized

### 5. Some Docs Still Read Slightly Ahead Of Full Production Reality

The architecture docs now describe the intended structure well, but a few production-sounding phrases may imply a more finalized pipeline than the repo fully has today.

Recommendation:

- keep the current docs
- make future milestone docs more explicit about what is already implemented versus what is planned next

## Review Outcome

The current scene architecture is good enough to support the next BMAD production milestone.

The right next move is no longer another large scene-tree refactor.

The right next move is to use the new structure to deliver a production-facing milestone:

- vertical-slice foundation
- content pipeline hardening
- progression proof point
- settings/save/accessibility baseline

## Suggested Follow-Up Validation

During the next Godot 4.6 hands-on pass, verify:

1. a new engineer can identify where to place new world content without asking
2. zones and collectibles read clearly in the 3D editor without running the scene
3. the authored HUD path feels obvious in `UI`
4. `DevHUD` can be re-enabled intentionally and stays out of the way by default
5. no runtime-created roots are silently masking missing authored content
