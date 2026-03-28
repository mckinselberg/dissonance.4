extends CharacterBody3D

@export var walk_speed: float = 2.4
@export var sprint_speed: float = 4.8
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.0025
@export var gravity_scale: float = 1.0
@export var camera_fov: float = 65.0
@export var bob_frequency: float = 1.7
@export var bob_amplitude: float = 0.05
@export var footstep_interval_walk: float = 1.0
@export var footstep_interval_sprint: float = 0.62
@export var footstep_volume_db: float = -18.0
@export var footstep_duration: float = 0.12
@export_range(-89.0, 89.0, 0.1) var min_pitch_degrees: float = -80.0
@export_range(-89.0, 89.0, 0.1) var max_pitch_degrees: float = 70.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var footstep_player: AudioStreamPlayer = $FootstepPlayer

var _yaw: float = 0.0
var _pitch: float = 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _head_base_position: Vector3
var _bob_time: float = 0.0
var _footstep_timer: float = 0.0
var _footstep_playback: AudioStreamGeneratorPlayback
var _current_interval: float = 0.58
var _was_on_floor: bool = true

var state: StateModel
var active_zones: Array = []
var noise_stimulus: float = 0.0
var movement_visibility: float = 0.0
var _in_rest_zone: bool = false
var _flashlight: SpotLight3D
var _drone_threat: float = 0.0

const _NOISE_DECAY: float = 4.0
const _NOISE_WALK_STEP: float = 0.25
const _NOISE_SPRINT_STEP: float = 0.55
const _NOISE_LAND: float = 0.70


func _ready() -> void:
	_setup_input_map()
	_yaw = rotation.y
	_pitch = head.rotation.x
	_head_base_position = head.position
	footstep_player.volume_db = footstep_volume_db
	_setup_footstep_audio()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	state = StateModel.new()
	_setup_flashlight()
	_ensure_action("player_flashlight", KEY_F)
	camera.fov = camera_fov


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		return

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	if event.is_action_pressed("player_flashlight"):
		toggle_flashlight()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion:
		var sens: float = mouse_sensitivity * lerp(1.0, 0.55, _drone_threat)
		_yaw -= event.relative.x * sens
		_pitch -= event.relative.y * sens
		_pitch = clamp(_pitch, deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))

		rotation.y = _yaw
		head.rotation.x = _pitch


func _physics_process(delta: float) -> void:
	_drone_threat = _compute_drone_threat()

	var input_vector := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	var direction := (global_basis.x * input_vector.x) + (-global_basis.z * input_vector.y)
	if direction.length_squared() > 0.0:
		direction = direction.normalized()

	var speed := sprint_speed if Input.is_action_pressed("move_sprint") else walk_speed
	var threat_mult: float = lerp(1.0, 0.5, _drone_threat * _drone_threat)
	velocity.x = direction.x * speed * threat_mult
	velocity.z = direction.z * speed * threat_mult

	# Stumble drift: at high threat the player's movements become erratic
	if _drone_threat > 0.35:
		var drift: float = (_drone_threat - 0.35) * (_drone_threat - 0.35) * 3.0
		velocity.x += randf_range(-drift, drift)
		velocity.z += randf_range(-drift, drift)

	if not is_on_floor():
		velocity.y -= _gravity * gravity_scale * delta
	elif Input.is_action_just_pressed("move_jump"):
		velocity.y = jump_velocity
	else:
		velocity.y = 0.0

	move_and_slide()

	if is_on_floor() and not _was_on_floor:
		noise_stimulus = clamp(noise_stimulus + _NOISE_LAND, 0.0, 1.0)
	_was_on_floor = is_on_floor()

	_update_head_bob_and_footsteps(delta, input_vector, speed)
	_update_state_model(delta, speed)
	noise_stimulus = move_toward(noise_stimulus, 0.0, _NOISE_DECAY * delta)
	var is_moving := input_vector.length_squared() > 0.0 and is_on_floor()
	movement_visibility = 0.55 if (is_moving and speed > walk_speed) else (0.22 if is_moving else 0.0)


