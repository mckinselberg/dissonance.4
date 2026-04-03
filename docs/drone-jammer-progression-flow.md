# Drone To Jammer Progression Flow

## Purpose

Define the exact vertical-slice progression beat where the player moves from surviving Synod surveillance to briefly repurposing that surveillance machinery.

This is the first concrete proof point for the game's larger thematic arc:

- first, sound is something to hide
- then, sound becomes something to shape

## Slice Role

This flow should be the first meaningful payoff inside the vertical slice.

It proves:

- the player can do more than merely survive patrol pressure
- Synod hardware can be repurposed
- the game's world fiction directly changes mechanics
- sound-based resistance can emerge from stealth play rather than replacing it

## Player-Facing Summary

The player learns the boulevard, avoids drone pressure, discovers a vulnerable drone state, brings one drone down through environmental opportunity, salvages a Synod component, and uses that component to activate a short-range anti-detection jammer that opens the route to the slice endpoint.

## Intended Player Arc

1. the player enters a hostile boulevard and learns to fear the drone
2. the player finds safe pockets and begins understanding regulation and exposure
3. the player notices that the drone and nearby infrastructure are not invulnerable
4. the player triggers or exploits a takedown opportunity
5. the player salvages a jammer component from the fallen drone
6. the player reaches a refuge or relay point where the component can be repurposed
7. the player activates the jammer and uses that brief advantage to cross a previously oppressive space

## Exact Slice Flow

### Beat 1: Pressure Introduction

The player starts with:

- normal movement
- regulation and rest actions
- flashlight
- no anti-detection tool

The first patrol drone should establish:

- line-of-sight pressure
- behavioral scrutiny
- unsafe exposure along the boulevard spine

### Beat 2: Discovery Of Vulnerability

The player discovers a world clue that Synod drones are vulnerable to local infrastructure faults.

Recommended expression:

- sparking conduit
- unstable streetlight junction
- maintenance note
- damaged emitter near the route

The clue should tell the player:

- the drone cannot simply be shot or arbitrarily disabled
- it can be brought down through a specific situational opportunity

### Beat 3: Takedown Setup

The player must prepare or wait for a short takedown window.

Recommended vertical-slice version:

- lure the drone into a marked fault zone
- trigger the fault while the drone is inside it

The takedown should require:

- reading the route
- using space and timing
- tolerating pressure long enough to create the opening

It should not require:

- a full combat system
- precision projectile mechanics
- a large puzzle chain

### Beat 4: Drone Disable Event

When the takedown succeeds:

- the drone loses altitude
- the patrol loop stops
- the audio state changes dramatically
- a crash site becomes available as a short-lived opportunity space

The disable event should be readable through:

- visual descent
- harsher procedural audio breakup
- clearer lighting shift
- one obvious salvage prompt

### Beat 5: Salvage

At the crash site, the player retrieves a single slice-critical part.

Recommended item identity:

- `Signal Phase Regulator`

Design rule:

- the salvage should feel like repurposed surveillance hardware, not generic scrap

The pickup should communicate:

- this is a control component
- it can be inverted or retuned
- it is the seed of the jammer

### Beat 6: Repurpose Point

The player cannot instantly use the part at the crash site.

They must reach a safer repurpose point, such as:

- a refuge room
- a hidden maintenance nook
- a sheltered relay box

At that point, the player performs a short interaction that converts the part into a jammer charge or jammer tool state.

Recommended slice simplification:

- a single interact prompt
- one short audiovisual tuning sequence
- immediate tool unlock

### Beat 7: Jammer Use

The jammer should be intentionally limited.

For the slice, it should:

- create a short anti-detection window
- reduce or disrupt drone tracking in a local radius
- make a single dangerous crossing newly viable

It should not yet:

- become a permanent "stealth solved" button
- disable all surveillance everywhere
- turn the game into an action game

Recommended slice behavior:

- one charge
- short duration
- obvious audiovisual field effect
- strong value in one authored traversal segment

### Beat 8: Endpoint Unlock

The jammer use should directly enable the slice endpoint.

Examples:

- cross a high-exposure plaza to the terminus
- move through a previously impossible drone-controlled checkpoint
- reach a protected signal cache or hidden refuge door

The player should leave the slice feeling:

- "I learned how the system works"
- "I turned their infrastructure against them"
- "This game can grow into stronger sound-based resistance later"

## Required Authored Content

The slice should include authored support for this flow:

- one patrol drone and readable route
- one fault zone or takedown opportunity
- one crash-site interaction marker
- one salvage pickup state
- one repurpose station
- one jammer-enabled traversal gate or dangerous crossing

## Required Systems

Minimum systems needed:

- drone takedown state
- crashed drone state
- salvage interaction
- jammer unlocked state
- jammer activation behavior
- one route or gate that responds to jammer use

## Failure And Recovery Rules

Failure should remain recoverable.

Rules:

- failing the takedown setup should reintroduce pressure, not hard-fail the slice
- the player should be able to retreat and regulate
- the takedown window should reset cleanly
- salvage should not be missable once the drone is down

## UX And Feedback Requirements

The player must always understand:

- why the takedown worked
- what part was salvaged
- where to bring it
- what the jammer does
- why the jammer matters for the next space

Required feedback surfaces:

- HUD objective text or short prompts
- readable world landmarking
- distinctive drone audio failure state
- distinctive jammer audio and visual field state

## Acceptance Criteria

This progression flow is ready for implementation when:

1. the takedown opportunity can be explained in one sentence
2. the salvage item has a clear world identity
3. the repurpose point has a clear spatial location in the slice
4. jammer use solves one authored traversal problem without trivializing stealth overall
5. the sequence can be broken into small implementation tasks across gameplay, world, UI, and audio

## Immediate Implementation Breakdown

1. author the takedown opportunity space in the district
2. define the drone's disable/crash state transitions
3. create the salvage interaction and inventory/state flag
4. author the repurpose point and unlock interaction
5. implement one-charge jammer behavior
6. gate one endpoint traversal segment behind jammer use
