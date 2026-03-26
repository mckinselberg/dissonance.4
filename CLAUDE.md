# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Dissonance Surveillance Boulevard** — a Godot 4.6 Forward+ first-person atmospheric scene: a moody surveillance-state boulevard with layered fog, skyline silhouettes, a patrolling drone, and procedural audio.

## Running

Open in **Godot 4.6** (Forward+ renderer). Main scene: `res://scenes/main.tscn`. There is no CLI build command — all runs/exports go through the Godot editor or its `godot` binary.

## Architecture

### Scene graph
- `main.tscn` is the only playable scene. It is large (600+ nodes) and hand-composed — avoid bulk edits to `.tscn` files via text as the format is fragile.
- `drone.tscn`, `streetlight.tscn`, `tower_block.tscn` are reusable instanced sub-scenes; multiple copies live inside `main.tscn`.

### Script responsibilities
| Script | Role |
|---|---|
| `player_controller.gd` | First-person movement, head-bob, procedural footstep synthesis via `AudioStreamGenerator` |
| `drone.gd` | Waypoint patrol, hover oscillation, line-of-sight detection, red-light reaction |
| `main_scene_setup.gd` | `_ready()` wiring: passes player ref + drone route to the drone, randomizes phase offsets for drone/mist/lamp energy |
| `mist_controller.gd` | Drifts its `GPUParticles3D` owner on a slow sinusoidal path |
| `drone_route_point.gd` | Thin `Marker3D` wrapper that adds a `wait_time` export |
| `dev_hud.gd` | F1 overlay for live tuning of lights, fog, volumetric density; has a clipboard-copy button |

### Lighting model
Three intentional contributors (mixing them is by design — see README for why light can appear to come from unexpected places):
1. **DirectionalLight3D** — cool, low-energy moonlike fill; global and unbounded.
2. **OmniLight3D streetlights** — warm pools; energy randomized ±5% at startup.
3. **Drone OmniLight3D** — red, pulses between 2.6–4.0; increases to ×1.1 multiplier when player is detected.

Fog is layered: scene-wide depth fog + volumetric fog + three `FogVolume` nodes (two ground layers, one mid layer). Particle mist adds a fourth visual layer.

### Drone detection
`drone.gd` ray-casts toward the player each frame. Attention builds at rate 1.8 and decays at 0.9. On detection the drone slows from 5.5 → 2.86 u/s, turns toward the player faster, and the light intensifies.

### Procedural audio
Footsteps are synthesized entirely in GDScript (no imported audio assets). The synthesis mixes a low body tone (52–68 Hz), a soft slap (180–260 Hz), a splash-noise transient, and a hiss overlay — all with independent exponential decays.

## Tuning reference

- **More oppressive:** lower streetlight energy and directional light energy.
- **Cleaner fog:** reduce `fog_density` and `volumetric_fog_density` in `environments/night_env.tres`.
- **Less light spill:** lower `light_volumetric_fog_energy` on streetlights/drone; increase roughness on `materials/wet_ground.tres`.
- **Dev HUD:** press `F1` in-game; use the "Copy values" button to snapshot current slider state to clipboard.