func _update_head_bob_and_footsteps(delta: float, input_vector: Vector2, speed: float) -> void:
	var planar_speed := Vector2(velocity.x, velocity.z).length()
	var is_moving_on_floor := is_on_floor() and planar_speed > 0.1 and input_vector.length_squared() > 0.0

	var target_interval := footstep_interval_sprint if speed > walk_speed else footstep_interval_walk
	_current_interval = lerp(_current_interval, target_interval, min(delta / 0.3, 1.0))

	if is_moving_on_floor:
		var bob_speed_scale := speed / walk_speed
		_bob_time += delta * bob_frequency * bob_speed_scale * TAU
		var bob_offset_y := sin(_bob_time) * bob_amplitude
		var bob_offset_x := cos(_bob_time * 0.5) * bob_amplitude * 0.45
		head.position = _head_base_position + Vector3(bob_offset_x, bob_offset_y, 0.0)

		_footstep_timer -= delta
		if _footstep_timer <= 0.0:
			_play_footstep()
			_footstep_timer = _current_interval * randf_range(0.88, 1.12)
	else:
		_bob_time = 0.0
		_footstep_timer = 0.0
		head.position = head.position.lerp(_head_base_position, min(delta * 10.0, 1.0))


func _play_footstep() -> void:
	if _footstep_playback == null:
		return

	_generate_footstep_waveform()
	var planar_speed := Vector2(velocity.x, velocity.z).length()
	noise_stimulus = clamp(
		noise_stimulus + (_NOISE_SPRINT_STEP if planar_speed > walk_speed else _NOISE_WALK_STEP),
		0.0, 1.0
	)


func _setup_flashlight() -> void:
	_flashlight = SpotLight3D.new()
	_flashlight.position = Vector3(0.0, 0.0, -0.1)
	_flashlight.light_color = Color(0.95, 0.92, 0.85)
	_flashlight.light_energy = 2.8
	_flashlight.spot_range = 18.0
	_flashlight.spot_angle = 22.0
	_flashlight.spot_angle_attenuation = 0.6
	_flashlight.light_volumetric_fog_energy = 0.6
	_flashlight.shadow_enabled = true
	_flashlight.name = "Flashlight"
	_flashlight.visible = false
	head.add_child(_flashlight)


func toggle_flashlight() -> void:
	_flashlight.visible = not _flashlight.visible


func get_signal_visibility() -> float:
	return state.signal_visibility


func _compute_drone_threat() -> float:
	var drones := get_tree().get_nodes_in_group("drones")
	var max_threat := 0.0
	for drone in drones:
		if not drone.has_method("get_alert_level"):
			continue
		var alert: float = drone.call("get_alert_level")
		var dist: float = global_position.distance_to(drone.global_position)
		var detection_range: float = float(drone.get("detection_range"))
		var dist_factor: float = clamp(1.0 - dist / (detection_range * 1.5), 0.0, 1.0)
		max_threat = max(max_threat, alert * (0.5 + dist_factor * 0.5))
	return clamp(max_threat, 0.0, 1.0)


func register_zone(zone: ZoneArea3D) -> void:
	if not active_zones.has(zone):
		active_zones.append(zone)


func unregister_zone(zone: ZoneArea3D) -> void:
	active_zones.erase(zone)


