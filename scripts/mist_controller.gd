extends GPUParticles3D

@export var drift_axis: Vector3 = Vector3(1.0, 0.0, 0.3)
@export var drift_amplitude: float = 1.2
@export var drift_speed: float = 0.08

var _base_position: Vector3
var _phase_offset: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	_base_position = global_position
	drift_axis = drift_axis.normalized()


func _process(delta: float) -> void:
	_time += delta
	var offset := sin((_time + _phase_offset) * drift_speed) * drift_amplitude
	global_position = _base_position + drift_axis * offset


func set_phase_offset(value: float) -> void:
	_phase_offset = value
