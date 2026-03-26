# Dissonance Surveillance Boulevard

Godot 4.6 Forward+ project scaffold for a moody surveillance-state boulevard scene with layered fog, skyline silhouettes, a hovering drone, and first-person exploration.

## Run

- Open the project in Godot 4.6.
- Main scene: `res://scenes/main.tscn`
- Renderer target: Forward+

## Controls

- `WASD`: move
- `Mouse`: look
- `Shift`: sprint
- `Space`: jump
- `Esc`: release mouse
- `Left Click`: capture mouse again

## Structure

- `scenes/main.tscn`: main playable scene
- `scenes/drone.tscn`: hovering drone with red light pulse
- `scenes/tower_block.tscn`: reusable skyline tower with collision
- `scenes/streetlight.tscn`: reusable streetlight with light and collision
- `scripts/player_controller.gd`: grounded first-person controller, head-bob, procedural footsteps
- `scripts/main_scene_setup.gd`: startup randomization for drone, mist, and lamp intensity
- `scripts/mist_controller.gd`: subtle large-scale mist drift
- `environments/night_env.tres`: environment, fog, volumetric fog, glow

## Audio

Footsteps are procedural and do not depend on imported assets. The player script uses `AudioStreamGenerator` to synthesize a damp, wet-pavement step with a soft low body plus noisy splash transient.

## Lighting Notes

The scene intentionally mixes three light contributors:

- A low-energy cool `DirectionalLight3D` for broad moonlike fill.
- Warm `OmniLight3D` streetlights for local pools of light.
- A strong red drone `OmniLight3D` for focal glow in fog.

If light appears to come from unexpected places, the main causes are usually:

- The directional light is global and unbounded, so it can illuminate surfaces even when no obvious fixture is nearby.
- Volumetric fog makes small omni lights appear larger and more spatially diffuse than their source mesh suggests.
- The wet ground material catches highlights aggressively, so reflections can read as displaced light sources.
- Glow exaggerates bright points, especially the drone and lamps, which can make their influence feel wider than the actual node position.

## Common Tuning

- Darker and more oppressive: reduce streetlight energy and directional light energy.
- Cleaner readability: lower `fog_density` and `volumetric_fog_density` in `res://environments/night_env.tres`.
- Less strange light spill: reduce `light_volumetric_fog_energy` on the streetlights and drone, and consider lowering ground material reflectivity by increasing roughness.
