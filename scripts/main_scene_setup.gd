extends Node3D

@export var walk_speed: float = 6.0
@export var sprint_speed: float = 11.0
@export var vertical_speed: float = 4.0
@export var mouse_sensitivity: float = 0.0025
@export_range(-89.0, 89.0, 0.1) var min_pitch_degrees: float = -80.0
@export_range(-89.0, 89.0, 0.1) var max_pitch_degrees: float = 70.0

@onready var camera: Camera3D = $Camera3D
@onready var drone: Node3D = $Drone
@onready var mist_a: GPUParticles3D = $MistParticles_A
@onready var mist_b: GPUParticles3D = $MistParticles_B
@onready var street_lights: Node3D = $StreetLights

var _yaw: float = 0.0
var _pitch: float = 0.0


func _ready() -> void:
	_setup_input_map()
	randomize()

	if drone.has_method("randomize_motion"):
		drone.call("randomize_motion", randf_range(0.0, TAU))

	for mist in [mist_a, mist_b]:
		if mist.has_method("set_phase_offset"):
			mist.call("set_phase_offset", randf_range(0.0, TAU))

	var energy_scale := randf_range(0.92, 1.05)
	for child in street_lights.get_children():
		var lamp_light: OmniLight3D = child.get_node_or_null("LampLight")
		if lamp_light:
			lamp_light.light_energy *= energy_scale

	_yaw = rotation.y
	_pitch = camera.rotation.x
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(delta: float) -> void:
	_update_first_person_movement(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		return

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	if event is InputEventMouseMotion:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clamp(_pitch, deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))

		rotation.y = _yaw
		camera.rotation.x = _pitch


func _update_first_person_movement(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move_basis := global_transform.basis
	var movement := (-move_basis.z * input_vector.y) + (move_basis.x * input_vector.x)

	if Input.is_action_pressed("move_up"):
		movement += Vector3.UP
	if Input.is_action_pressed("move_down"):
		movement += Vector3.DOWN

	if movement.length_squared() > 0.0:
		movement = movement.normalized()

	var current_speed := sprint_speed if Input.is_action_pressed("move_sprint") else walk_speed
	if Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down"):
		if input_vector == Vector2.ZERO:
			current_speed = vertical_speed

	global_position += movement * current_speed * delta


func _setup_input_map() -> void:
	_ensure_action("move_forward", KEY_W)
	_ensure_action("move_back", KEY_S)
	_ensure_action("move_left", KEY_A)
	_ensure_action("move_right", KEY_D)
	_ensure_action("move_up", KEY_E)
	_ensure_action("move_down", KEY_Q)
	_ensure_action("move_sprint", KEY_SHIFT)


func _ensure_action(action_name: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for action_event in InputMap.action_get_events(action_name):
		if action_event is InputEventKey and action_event.physical_keycode == keycode:
			return

	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action_name, event)
