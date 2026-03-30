# Contributing

## Setup

- Install `Godot 4.6`.
- Open the repository root as a Godot project.
- Run [`scenes/main.tscn`](scenes/main.tscn) to verify the project loads correctly.

## Workflow

- Create a focused branch for each change.
- Keep commits small enough to review coherently.
- Avoid mixing gameplay tuning, scene composition, and repository-maintenance changes unless they are directly related.

## Code Style

- Follow existing GDScript style and naming in the touched file.
- Prefer explicit, readable logic over compact cleverness.
- Keep tuning values exported when they are expected to be adjusted in the editor.
- Add comments only when the intent is not obvious from the code itself.

## Scene Editing

- Prefer editing large scenes in the Godot editor.
- Be careful with manual `.tscn` changes; node paths and subresource references are easy to break.
- Preserve committed `.uid` files and other project resources needed for stable references.

## Testing

There is currently no automated test suite in the repository. Before opening a PR, manually verify the affected behavior in Godot:

- Project opens without import or parse errors
- [`scenes/main.tscn`](scenes/main.tscn) still runs
- Player movement and camera input still function if touched
- Drone behavior still works if touched
- HUD and state-driven gameplay feedback still work if touched

## Pull Requests

Include:

- A short summary of what changed
- Any manual test coverage you performed
- Screenshots or video for visible environment or UI changes when relevant

If a change modifies balancing, detection thresholds, fog, lighting, or player-state values, call that out explicitly.
