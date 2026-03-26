# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Dissonance Surveillance Boulevard** — a Godot 4.6 Forward+ first-person stealth/exploration game set on a surveillance-state boulevard. Features layered fog, a dusk sky, a patrolling drone, player mental-state simulation, musical collectibles, and entirely procedural audio.

## Running

Open in **Godot 4.6** (Forward+ renderer). Main scene: `res://scenes/main.tscn`. There is no CLI build command — all runs/exports go through the Godot editor or its `godot` binary.

## Architecture

### Scene graph
- `main.tscn` is the only playable scene. It is large (600+ nodes) and hand-composed — avoid bulk edits to `.tscn` files via text as the format is fragile.
- `drone.tscn`, `streetlight.tscn`, `tower_block.tscn` are reusable instanced sub-scenes; multiple copies live inside `main.tscn`.

### Script responsibilities
| Script | Role |
|---|---|
| `player_controller.gd` | First-person movement, head-bob, footstep synthesis, `StateModel` update, zone accumulation, flashlight toggle (F), regulate (R), rest (E) |
| `drone.gd` | Waypoint patrol, hover oscillation, 3-channel detection (signal/noise/visual), red-light reaction, procedural hum + alert chirp + shriek audio |
| `state_model.gd` | `RefCounted` — 5 core values (focus, energy, social_load, sensory_load, mood) → derived signal_visibility, harmonic_coherence, burnout_risk, zone string |
| `zone_area.gd` | `ZoneArea3D extends Area3D` — exported zone properties; fires `register_zone`/`unregister_zone` on player enter/exit |
| `zones_setup.gd` | Procedurally spawns 5 zone volumes at startup (OpenBoulevard, DronePath, AlcoveLeft, AlcoveRight, TuningNook) |
| `scene_props.gd` | Procedurally spawns props: utility boxes, dumpsters, sign plates, puddles, skyline towers, alcove geometry |
| `player_hud.gd` | `CanvasLayer` HUD: StateModel bars, zone label, drone threat overlay + camera jitter, ♪ collectible counter, burnout game-over panel |
| `collectible.gd` | `MusicalCollectible extends Area3D` — billboard symbol, bob animation, collect-on-enter, C-major arpeggio sound |
| `collectibles_setup.gd` | Spawns 10 collectibles along the boulevard; returns `CollectionManager` reference |
| `collection_manager.gd` | Tracks collected count, emits `item_collected` and `all_collected` signals |
| `main_scene_setup.gd` | `_ready()` wiring: drone route + player refs, mist/lamp randomization, spawns props/zones/collectibles/HUD |
| `mist_controller.gd` | Drifts its `GPUParticles3D` owner on a slow sinusoidal path |
| `drone_route_point.gd` | Thin `Marker3D` wrapper that adds a `wait_time` export |
| `dev_hud.gd` | F1 overlay for live tuning of lights/fog/density; day/night presets; master mute toggle; clipboard-copy button |

### Lighting model
Three intentional contributors (mixing them is by design — see README for why light can appear to come from unexpected places):
1. **DirectionalLight3D** — cool, low-energy moonlike fill; global and unbounded.
2. **OmniLight3D streetlights** — warm pools; energy randomized ±5% at startup.
3. **Drone OmniLight3D** — red, pulses between 2.6–4.0; increases to ×1.1 multiplier when player is detected.

Fog is layered: scene-wide depth fog + volumetric fog + three `FogVolume` nodes (two ground layers, one mid layer). Particle mist adds a fourth visual layer.

### Player state model
`StateModel` (RefCounted) runs every frame inside `player_controller.gd`. Zone `Area3D` volumes register/unregister on the player as it moves, accumulating six exposure floats (social, sensory, rest, musical_regulation, solitude_regulation, calming_input). These drive the five core values, which in turn derive `signal_visibility` (stealth metric), `harmonic_coherence` (detection shield), and `burnout_risk`.

Key player inputs: **R** regulate (reduces sensory/signal load), **E** rest (only inside a rest zone), **F** flashlight toggle. Regulate cost should be balanced — free regulate breaks the stealth loop.

### Drone detection
Three parallel channels accumulate `_player_attention` each frame:
1. **Signal** — `signal_visibility × dist_factor × coherence_shield` (no LOS required)
2. **Noise** — `noise_stimulus × noise_dist_factor` (half range; spikes on footsteps and landing)
3. **Visual** — LOS ray-cast + `movement_visibility` (only when player is moving and in sight)

Attention builds toward 1.0, decays faster when distant. Above `warning_threshold` (0.55) a shrieking synth sound begins, pulsing faster as attention climbs. At full detection the drone slows, turns toward the player, and the red light intensifies.

### Burnout game-over
When `burnout_risk ≥ 0.88` for 4 continuous seconds, `player_hud.gd` shows a "SIGNAL OVERLOAD" panel and calls `get_tree().reload_current_scene()` after 2.5s.

### Zone layout
| Zone | Type | Priority | Effect |
|---|---|---|---|
| OpenBoulevard | Social | 3 | social_exposure 0.65, sensory 0.10 |
| DronePath | Sensory | 4 | sensory_exposure 0.80, social 0.15 |
| AlcoveLeft / AlcoveRight | Rest | 5 | rest_input 1.25, calming 0.72, solitude 0.55 |
| TuningNook | Tuning | 6 | musical_regulation 0.95, rest 0.5, calming 0.9 |

Priority determines which zone label is shown in the HUD when zones overlap.

### Musical collectibles
10 `MusicalCollectible` nodes (♩♪♫♬…) are spread from Z=-8 (spawn) to Z=-112 (far end), including inside alcoves. Collecting all triggers the completion panel and emits `all_collected`. Each pickup plays a procedural C-major arpeggio.

### Procedural audio
No imported audio assets anywhere in the project. All sound is synthesized in GDScript via `AudioStreamGenerator` / `AudioStreamGeneratorPlayback`:
- **Footsteps**: body tone (52–68 Hz) + slap (180–260 Hz) + splash transient + hiss; amplitude and decay randomized per step
- **Drone hum**: continuous 110 Hz + 220 Hz + band-limited noise + 12 Hz amplitude chop
- **Drone alert chirp**: 320→640 Hz sweep + 1200 Hz click on rising attention edge
- **Drone shriek**: pulsed harsh tone (900→2600 Hz, 2.5→10 Hz pulse rate) with 3rd harmonic; volume scales quadratically with attention above warning_threshold
- **Collectible pickup**: C5→E5→G5 arpeggio with exponential decay

## Tuning reference

- **More oppressive:** lower streetlight energy and directional light energy, or use the "Night" preset in F1 HUD.
- **Dusk sky warmth:** adjust `background_color`, `ambient_light_color`, and `fog_light_color` in `environments/night_env.tres`. Current palette is deep indigo-purple with mauve fog.
- **Cleaner fog:** reduce `fog_density` and `volumetric_fog_density` in `environments/night_env.tres`.
- **Less light spill:** lower `light_volumetric_fog_energy` on streetlights/drone; increase roughness on `materials/wet_ground.tres`.
- **Drone sensitivity:** `sensitivity`, `alert_decay`, `warning_threshold`, `detection_threshold` are `@export` on `drone.gd`.
- **Burnout timer:** `_BURNOUT_THRESHOLD` and `_BURNOUT_TIME_TO_GAMEOVER` constants in `player_hud.gd`.
- **Dev HUD:** press `F1` in-game; use the "Copy values" button to snapshot current slider state to clipboard.
