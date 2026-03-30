# Dissonance Surveillance Boulevard

Godot 4.6 first-person exploration and stealth prototype set on a fog-soaked surveillance boulevard. The project combines procedural audio, a player state model, dynamic zone-based pressure, and a patrolling drone that reacts to signal, noise, and line of sight.

## Overview

This repository contains a playable Godot project, not just a scene study. The current build focuses on mood, traversal, and systemic pressure:

- First-person movement with head-bob, sprinting, jumping, and a flashlight.
- A surveillance drone with patrol, warning, and pursuit states.
- Zone-driven player state simulation affecting stealth and burnout pressure.
- Collectible musical pickups with fully procedural sound synthesis.
- Layered fog, wet-surface lighting, and reusable environmental props.

## Requirements

- Godot `4.6` with the `Forward+` renderer

## Getting Started

1. Clone the repository.
2. Open the project folder in Godot 4.6.
3. Run [`scenes/main.tscn`](scenes/main.tscn) or press Play in the editor.

Project entrypoint:

- Main scene: `res://scenes/main.tscn`
- Project file: `res://project.godot`

## Controls

- `WASD`: move
- `Mouse`: look
- `Shift`: sprint
- `Space`: jump
- `F`: toggle flashlight
- `R`: regulate
- `E`: rest when inside a rest zone
- `F1`: open dev HUD
- `Esc`: release mouse
- `Left Click`: capture mouse again

## Core Systems

### Drone detection

The drone evaluates the player through three channels:

- `Signal`: driven by the player state model
- `Noise`: driven by movement and footsteps
- `Visual`: driven by line of sight and movement visibility

Attention rises toward warning and detection thresholds, then decays slowly when stimuli drop off.

### Player state model

The player accumulates environmental pressure from overlapping zones. Those inputs update five core values:

- `focus`
- `energy`
- `social_load`
- `sensory_load`
- `mood`

Derived values such as `signal_visibility`, `harmonic_coherence`, and `burnout_risk` feed directly into stealth and game-over pressure.

### Procedural audio

No imported audio assets are required. Footsteps, drone hum, alert cues, shrieks, and collectible sounds are synthesized in GDScript via `AudioStreamGenerator`.

## Project Structure

- [`project.godot`](project.godot): Godot project configuration
- [`scenes/main.tscn`](scenes/main.tscn): main playable scene
- [`scenes/drone.tscn`](scenes/drone.tscn): drone scene
- [`scenes/streetlight.tscn`](scenes/streetlight.tscn): reusable streetlight
- [`scenes/tower_block.tscn`](scenes/tower_block.tscn): reusable skyline tower
- [`scripts/player_controller.gd`](scripts/player_controller.gd): movement, input, footsteps, state updates
- [`scripts/drone.gd`](scripts/drone.gd): patrol, detection, pursuit, drone audio
- [`scripts/state_model.gd`](scripts/state_model.gd): player state simulation
- [`scripts/player_hud.gd`](scripts/player_hud.gd): HUD, overlays, burnout handling
- [`scripts/main_scene_setup.gd`](scripts/main_scene_setup.gd): startup wiring and procedural setup
- [`environments/night_env.tres`](environments/night_env.tres): fog and environment settings

## Development Notes

- Large `.tscn` files are easiest to edit in the Godot editor. Avoid broad manual text edits unless the change is tightly scoped.
- The project is currently centered around a single playable scene with reusable instanced sub-scenes.
- `.uid` files are part of the Godot 4 asset graph and should remain committed.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for setup and pull request guidance.

Automation and coding-agent instructions live in [`AGENTS.md`](AGENTS.md).
