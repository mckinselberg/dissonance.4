# AGENTS.md

This file is the repository-level guide for coding agents and automation tools working in this project.

## Project Summary

`Dissonance Surveillance Boulevard` is a Godot 4.6 Forward+ prototype focused on first-person exploration, stealth pressure, procedural audio, and a surveillance-heavy atmosphere.

## Source Of Truth

- Treat this file as the primary automation guide.
- [`CLAUDE.md`](CLAUDE.md) contains deeper project notes and should be kept consistent when guidance overlaps.

## Environment

- Engine: `Godot 4.6`
- Renderer: `Forward+`
- Main scene: `res://scenes/main.tscn`
- Main project file: `res://project.godot`

## Repository Rules

- Do not remove or ignore Godot `.uid` files.
- Do not commit `.godot/`, export credentials, editor cache, or OS-specific junk.
- Assume scene files may be hand-authored and fragile.
- Prefer focused script edits over large blind rewrites of `.tscn` resources.

## Editing Guidance

- Use the Godot editor for broad scene composition changes when possible.
- If a `.tscn` must be edited as text, keep the change minimal and verify node paths and resource references.
- Preserve the procedural-audio approach; do not replace generated sounds with imported assets unless explicitly requested.
- Keep gameplay tuning values easy to adjust through exported variables where practical.

## Key Systems

- [`scripts/player_controller.gd`](scripts/player_controller.gd): movement, input, flashlight, footsteps, state updates
- [`scripts/drone.gd`](scripts/drone.gd): patrol, detection, pursuit, procedural drone audio
- [`scripts/state_model.gd`](scripts/state_model.gd): core player-state simulation
- [`scripts/player_hud.gd`](scripts/player_hud.gd): HUD and burnout pressure feedback
- [`scripts/main_scene_setup.gd`](scripts/main_scene_setup.gd): runtime scene wiring

## Validation Expectations

- At minimum, confirm the project still opens in Godot 4.6.
- For gameplay changes, verify the main loop still runs from [`scenes/main.tscn`](scenes/main.tscn).
- For stealth changes, check drone warning and pursuit behavior.
- For state-model changes, check HUD values, zone transitions, and burnout pressure.
- For audio changes, verify procedural generators still produce output without imported assets.

## Pull Request Guidance

- Keep PRs narrowly scoped.
- Document user-visible behavior changes in the PR description.
- Call out any tuning changes that affect difficulty, lighting, fog density, or detection thresholds.
- Mention manual verification steps when no automated tests exist.
