# BMAD Next Production Milestone

## Milestone

`Vertical Slice Foundation`

## Why This Milestone Exists Now

The project has finished a meaningful architecture-and-onboarding cleanup pass.

That work should now pay off by enabling the first production-facing milestone built on the new structure rather than continuing indefinite POC refactoring.

This milestone uses the clearer scene ownership model to move the game from:

- playable prototype with improving structure

to:

- production-ready vertical-slice foundation with reliable content workflows

## BMAD Framing

### Brief

Deliver the smallest production-grade milestone that proves the game can now be built and tuned through clear scene ownership rather than code archaeology.

### Model

Use the current root contract in `main.tscn` as the operational model:

- `World`
- `Gameplay`
- `SceneProps`
- `Zones`
- `Collectibles`
- `UI`
- `Debug`

Treat those roots as the ownership boundaries for all milestone tasks.

### Act

Implement the milestone in narrow slices that preserve the new structure.

### Debug

Review each slice both in runtime behavior and in editor clarity.

## Milestone Goal

Reach a point where the team can build and tune the vertical slice with confidence because:

- the scene tree is understandable
- the gameplay loop is readable
- content placement is editor-visible
- the next production systems can be added without reopening scene-ownership chaos

## Milestone Deliverables

### 1. Vertical-Slice Foundation Checklist

- stable `main.tscn` ownership layout
- validated scene onboarding flow
- no critical hidden content placement
- player, drone, zones, collectibles, and HUD all readable in-editor

### 2. Production Baseline Systems

- settings menu baseline
- input rebinding baseline
- pause flow baseline
- save/load foundation
- accessibility baseline for testing

### 3. Slice Progression Proof Point

Implement the current best progression hook from the planning docs:

- drone pressure
- drone disable or takedown event
- salvage of Synod hardware
- unlock or prototype an anti-detection audio jammer

This does not need the full long-term sound-resistance system yet.
It needs one strong, playable proof point.

### 4. Content Pipeline Hardening

- convert remaining fragile runtime fallbacks into explicit authored expectations or validation warnings
- document where new world content, zones, collectibles, and UI elements belong
- keep builder behavior predictable for engineers and agents

Current progress:

- `main_scene_setup.gd` now warns for missing authored content roots and legacy node paths instead of silently recreating major UI/content structure
- `Collectibles/CollectionManager` is now treated as an authored expectation for the vertical-slice path

### 5. External Playtest Readiness

- enough stability to support guided external playtests
- enough clarity to collect feedback on stealth readability, state pressure, and world identity

## Workstreams

### Scene Architecture

- preserve the new ownership model
- reduce remaining ambiguity inside `World`
- start replacing transition-time fallback spawning with validation

### Player And State Model

- confirm state feedback remains readable
- tune burnout, regulation, and recovery pacing for the slice

### Drone And Stealth

- improve readability of warning, pursuit, and recovery
- support the salvage-to-jammer progression beat

### World And Content

- use the clearer roots to author one polished district flow
- reinforce the world fiction through landmarks, signage, and safe/unsafe contrast

### UI And UX

- keep `UI/PlayerHUD` authored and inspectable
- add the minimum production-facing menus and flows needed for slice testing

### Debug And Validation

- keep `DevHUD` optional
- add validation-oriented checks where runtime fallbacks still exist

## Acceptance Criteria

This milestone succeeds when:

1. a new engineer can open `main.tscn` and understand where to add new slice content
2. the slice-critical content is readable in the editor before pressing Play
3. the player can complete a short progression loop that includes surveillance pressure and a meaningful payoff
4. the project has the baseline settings and UX expected for repeated playtests
5. the team can plan the remainder of the vertical slice as content expansion, not architecture rescue

## Immediate Backlog

1. audit `main_scene_setup.gd` fallbacks and mark which should become validation warnings next
2. define the exact drone-disable-to-jammer flow for the slice
3. add minimum settings and pause flows under `UI`
4. document validation steps for Godot 4.6 slice review sessions
5. identify whether `World` needs sub-roots before more district content is added
