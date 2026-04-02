# BMAD Product Brief

## Project

`Dissonance Surveillance Boulevard` is a Godot 4.6 Forward+ first-person stealth and exploration game set in the world of Dissonance, where Synod surveillance infrastructure, SignalNet pattern interpretation, and the suppression of expressive sound shape both moment-to-moment play and long-term progression.

This brief is the planning anchor for humans and AI agents working on the project.

## Product Intent

Build a compact, atmospheric stealth game where the player navigates a hostile boulevard, manages internal overload, avoids drone detection, and seeks moments of regulation and safety.

The game should feel:

- oppressive but readable
- mechanically tense without becoming noisy
- visually legible in motion and in screenshots
- distinct because the stealth loop is shaped by player state, not only line-of-sight

## World Integration Layer

The game should feel inseparable from Dissonance as a setting.

Core systems should read as products of the world:

- The Synod uses surveillance as infrastructure, culture, and behavioral control.
- SignalNet interprets movement, pattern deviations, and signal irregularity, not just visual exposure.
- Music and expressive harmonic structures are culturally suppressed, monitored, or forbidden.
- Architecture, lighting, signage, and ambient sound all function as instruments of compliance.
- The world should show decay, patchwork retrofits, and authoritarian residue rather than clean science-fiction polish.

The player fantasy should evolve along a clear thematic line:

- first, sound is something to hide
- later, sound is something to shape
- eventually, sound becomes a means of regulation, expression, and resistance

## Core Pillars

### 1. Surveillance Stealth

The player is observed, profiled, and interpreted inside a Synod-controlled space designed to normalize compliant behavior.

Must-haves:

- drone patrol pressure
- readable warning and pursuit escalation
- stealth readability through space, light, sound, and state
- escalation that feels systemic: observation, tagging, pursuit, containment
- stealth that includes remaining behaviorally legible as "normal" to SignalNet
- detection that can respond to anomaly, repetition, irregularity, and suspicious patterning

### 2. State-Driven Play

The player’s internal state represents cognitive and sensory overload under surveillance conditions. It is not flavor text. It changes stealth outcomes, recovery options, movement quality, and detection risk.

Must-haves:

- meaningful state model feedback
- zones that alter recovery, exposure, and regulation
- burnout risk that matters during normal play
- pressure from unsafe zones, drones, emitters, and prolonged exposure
- audio irregularity or instability feeding back into risk
- state affecting sound stability, movement composure, and regulation reliability

### 3. Procedural Audio Identity

Audio should remain a signature system rather than a temporary prototype shortcut. In Dissonance, audio is also political, behavioral, and potentially subversive.

Must-haves:

- procedural footsteps
- procedural drone sounds
- procedural collectible feedback
- tunable audio parameters for future production balancing
- drones using tones, warnings, and herding sounds as tools of control
- safe spaces changing acoustic character as well as visual pressure
- harmonic structures feeling dangerous, rare, or forbidden when they appear
- a future-facing path where sound-based tools can become survival and resistance tools

### 4. Dense Atmosphere

The boulevard should feel like a place, not a test map.

Must-haves:

- strong lighting hierarchy
- wet ground and fog layering
- landmark silhouettes and spatial memory
- safe spaces that contrast with exposed spaces
- signs of Synod control, retrofits, and infrastructure decay

## Environmental Story Signals

The environment should imply world truth without relying on long exposition.

Use:

- surveillance retrofits added onto older architecture
- corrupted signage, outdated protocols, and looping public instructions
- damaged emitters, patched conduits, and partial system failures
- traces of suppressed cultural expression hidden in plain sight
- spaces where acoustic deadening or control is visibly intentional

## Target Experience

The player loop should be:

1. enter exposed Synod-controlled space
2. feel surveillance pressure and behavioral scrutiny
3. regulate movement, sound, and internal state
4. use blind spots, safer pockets, and alternate routes
5. notice cracks, anomalies, or exploitable failures in the system
6. recover enough to push deeper toward a reveal, tool, or discovery

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
- Dissonance-specific world expression beyond atmosphere alone
- a clear transition from sound-as-risk to sound-as-tool

## Production Goals

The next major goal is not “more prototype content.”

The next major goal is a vertical slice that proves:

- the game is understandable to new players
- the systems can be tuned without code archaeology
- the scene/content workflow is scalable
- a short polished build creates real player interest
- the game could only exist in the world of Dissonance

An especially strong early proof point is a world-integrated progression beat where the player disables or brings down a drone, salvages its parts, and repurposes that surveillance machinery into an anti-detection audio jammer. This should guide vertical-slice planning without becoming a full mission spec inside this brief.

## Current POC Refactor Goal

Before the project scales, the current POC should be refactored into a clearer production foundation.

That refactor should focus on:

- scene and node ownership clarity
- editor-visible content organization
- replacing hidden runtime content placement with previewable structures
- reducing string-based coupling where production safety matters
- moving prototype tuning toward exported values or resources
- making world logic and gameplay logic feel more tightly connected

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
- Core mechanics should have plausible in-world justification through Synod systems, SignalNet logic, suppression infrastructure, or system decay.

## Near-Term Success Metrics

The next planning cycle is successful if the team delivers:

- a documented scene architecture contract
- editor-visible props, zones, collectibles, and UI ownership
- a production-ready vertical slice scope
- a backlog that can be executed in small, testable tasks
- stronger world-authentic hooks for progression and environmental storytelling

## Out Of Scope For The Next Cycle

- multi-platform release work
- large narrative scripting systems
- broad enemy roster expansion
- content sprawl without a polished slice
- a full crafting or music-composition system spec

## Deliverables For The Next Cycle

- current POC refactor plan
- scene architecture cleanup plan
- editor preview implementation epic
- vertical slice definition
- production backlog grouped by subsystem
- world integration guidelines

## Directional Progression Hooks

These hooks should influence current design decisions without forcing full implementation in the next cycle:

- rogue or modified drones
- non-Synod harmonic systems
- remnants of suppressed musical culture
- salvageable surveillance hardware becoming player tools
- found parts, forbidden symbols, and fragments of audio knowledge contributing to future instruments, motifs, and resistance capabilities

Found objects should not be treated as generic loot. They should feel like pieces of a suppressed expressive language that can later support stealth tools, recovery tools, and forms of subversive musical expression.
