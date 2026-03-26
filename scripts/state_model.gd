class_name StateModel
extends RefCounted

## Core internal state, normalized for easier tuning from gameplay scripts.
var focus: float = 0.6
var energy: float = 0.7
var social_load: float = 0.2
var sensory_load: float = 0.2
var mood: float = 0.7

## Derived values used by UI, audio, and stealth logic.
var burnout_risk: float = 0.0
var signal_visibility: float = 0.0
var harmonic_coherence: float = 0.0
var zone: String = "neutral"


func update_state(
	delta: float,
	task_intensity: float,
	social_exposure: float,
	sensory_exposure: float,
	rest_input: float,
	musical_regulation: float,
	movement_regulation: float,
	solitude_regulation: float,
	calming_input: float
) -> void:
	var fatigue_penalty: float = max(0.0, 0.5 - energy) * 2.0
	var coherence: float = 1.0 - abs(focus - energy)
	var overload: float = (social_load + sensory_load) / 2.0
	var burnout_pressure: float = focus * (1.0 - energy)

	focus = clamp(
		focus + delta * (
			0.9 * task_intensity * energy
			+ 0.5 * musical_regulation
			- 0.6 * sensory_load
			- 0.45 * social_load
			- 0.5 * fatigue_penalty
		),
		0.0, 1.0
	)

	energy = clamp(
		energy + delta * (
			0.8 * rest_input
			+ 0.25 * movement_regulation
			- 0.55 * task_intensity
			- 0.35 * sensory_load
			- 0.30 * social_load
		),
		0.0, 1.0
	)

	social_load = clamp(
		social_load + delta * (
			0.8 * social_exposure
			- 0.35 * rest_input
			- 0.45 * solitude_regulation
		),
		0.0, 1.0
	)

	sensory_load = clamp(
		sensory_load + delta * (
			0.9 * sensory_exposure
			- 0.4 * rest_input
			- 0.5 * calming_input
		),
		0.0, 1.0
	)

	mood = clamp(
		mood + delta * (
			0.45 * coherence
			+ 0.35 * musical_regulation
			- 0.4 * overload
			- 0.5 * burnout_pressure
		),
		0.0, 1.0
	)

	burnout_risk = clamp(
		0.45 * focus * (1.0 - energy)
		+ 0.25 * social_load
		+ 0.25 * sensory_load
		+ 0.15 * (1.0 - mood),
		0.0, 1.0
	)

	signal_visibility = clamp(
		0.35 * sensory_load
		+ 0.30 * social_load
		+ 0.20 * (1.0 - mood)
		+ 0.15 * max(0.0, focus - energy),
		0.0, 1.0
	)

	harmonic_coherence = clamp(
		0.5 * (1.0 - abs(focus - energy))
		+ 0.3 * (1.0 - sensory_load)
		+ 0.2 * (1.0 - social_load),
		0.0, 1.0
	)

	zone = _compute_zone()


func _compute_zone() -> String:
	if focus > 0.72 and energy > 0.45 and social_load < 0.4 and sensory_load < 0.4:
		return "deep_focus"
	if focus > 0.70 and energy < 0.38 and burnout_risk > 0.65:
		return "burnout_edge"
	if (social_load > 0.70 or sensory_load > 0.70) and mood < 0.55:
		return "overload"
	if focus >= 0.45 and focus <= 0.72 and energy > 0.55 and mood > 0.5:
		return "exploratory"
	if energy < 0.4 and focus < 0.5 and social_load < 0.55 and sensory_load < 0.55:
		return "recovery"
	return "neutral"
