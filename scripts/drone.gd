extends Node3D

@export var hover_amplitude: float = 0.45
@export var hover_speed: float = 0.8
@export var drift_amplitude: Vector3 = Vector3(0.75, 0.0, 0.45)
@export var drift_speed: Vector2 = Vector2(0.23, 0.17)
@export var rotor_speed: float = 14.0
@export var pulse_speed: float = 2.1
@export var pulse_min_energy: float = 2.6
@export var pulse_max_energy: float = 4.0

@onready var rotor_left: MeshInstance3D = $Rotor_Left
@onready var rotor_right: MeshInstance3D = $Rotor_Right
@onready var red_light: OmniLight3D = $RedLight

var _base_position: Vector3
var _time: float = 0.0
var _phase: float = 0.0


func _ready() -> void:
	_base_position = global_position


func _process(delta: float) -> void:
	_time += delta

	var hover_offset := sin((_time + _phase) * hover_speed) * hover_amplitude
	var sway_x := sin((_time + _phase) * drift_speed.x) * drift_amplitude.x
	var sway_z := cos((_time + _phase) * drift_speed.y) * drift_amplitude.z
	global_position = _base_position + Vector3(sway_x, hover_offset, sway_z)

	var bank := sin((_time + _phase) * 0.35) * 0.04
	rotation.z = bank
	rotation.x = sin((_time + _phase) * 0.21) * 0.03

	rotor_left.rotate_y(rotor_speed * delta)
	rotor_right.rotate_y(-rotor_speed * delta)

	var pulse := 0.5 + 0.5 * sin((_time + _phase) * pulse_speed)
	red_light.light_energy = lerp(pulse_min_energy, pulse_max_energy, pulse)


func randomize_motion(seed_value: float) -> void:
	_phase = seed_value
