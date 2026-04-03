# Vertical Slice Definition

## Purpose

Define the smallest polished slice that proves `Dissonance Surveillance Boulevard` is ready to move from prototype mode into production mode.

This is not a content-complete milestone. It is a proof-of-product milestone.

## Slice Goal

Deliver a short, polished, stable build that communicates the game’s unique identity in the first 15 to 20 minutes of play.

The slice must prove:

- the core stealth loop is fun and readable
- the state model meaningfully shapes play
- the atmosphere is commercially compelling
- the current workflow can scale into production
- the setting reads specifically as Dissonance rather than generic surveillance fiction

## Player Promise

The player enters a hostile Synod-controlled boulevard, learns how exposure, behavioral irregularity, and regulation interact, avoids or manipulates drone pressure, discovers cracks in the control system, and reaches a memorable endpoint.

## Required Content In The Slice

### 1. Playable District

One contiguous district with:

- exposed boulevard spaces
- one or more safer side spaces
- at least one interior refuge
- a strong end landmark

### 2. Stealth Loop

The slice must include:

- drone patrol behavior
- warning and pursuit readability
- meaningful choices around movement, sound, and exposure
- recoverable failure pressure
- a sense that systems are profiling anomaly, not only seeing the player

### 3. State Loop

The slice must include:

- readable HUD feedback
- spaces that calm, restore, or regulate
- moments where the player understands why state matters
- pressure from surveillance proximity or unsafe acoustic conditions

### 4. Progression Hook

The slice must include one simple but meaningful short-term objective, such as:

- recover a signal fragment set
- reach a protected destination
- unlock a route or reveal after enough successful traversal

A strong preferred option for the current project is:

- disable or bring down a drone
- salvage its parts
- build or unlock an anti-detection audio jammer from Synod hardware

See `drone-jammer-progression-flow.md` for the exact slice version of this objective.

### 5. Atmosphere Hook

The slice must produce strong trailer and screenshot moments:

- boulevard approach
- first drone pressure beat
- one refuge contrast beat
- one dramatic terminus or reveal beat
- one clear environmental clue that suppressed sound or culture still exists under Synod control

## Required Production Quality For The Slice

### Engineering

- stable scene ownership
- editor-visible core content
- no critical runtime setup ambiguity
- settings and input flow sufficient for testing
- no obvious progression-breaking bugs

### Design

- onboarding is understandable
- player feedback is readable
- stealth consequences are fair
- pacing includes tension and relief
- world fiction and mechanics reinforce each other

### Presentation

- lighting is intentional and consistent
- fog and visibility support readability
- procedural audio is clear and non-fatiguing
- UI is readable at gameplay speed

## Acceptance Criteria

The vertical slice is done when all of the following are true:

- a new player can understand the first objective without developer explanation
- the player can identify safe versus unsafe spaces through environment and feedback
- the drone creates tension without feeling random or unreadable
- regulation and rest feel necessary and useful
- the build is stable enough for external playtesting
- the team can capture marketable footage from the slice
- players can describe at least one way the world’s control systems shape the mechanics

## Metrics To Watch

Qualitative:

- do players understand what caused detection
- do players understand how to recover
- do players describe the game as distinctive
- do players want to continue after the slice ends
- do players notice the connection between surveillance machinery and player tool progression

Quantitative:

- completion rate
- average time to first detection
- average time to first successful recovery
- burnout frequency
- collectible completion rate if collectible objective remains in the slice

## Production Backlog Categories

The slice backlog should be grouped into these workstreams:

- scene architecture
- player and state model
- drone and stealth readability
- world building and landmarks
- HUD and UX
- procedural audio tuning
- world integration and environmental storytelling
- settings and accessibility
- QA and playtest instrumentation

## Explicit Non-Goals

The slice does not need:

- a full campaign structure
- multiple enemy archetypes
- broad narrative branching
- final content volume
- console-ready certification work
- a full crafting or instrument-composition system

## Exit Criteria

Once the slice succeeds, the project can safely enter production scaling:

- expand districts with a modular content pipeline
- add progression depth
- add encounter variation
- add stronger narrative framing
- prepare a public demo and store-facing assets

Longer-term progression may include found parts, forbidden symbols, and fragments of suppressed audio knowledge contributing to tools, instruments, and expressive resistance systems, but that should be treated as a future design track rather than fully specified vertical-slice scope.
