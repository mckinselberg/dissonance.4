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

## Player Promise

The player enters a hostile, surveilled boulevard, learns how exposure and regulation interact, avoids or manipulates drone pressure, recovers in protected spaces, and reaches a memorable endpoint.

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

### 3. State Loop

The slice must include:

- readable HUD feedback
- spaces that calm, restore, or regulate
- moments where the player understands why state matters

### 4. Progression Hook

The slice must include one simple but meaningful short-term objective, such as:

- recover a signal fragment set
- reach a protected destination
- unlock a route or reveal after enough successful traversal

### 5. Atmosphere Hook

The slice must produce strong trailer and screenshot moments:

- boulevard approach
- first drone pressure beat
- one refuge contrast beat
- one dramatic terminus or reveal beat

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

## Metrics To Watch

Qualitative:

- do players understand what caused detection
- do players understand how to recover
- do players describe the game as distinctive
- do players want to continue after the slice ends

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
- settings and accessibility
- QA and playtest instrumentation

## Explicit Non-Goals

The slice does not need:

- a full campaign structure
- multiple enemy archetypes
- broad narrative branching
- final content volume
- console-ready certification work

## Exit Criteria

Once the slice succeeds, the project can safely enter production scaling:

- expand districts with a modular content pipeline
- add progression depth
- add encounter variation
- add stronger narrative framing
- prepare a public demo and store-facing assets