func _update_state_model(delta: float, speed: float) -> void:
	var is_sprinting := speed > walk_speed
	var is_moving := Vector2(velocity.x, velocity.z).length() > 0.2
	var regulating := Input.is_action_pressed("player_regulate")
	var resting := Input.is_action_pressed("player_rest")

	# Accumulate zone inputs
	var z_social: float = 0.0
	var z_sensory: float = 0.0
	var z_rest: float = 0.0
	var z_musical: float = 0.0
	var z_solitude: float = 0.0
	var z_calming: float = 0.0
	_in_rest_zone = false
	for zone in active_zones:
		z_social += float(zone.get("social_exposure"))
		z_sensory += float(zone.get("sensory_exposure"))
		z_rest += float(zone.get("rest_input"))
		z_musical += float(zone.get("musical_regulation"))
		z_solitude += float(zone.get("solitude_regulation"))
		z_calming += float(zone.get("calming_input"))
		if float(zone.get("rest_input")) > 0.0:
			_in_rest_zone = true

	# Regulate drains energy — mental effort of self-regulation
	var base_task := 0.5 if is_sprinting else 0.14
	var task := base_task + (0.65 if regulating else 0.0)

	# Drone detection feeds directly into stress — being chased is inherently destabilizing
	var threat_sensory := _drone_threat * 0.9
	var threat_social := _drone_threat * 0.5

	state.update_state(
		delta,
		task,
		z_social + threat_social,
		z_sensory + threat_sensory,
		z_rest if (resting and _in_rest_zone) else 0.0,
		(0.82 + z_musical) if regulating else z_musical,
		0.15 if (is_moving and not is_sprinting) else 0.0,
		z_solitude,
		(0.7 + z_calming) if regulating else z_calming,
	)


func _setup_input_map() -> void:
	_ensure_action("move_forward", KEY_W)
	_ensure_action("move_back", KEY_S)
	_ensure_action("move_left", KEY_A)
	_ensure_action("move_right", KEY_D)
	_ensure_action("move_sprint", KEY_SHIFT)
	_ensure_action("move_jump", KEY_SPACE)
	_ensure_action("player_regulate", KEY_R)
	_ensure_action("player_rest", KEY_E)


func _ensure_action(action_name: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for action_event in InputMap.action_get_events(action_name):
		if action_event is InputEventKey and action_event.physical_keycode == keycode:
			return

	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action_name, event)


func _setup_footstep_audio() -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 44100.0
	stream.buffer_length = 0.18
	footstep_player.stream = stream
	footstep_player.play()
	_footstep_playback = footstep_player.get_stream_playback() as AudioStreamGeneratorPlayback


func _generate_footstep_waveform() -> void:
	footstep_player.pitch_scale = 1.0
	if footstep_player.playing == false:
		footstep_player.play()
		_footstep_playback = footstep_player.get_stream_playback() as AudioStreamGeneratorPlayback

	if _footstep_playback == null:
		return

	var mix_rate := 44100.0
	var sample_count := int(footstep_duration * mix_rate)
	var tone_frequency := randf_range(52.0, 68.0)
	var slap_frequency := randf_range(180.0, 260.0)
	var splash_amount := randf_range(0.22, 0.34)
	var hiss_amount := randf_range(0.05, 0.1)
	var phase := randf_range(0.0, TAU)
	var amplitude_scale := randf_range(0.88, 1.0)
	var splash_decay := randf_range(32.0, 40.0)

	for i in range(sample_count):
		var t := float(i) / mix_rate
		var body_envelope := exp(-t * 22.0)
		var splash_envelope := exp(-t * splash_decay)
		var hiss_envelope := exp(-t * 65.0)
		var low_body := sin(TAU * tone_frequency * t + phase) * 0.33
		var soft_slap := sin(TAU * slap_frequency * t) * 0.11 * exp(-t * 30.0)
		var splash_noise := randf_range(-1.0, 1.0) * splash_amount
		var hiss_noise := randf_range(-1.0, 1.0) * hiss_amount
		var sample := (
			(low_body + soft_slap) * body_envelope +
			splash_noise * splash_envelope +
			hiss_noise * hiss_envelope
		) * 0.42 * amplitude_scale
		sample = clamp(sample, -0.95, 0.95)
		_footstep_playback.push_frame(Vector2(sample, sample))
