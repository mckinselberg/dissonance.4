# BMAD Product Brief

## Project

`Dissonance Surveillance Boulevard` is a Godot 4.6 Forward+ first-person stealth and exploration game centered on surveillance pressure, procedural audio, and a player-state simulation that changes stealth readability and recovery.

This brief is the planning anchor for humans and AI agents working on the project.

## Product Intent

Build a compact, atmospheric stealth game where the player navigates a hostile boulevard, manages internal overload, avoids drone detection, and seeks moments of regulation and safety.

The game should feel:

- oppressive but readable
- mechanically tense without becoming noisy
- visually legible in motion and in screenshots
- distinct because the stealth loop is shaped by player state, not only line-of-sight

## Core Pillars

### 1. Surveillance Stealth

The player is observed, pressured, and hunted in a space designed to feel watched.

Must-haves:

- drone patrol pressure
- readable warning and pursuit escalation
- stealth readability through space, light, sound, and state

### 2. State-Driven Play

The player’s internal state is not flavor text. It changes stealth outcomes, recovery options, and pressure.

Must-haves:

- meaningful state model feedback
- zones that alter recovery, exposure, and regulation
- burnout risk that matters during normal play

### 3. Procedural Audio Identity

Audio should remain a signature system rather than a temporary prototype shortcut.

Must-haves:

- procedural footsteps
- procedural drone sounds
- procedural collectible feedback
- tunable audio parameters for future production balancing

### 4. Dense Atmosphere

The boulevard should feel like a place, not a test map.

Must-haves:

- strong lighting hierarchy
- wet ground and fog layering
- landmark silhouettes and spatial memory
- safe spaces that contrast with exposed spaces

## Target Experience

The player loop should be:

1. enter exposed space
2. sense surveillance pressure
3. adjust movement and regulation
4. use safer pockets and alternate routes
5. recover enough to push deeper
6. reach a memorable destination or reveal

## Target Platform

Primary target:

- PC
- keyboard and mouse
- Steam-first launch assumption

Secondary platform decisions should wait until the vertical slice is stable.

## Current Prototype Truths

The current POC already proves:

- a playable Godot 4.6 baseline scene
- a functioning drone patrol and detection loop
- a state model that can influence stealth and recovery
- procedural audio generation without imported sound assets
- a strong atmosphere direction

The current POC does not yet prove:

- production-grade scene ownership
- editor-friendly onboarding
- scalable content authoring
- save/settings/accessibility flows
- content variety and progression
- polished onboarding and payoff

## Production Goals

The next major goal is not “more prototype content.”

The next major goal is a vertical slice that proves:

- the game is understandable to new players
- the systems can be tuned without code archaeology
- the scene/content workflow is scalable
- a short polished build creates real player interest

## Current POC Refactor Goal

Before the project scales, the current POC should be refactored into a clearer production foundation.

That refactor should focus on:

- scene and node ownership clarity
- editor-visible content organization
- replacing hidden runtime content placement with previewable structures
- reducing string-based coupling where production safety matters
- moving prototype tuning toward exported values or resources

## BMAD Working Model

### Brief

Define product intent, goals, scope, and success criteria before implementation work expands.

### Model

Make the scene architecture, gameplay systems, and ownership boundaries explicit so humans and AI agents can act safely.

### Act

Ship work in narrow slices with clear acceptance criteria rather than wide prototype rewrites.

### Debug

Validate each slice against design intent, runtime behavior, and scene/editor consistency.

## Non-Negotiables

- Engine remains Godot 4.6 unless explicitly reapproved.
- Procedural audio remains part of the product identity.
- Scene/node ownership must become more visible in-editor, not less.
- Tuning values should move toward exported variables or resources instead of hidden runtime constants.
- Main playable flow must continue to run from `res://scenes/main.tscn` until a deliberate production restructure replaces it.

## Near-Term Success Metrics

The next planning cycle is successful if the team delivers:

- a documented scene architecture contract
- editor-visible props, zones, collectibles, and UI ownership
- a production-ready vertical slice scope
- a backlog that can be executed in small, testable tasks

## Out Of Scope For The Next Cycle

- multi-platform release work
- large narrative scripting systems
- broad enemy roster expansion
- content sprawl without a polished slice

## Deliverables For The Next Cycle

- current POC refactor plan
- scene architecture cleanup plan
- editor preview implementation epic
- vertical slice definition
- production backlog grouped by subsystem
