# Interaction Script Pattern

## Overview

This document captures the scene + script design pattern used in `repurpose_point.gd`.
It is an effective, self-contained approach for any interactive world object where:

- The player walks into a trigger volume
- A label / light reacts to player presence and state
- A single input press performs a conditional action
- The result changes the object's appearance and the player's inventory/state
- Audio is synthesised procedurally and self-cleans up

Use this pattern as a reference template when building new interactable props
(relay stations, terminals, doors, collectible dispensers, etc.).

---

## Node Structure (expected by the script)

```
RepurposePoint (Node3D)     ← root — attach repurpose_point.gd
├── InteractArea (Area3D)   ← body_entered / body_exited wires player presence
├── StatusLabel (Label3D)   ← billboard label, driven by script state
└── ControlLight (OmniLight3D) ← colour-coded status light
```

The script requires no other authored children.
Audio players are created at runtime via `add_child`, cleaned up with a `Tween`.

---

## Script — `scripts/repurpose_point.gd`

```gdscript
extends Node3D

@export var interact_action: StringName = &"player_interact"

@onready var _interact_area: Area3D = $InteractArea
@onready var _status_label: Label3D = $StatusLabel
@onready var _control_light: OmniLight3D = $ControlLight

var _player_inside: bool = false
var _spent: bool = false


func _ready() -> void:
	_interact_area.body_entered.connect(_on_body_entered)
	_interact_area.body_exited.connect(_on_body_exited)
	_sync_label()


func _unhandled_input(event: InputEvent) -> void:
	if not _player_inside or _spent:
		return
	if not event.is_action_pressed(interact_action):
		return
	var player := _find_player()
	if player == null or player.get("has_regulator") != true:
		_status_label.text = "Relay: no component"
		return
	player.set("has_regulator", false)
	player.set("jammer_charges", int(player.get("jammer_charges")) + 1)
	_spent = true
	SaveLoad.has_regulator = false
	SaveLoad.jammer_charges = int(player.get("jammer_charges"))
	SaveLoad.save_game()
	_status_label.text = "Jammer loaded\n[J] to activate"
	_control_light.light_color = Color(0.25, 0.92, 0.62)
	_control_light.light_energy = 3.2
	_play_tuning_audio()
	get_viewport().set_input_as_handled()


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D:
		_player_inside = true
		_sync_label()


func _on_body_exited(body: Node) -> void:
	if body is CharacterBody3D:
		_player_inside = false
		_sync_label()


func _sync_label() -> void:
	if _spent:
		return
	if _player_inside:
		var player := _find_player()
		var has_part := false
		if player != null and player.get("has_regulator"):
			has_part = true
		_status_label.text = "Relay [G] repurpose component" if has_part else "Relay: bring component"
		_control_light.light_color = Color(0.35, 0.92, 0.55) if has_part else Color(0.72, 0.82, 0.98)
		_control_light.light_energy = 2.8 if has_part else 1.6
	else:
		_status_label.text = "Relay: maintenance"
		_control_light.light_color = Color(0.72, 0.82, 0.98)
		_control_light.light_energy = 1.1


func _find_player() -> Node3D:
	for body in _interact_area.get_overlapping_bodies():
		if body is CharacterBody3D:
			return body
	return null


func _play_tuning_audio() -> void:
	var player_audio := AudioStreamPlayer3D.new()
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 44100.0
	stream.buffer_length = 1.8
	player_audio.stream = stream
	player_audio.volume_db = -10.0
	player_audio.max_distance = 14.0
	player_audio.unit_size = 3.0
	add_child(player_audio)
	player_audio.play()
	var pb := player_audio.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	var mix_rate := 44100.0
	var sample_count := int(1.4 * mix_rate)
	for i in range(sample_count):
		var t := float(i) / mix_rate
		var progress: float = clampf(t / 1.4, 0.0, 1.0)
		var freq: float = lerpf(440.0, 220.0, progress)
		var warble: float = 1.0 + 0.08 * sin(TAU * 5.5 * t) * (1.0 - progress)
		var amp := sin(PI * progress) * 0.38
		var sample := sin(TAU * freq * warble * t) * amp
		sample += sin(TAU * freq * 2.0 * warble * t) * amp * 0.22
		pb.push_frame(Vector2(clamp(sample, -0.95, 0.95), clamp(sample, -0.95, 0.95)))
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_callback(player_audio.queue_free)
```

---

## Why This Pattern Works

### 1. Self-contained state machine
`_player_inside` and `_spent` are the only state variables needed.
`_sync_label()` is the single place that translates state → label + light colour.
There is no separate update loop — state changes only on events.

### 2. Input guard chain
`_unhandled_input` checks conditions in order, returns early at each failure,
and calls `set_input_as_handled()` only on success. This prevents input bleed to
other systems and makes the precondition logic read top-to-bottom.

### 3. Player queried by type, not node path
`_find_player()` queries `get_overlapping_bodies()` for any `CharacterBody3D`.
No hardcoded paths. Works regardless of where in the scene tree the player lives.

### 4. Player inventory accessed via `.get()` / `.set()`
The script never `@onready`-refs the player. It only uses the weakly-coupled
`node.get("property")` / `node.set("property")` API. This means the script can
run on any scene that has a compatible player without changes.

### 5. One-shot audio via `add_child` + Tween self-cleanup
No audio nodes are authored in the scene. The procedural audio player is created,
filled with a synthesised waveform, and scheduled for `queue_free()` via a `Tween`.
The object stays clean and the audio lifecycle is entirely local to the function.

### 6. Persistence at the point of change
`SaveLoad.save_game()` is called exactly once, at the moment state changes,
with all fields written immediately before the call. No deferred saves, no risk
of a stale write.

---

## Adapting This Pattern

| New object type | What to change |
|---|---|
| Door / barrier | Replace `_spent` guard with a toggle; replace `_sync_label` with mesh/light swap |
| Collectible dispenser | Swap `has_regulator` check for a currency/key item; emit a signal on collect |
| Terminal / log | Replace audio synth with text panel show/hide; no `_spent` needed (re-readable) |
| Multi-step interaction | Add a `_step: int` counter; `_sync_label` maps step → prompt text |
