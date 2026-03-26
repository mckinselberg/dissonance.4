extends Node3D

@export var hover_amplitude: float = 0.45
@export var hover_speed: float = 0.8
@export var drift_amplitude: Vector3 = Vector3(0.75, 0.0, 0.45)
@export var drift_speed: Vector2 = Vector2(0.23, 0.17)
@export var rotor_speed: float = 14.0
@export var pulse_speed: float = 2.1
@export var pulse_min_energy: float = 2.6
@export var pulse_max_energy: float = 4.0
@export var patrol_speed: float = 5.5
@export var turn_speed: float = 1.8
@export var detection_range: float = 20.0
@export var route_gizmo_height: float = 0.15

@onready var rotor_left: MeshInstance3D = $Rotor_Left
@onready var rotor_right: MeshInstance3D = $Rotor_Right
@onready var red_light: OmniLight3D = $RedLight

var _base_position: Vector3
var _route_position: Vector3
var _route_points: Array[Node3D] = []
var _route_index: int = 0
var _time: float = 0.0
var _phase: float = 0.0
var _wait_timer: float = 0.0
var _waiting_at_waypoint: bool = false
var _player_attention: float = 0.0
var _player: Node3D
var _route_gizmo: MeshInstance3D

var _hum_player: AudioStreamPlayer3D
var _alert_player: AudioStreamPlayer3D
var _hum_playback: AudioStreamGeneratorPlayback
var _alert_fired: bool = false
var _hum_time: float = 0.0
const _HUM_MIX_RATE: float = 44100.0


func _ready() -> void:
	_base_position = global_position
	_route_position = global_position
	_setup_drone_audio()


func _process(delta: float) -> void:
	_time += delta

	var hover_offset := sin((_time + _phase) * hover_speed) * hover_amplitude
	var sway_x := sin((_time + _phase) * drift_speed.x) * drift_amplitude.x
	var sway_z := cos((_time + _phase) * drift_speed.y) * drift_amplitude.z

	if _route_points.is_empty():
		_route_position = _base_position
	else:
		_update_player_attention(delta)
		_update_route_position(delta)

	var anchor_position := _route_position
	if _player and _player_attention > 0.0:
		var player_anchor := _player.global_position + Vector3(0.0, 6.5, 0.0)
		anchor_position = anchor_position.lerp(player_anchor, 0.24 * _player_attention)

	global_position = anchor_position + Vector3(sway_x, hover_offset, sway_z)

	var bank := sin((_time + _phase) * 0.35) * 0.04
	rotation.z = bank
	rotation.x = sin((_time + _phase) * 0.21) * 0.03

	rotor_left.rotate_y(rotor_speed * delta)
	rotor_right.rotate_y(-rotor_speed * delta)

	var pulse := 0.5 + 0.5 * sin((_time + _phase) * pulse_speed)
	var boosted_max := pulse_max_energy + 1.1 * _player_attention
	red_light.light_energy = lerp(pulse_min_energy, boosted_max, pulse)

	_update_audio(delta)


func randomize_motion(seed_value: float) -> void:
	_phase = seed_value


func _setup_drone_audio() -> void:
	var hum_stream := AudioStreamGenerator.new()
	hum_stream.mix_rate = _HUM_MIX_RATE
	hum_stream.buffer_length = 0.5
	_hum_player = AudioStreamPlayer3D.new()
	_hum_player.stream = hum_stream
	_hum_player.volume_db = -22.0
	_hum_player.max_distance = 35.0
	_hum_player.unit_size = 4.0
	add_child(_hum_player)
	_hum_player.play()
	_hum_playback = _hum_player.get_stream_playback() as AudioStreamGeneratorPlayback

	var alert_stream := AudioStreamGenerator.new()
	alert_stream.mix_rate = _HUM_MIX_RATE
	alert_stream.buffer_length = 0.25
	_alert_player = AudioStreamPlayer3D.new()
	_alert_player.stream = alert_stream
	_alert_player.volume_db = 0.0
	_alert_player.max_distance = 40.0
	_alert_player.unit_size = 6.0
	add_child(_alert_player)


func _update_audio(_delta: float) -> void:
	_hum_player.volume_db = lerp(-22.0, -12.0, _player_attention)

	if _hum_playback != null:
		var available := _hum_playback.get_frames_available()
		if available > 0:
			_fill_hum_buffer(available)

	var detecting := _player_attention > 0.6
	if detecting and not _alert_fired:
		_alert_fired = true
		_synthesize_alert()
	elif not detecting and _player_attention < 0.2:
		_alert_fired = false


func _fill_hum_buffer(frame_count: int) -> void:
	var dt := 1.0 / _HUM_MIX_RATE
	for i in range(frame_count):
		var chop := 1.0 + 0.08 * sin(TAU * 12.0 * _hum_time)
		var base_tone := sin(TAU * 110.0 * _hum_time) * 0.5
		var harmonic := sin(TAU * 220.0 * _hum_time) * 0.2
		var noise := randf_range(-1.0, 1.0) * 0.06
		var sample := (base_tone + harmonic + noise) * chop * 0.38
		_hum_playback.push_frame(Vector2(clamp(sample, -0.95, 0.95), clamp(sample, -0.95, 0.95)))
		_hum_time += dt


func _synthesize_alert() -> void:
	_alert_player.play()
	var playback := _alert_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return

	# Rising chirp: 320 -> 640 Hz over 0.08 s
	var chirp_count := int(0.08 * _HUM_MIX_RATE)
	for i in range(chirp_count):
		var t := float(i) / _HUM_MIX_RATE
		var freq: float = lerp(320.0, 640.0, float(i) / chirp_count)
		var sample := sin(TAU * freq * t) * exp(-t * 8.0) * 0.55
		playback.push_frame(Vector2(sample, sample))

	# Brief silence: 0.03 s
	for _i in range(int(0.03 * _HUM_MIX_RATE)):
		playback.push_frame(Vector2.ZERO)

	# Click transient: 1200 Hz, sharp decay
	var click_count := int(0.04 * _HUM_MIX_RATE)
	for i in range(click_count):
		var t := float(i) / _HUM_MIX_RATE
		var sample := sin(TAU * 1200.0 * t) * exp(-t * 80.0) * 0.7
		playback.push_frame(Vector2(sample, sample))


func set_route(route_root: Node3D) -> void:
	_route_points.clear()
	if route_root == null:
		return

	for child in route_root.get_children():
		if child is Node3D:
			_route_points.append(child)

	if not _route_points.is_empty():
		_route_position = _route_points[0].global_position
		_route_index = 1 % _route_points.size()
		_build_route_gizmo(route_root)


func set_player(player: Node3D) -> void:
	_player = player


func set_route_gizmo_visible(is_visible: bool) -> void:
	if _route_gizmo:
		_route_gizmo.visible = is_visible


func _update_route_position(delta: float) -> void:
	if _waiting_at_waypoint:
		_wait_timer -= delta
		if _wait_timer <= 0.0:
			_waiting_at_waypoint = false
			_route_index = (_route_index + 1) % _route_points.size()
		return

	var target_node := _route_points[_route_index]
	var target := target_node.global_position
	var previous_position := _route_position
	var current_speed: float = patrol_speed * lerp(1.0, 0.52, _player_attention)
	_route_position = _route_position.move_toward(target, current_speed * delta)

	if _route_position.distance_to(target) < 0.35:
		_route_position = target
		var wait_time: float = target_node.get("wait_time")
		if wait_time > 0.0:
			_waiting_at_waypoint = true
			_wait_timer = wait_time
		else:
			_route_index = (_route_index + 1) % _route_points.size()

	var travel := _route_position - previous_position
	if _player and _player_attention > 0.25:
		var to_player := _player.global_position - global_position
		var target_yaw_player := atan2(-to_player.x, -to_player.z)
		rotation.y = lerp_angle(rotation.y, target_yaw_player, delta * turn_speed * 1.3)
	elif travel.length_squared() > 0.0001:
		var target_yaw := atan2(-travel.x, -travel.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, delta * turn_speed)


func _update_player_attention(delta: float) -> void:
	if _player == null:
		_player_attention = move_toward(_player_attention, 0.0, delta)
		return

	var to_player := _player.global_position - global_position
	var in_range := to_player.length() <= detection_range
	var can_see_player := false

	if in_range:
		var space_state := get_world_3d().direct_space_state
		var query := PhysicsRayQueryParameters3D.create(global_position, _player.global_position + Vector3(0.0, 1.4, 0.0))
		query.exclude = [self]
		var hit := space_state.intersect_ray(query)
		can_see_player = hit.is_empty() or hit.get("collider") == _player

	var target_attention := 1.0 if in_range and can_see_player else 0.0
	var rate := 1.8 if target_attention > _player_attention else 0.9
	_player_attention = move_toward(_player_attention, target_attention, delta * rate)


func _build_route_gizmo(route_root: Node3D) -> void:
	var existing := route_root.get_node_or_null("RouteGizmo")
	if existing:
		existing.queue_free()

	if _route_points.size() < 2:
		return

	var gizmo := MeshInstance3D.new()
	gizmo.name = "RouteGizmo"

	var immediate_mesh := ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.82, 0.15, 0.15, 0.85)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, material)
	for point in _route_points:
		var local_point := route_root.to_local(point.global_position + Vector3.UP * route_gizmo_height)
		immediate_mesh.surface_add_vertex(local_point)
	if _route_points.size() > 2:
		var first_point := route_root.to_local(_route_points[0].global_position + Vector3.UP * route_gizmo_height)
		immediate_mesh.surface_add_vertex(first_point)
	immediate_mesh.surface_end()

	gizmo.mesh = immediate_mesh
	route_root.add_child(gizmo)
	_route_gizmo = gizmo
