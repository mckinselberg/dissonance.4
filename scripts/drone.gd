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
@export var sensitivity: float = 2.5
@export var alert_decay: float = 0.10
@export var warning_threshold: float = 0.30
@export var detection_threshold: float = 0.60
@export var noise_range_factor: float = 0.5
@export var chase_speed: float = 6.5
@export var chase_height: float = 5.5
@export var covered_detection_scale: float = 0.3
@export var stun_duration: float = 5.0
@export var grab_height: float = 2.5
@export var crash_fall_speed: float = 13.0

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
var _pursuing: bool = false
var _disabled: bool = false
var _crash_target: Vector3
var _crash_complete: bool = false

var _hum_player: AudioStreamPlayer3D
var _alert_player: AudioStreamPlayer3D
var _shriek_player: AudioStreamPlayer3D
var _crash_player: AudioStreamPlayer3D
var _hum_playback: AudioStreamGeneratorPlayback
var _shriek_playback: AudioStreamGeneratorPlayback
var _crash_playback: AudioStreamGeneratorPlayback
var _alert_fired: bool = false
var _hum_time: float = 0.0
var _shriek_time: float = 0.0
var _crash_audio_time: float = 0.0
var _crash_audio_active: bool = false
var _stunned: bool = false
var _stun_timer: float = 0.0
var _in_covered_zone: bool = false
const _HUM_MIX_RATE: float = 44100.0


func _ready() -> void:
	add_to_group("drones")
	_base_position = global_position
	_route_position = global_position
	_setup_drone_audio()


func get_alert_level() -> float:
	if _disabled:
		return 0.0
	return _player_attention


func _process(delta: float) -> void:
	_time += delta

	if _disabled:
		_process_disabled(delta)
		_update_audio(delta)
		return

	_in_covered_zone = _check_covered_zone()

	if _stunned:
		_process_stunned(delta)
		_update_audio(delta)
		return

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
		var player_anchor := _player.global_position + Vector3(0.0, chase_height, 0.0)
		var bias := 0.85 if _pursuing else (0.24 * _player_attention)
		anchor_position = anchor_position.lerp(player_anchor, bias)

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


func is_disabled() -> bool:
	return _disabled


func is_stunned() -> bool:
	return _stunned


func apply_smash(impact_position: Vector3) -> void:
	if not _stunned:
		return
	_stunned = false
	_stun_timer = 0.0
	_disabled = true
	_crash_target = impact_position
	_crash_complete = false
	_player_attention = 0.0
	_pursuing = false
	_crash_audio_active = true
	_crash_audio_time = 0.0


func _check_covered_zone() -> bool:
	var covered_zones := get_tree().get_nodes_in_group("covered_zones")
	for zone_node in covered_zones:
		var zone := zone_node as Node3D
		if zone == null:
			continue
		if zone.has_method("contains_point"):
			var inside: bool = zone.call("contains_point", global_position)
			if inside:
				return true
	return false


func _process_stunned(delta: float) -> void:
	_stun_timer -= delta
	if _stun_timer <= 0.0:
		_stunned = false
		return

	# Impaired hover: erratic oscillation
	var stagger_x := sin(_time * 7.3) * 0.35 + sin(_time * 3.1) * 0.18
	var stagger_z := cos(_time * 5.9) * 0.28
	var sag_y := grab_height + sin(_time * 2.1) * 0.12
	global_position.x += stagger_x * delta
	global_position.y = lerpf(global_position.y, _player.global_position.y + sag_y if _player else global_position.y, delta * 2.5)
	global_position.z += stagger_z * delta

	rotation.z = lerp_angle(rotation.z, sin(_time * 9.1) * 0.4, delta * 6.0)
	rotation.x = lerp_angle(rotation.x, cos(_time * 6.7) * 0.3, delta * 5.0)

	var flicker := 0.5 + 0.5 * sin(_time * 22.0 + sin(_time * 4.3) * 3.0)
	red_light.light_energy = pulse_min_energy * flicker

	rotor_left.rotate_y(rotor_speed * delta * 0.35)
	rotor_right.rotate_y(-rotor_speed * delta * 0.35)


func trigger_fault_takedown(crash_position: Vector3) -> bool:
	if _disabled:
		return false
	_disabled = true
	_crash_target = crash_position
	_crash_complete = false
	_player_attention = 0.0
	_pursuing = false
	_waiting_at_waypoint = false
	_wait_timer = 0.0
	_crash_audio_active = true
	_crash_audio_time = 0.0
	return true


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

	var shriek_stream := AudioStreamGenerator.new()
	shriek_stream.mix_rate = _HUM_MIX_RATE
	shriek_stream.buffer_length = 0.3
	_shriek_player = AudioStreamPlayer3D.new()
	_shriek_player.stream = shriek_stream
	_shriek_player.volume_db = -80.0
	_shriek_player.max_distance = 50.0
	_shriek_player.unit_size = 8.0
	add_child(_shriek_player)
	_shriek_player.play()
	_shriek_playback = _shriek_player.get_stream_playback() as AudioStreamGeneratorPlayback

	var crash_stream := AudioStreamGenerator.new()
	crash_stream.mix_rate = _HUM_MIX_RATE
	crash_stream.buffer_length = 0.6
	_crash_player = AudioStreamPlayer3D.new()
	_crash_player.stream = crash_stream
	_crash_player.volume_db = -80.0
	_crash_player.max_distance = 45.0
	_crash_player.unit_size = 7.0
	add_child(_crash_player)
	_crash_player.play()
	_crash_playback = _crash_player.get_stream_playback() as AudioStreamGeneratorPlayback


func _update_audio(_delta: float) -> void:
	if _stunned:
		# Impaired hum: pitch-dropped, stuttering
		var stutter_gate := 1.0 if sin(_time * 11.0) > -0.3 else 0.0
		_hum_player.volume_db = lerpf(-16.0, -8.0, stutter_gate)
		_shriek_player.volume_db = -80.0
		if _hum_playback != null:
			var avail := _hum_playback.get_frames_available()
			if avail > 0:
				_fill_stun_hum_buffer(avail)
		return

	if _disabled:
		_hum_player.volume_db = move_toward(_hum_player.volume_db, -80.0, 1.2)
		_shriek_player.volume_db = -80.0
		if _crash_audio_active and _crash_playback != null:
			var ca_avail := _crash_playback.get_frames_available()
			if ca_avail > 0:
				_fill_crash_buffer(ca_avail)
			var vol_target: float = lerpf(-4.0, -80.0, clampf(_crash_audio_time / 3.0, 0.0, 1.0))
			_crash_player.volume_db = lerpf(_crash_player.volume_db, vol_target, 0.08)
		return

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

	# Shriek: ramps in above warning_threshold, intensifies toward full detection
	if _player_attention > warning_threshold:
		var shriek_norm: float = clamp((_player_attention - warning_threshold) / (1.0 - warning_threshold), 0.0, 1.0)
		_shriek_player.volume_db = lerp(-80.0, -4.0, shriek_norm * shriek_norm)
	else:
		_shriek_player.volume_db = -80.0

	if _shriek_playback != null:
		var shriek_available := _shriek_playback.get_frames_available()
		if shriek_available > 0:
			_fill_shriek_buffer(shriek_available)


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


func _fill_stun_hum_buffer(frame_count: int) -> void:
	# Pitch-dropped (55 Hz) stuttery hum for impaired drone
	var dt := 1.0 / _HUM_MIX_RATE
	for i in range(frame_count):
		var stutter := 1.0 if sin(TAU * 9.5 * _hum_time) > -0.25 else 0.0
		var base_tone := sin(TAU * 55.0 * _hum_time) * 0.55
		var harmonic := sin(TAU * 110.0 * _hum_time) * 0.18
		var crackle := randf_range(-1.0, 1.0) * 0.12
		var sample := (base_tone + harmonic + crackle) * stutter * 0.4
		_hum_playback.push_frame(Vector2(clamp(sample, -0.95, 0.95), clamp(sample, -0.95, 0.95)))
		_hum_time += dt


func _fill_shriek_buffer(frame_count: int) -> void:
	var dt := 1.0 / _HUM_MIX_RATE
	var shriek_norm: float = clamp((_player_attention - warning_threshold) / (1.0 - warning_threshold), 0.0, 1.0)
	var pulse_rate: float = lerp(2.5, 10.0, shriek_norm)
	var base_freq: float = lerp(900.0, 2600.0, shriek_norm)
	for i in range(frame_count):
		# Positive-half squared sine creates sharp pulses
		var pulse_env: float = sin(TAU * pulse_rate * _shriek_time)
		pulse_env = max(0.0, pulse_env)
		pulse_env = pulse_env * pulse_env
		# Fundamental + 3rd harmonic for harshness
		var sample := (sin(TAU * base_freq * _shriek_time) * 0.7 + sin(TAU * base_freq * 3.0 * _shriek_time) * 0.3) * pulse_env * 0.45
		_shriek_playback.push_frame(Vector2(clamp(sample, -0.95, 0.95), clamp(sample, -0.95, 0.95)))
		_shriek_time += dt


func _fill_crash_buffer(frame_count: int) -> void:
	var dt := 1.0 / _HUM_MIX_RATE
	for i in range(frame_count):
		var progress: float = clampf(_crash_audio_time / 2.8, 0.0, 1.0)
		var freq: float = lerpf(110.0, 24.0, progress * progress)
		var stutter_rate: float = lerpf(3.0, 18.0, progress)
		var gate := 1.0 if sin(TAU * stutter_rate * _crash_audio_time) > (-0.25 * (1.0 - progress)) else 0.0
		var sample := sin(TAU * freq * _crash_audio_time) * 0.55
		sample += sin(TAU * freq * 2.73 * _crash_audio_time) * 0.22 * progress
		sample += randf_range(-1.0, 1.0) * 0.18 * progress
		sample *= gate
		_crash_playback.push_frame(Vector2(clamp(sample, -0.95, 0.95), clamp(sample, -0.95, 0.95)))
		_crash_audio_time += dt


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


func set_route_gizmo_visible(visible_state: bool) -> void:
	if _route_gizmo:
		_route_gizmo.visible = visible_state


func _update_route_position(delta: float) -> void:
	var previous_position := _route_position

	if _pursuing and _player != null:
		# Chase mode: move route anchor directly toward player at chase height
		var chase_target := Vector3(_player.global_position.x, _player.global_position.y + chase_height, _player.global_position.z)
		_route_position = _route_position.move_toward(chase_target, chase_speed * delta)
	else:
		if _waiting_at_waypoint:
			_wait_timer -= delta
			if _wait_timer <= 0.0:
				_waiting_at_waypoint = false
				_route_index = (_route_index + 1) % _route_points.size()
		else:
			var target_node := _route_points[_route_index]
			var target := target_node.global_position
			var current_speed: float = patrol_speed * lerp(1.0, 0.65, _player_attention)
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
	if _player and _player_attention >= warning_threshold:
		var to_player := _player.global_position - global_position
		var target_yaw_player := atan2(-to_player.x, -to_player.z)
		var yaw_speed := turn_speed * (2.2 if _pursuing else 1.3)
		rotation.y = lerp_angle(rotation.y, target_yaw_player, delta * yaw_speed)
	elif travel.length_squared() > 0.0001:
		var target_yaw := atan2(-travel.x, -travel.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, delta * turn_speed)


func _update_player_attention(delta: float) -> void:
	if _disabled:
		_player_attention = move_toward(_player_attention, 0.0, alert_decay * delta)
		_pursuing = false
		return
	if _player == null:
		_player_attention = move_toward(_player_attention, 0.0, alert_decay * delta)
		return

	if _stunned:
		_player_attention = move_toward(_player_attention, 0.0, alert_decay * delta)
		return

	if _player.get("jammer_active") == true:
		_player_attention = move_toward(_player_attention, 0.0, alert_decay * 5.0 * delta)
		_pursuing = false
		return

	var to_player := _player.global_position - global_position
	var dist := to_player.length()
	var dist_factor: float = clamp(1.0 - dist / detection_range, 0.0, 1.0)

	# ── Signal channel: internal state (no LOS required) ────────────
	var signal_vis: float = 0.0
	var coherence: float = 0.5
	var player_state = _player.get("state")
	if player_state != null:
		signal_vis = float(player_state.get("signal_visibility"))
		coherence = float(player_state.get("harmonic_coherence"))
	var coherence_shield: float = lerp(1.0, 0.72, coherence)
	var signal_rate: float = signal_vis * dist_factor * coherence_shield

	# ── Noise channel: footsteps and landing (no LOS required) ──────
	var noise_dist_factor: float = clamp(1.0 - dist / (detection_range * noise_range_factor), 0.0, 1.0)
	var noise_stim: float = 0.0
	if "noise_stimulus" in _player:
		noise_stim = float(_player.get("noise_stimulus"))
	var noise_rate: float = noise_stim * noise_dist_factor

	# ── Visual channel: movement visibility (LOS required) ──────────
	var visual_rate := 0.0
	if dist <= detection_range:
		var space_state := get_world_3d().direct_space_state
		var query := PhysicsRayQueryParameters3D.create(global_position, _player.global_position + Vector3(0.0, 1.4, 0.0))
		query.exclude = [self]
		var hit := space_state.intersect_ray(query)
		if hit.is_empty() or hit.get("collider") == _player:
			var move_vis: float = 0.0
			if "movement_visibility" in _player:
				move_vis = float(_player.get("movement_visibility"))
			# Baseline: existing in LOS is detectable even while still
			var cov_scale := covered_detection_scale if _in_covered_zone else 1.0
			visual_rate = (0.12 + move_vis) * dist_factor * cov_scale

	# ── Combine and accumulate ───────────────────────────────────────
	var total_rate := (signal_rate + noise_rate + visual_rate) * sensitivity
	if total_rate > 0.01:
		_player_attention = clamp(_player_attention + total_rate * delta, 0.0, 1.0)
	else:
		# Decay is slower while pursuing — the drone stays suspicious
		var decay_mult := 0.55 if _pursuing else 1.0
		var decay := alert_decay * (0.6 + (1.0 - dist_factor)) * decay_mult
		_player_attention = clamp(_player_attention - decay * delta, 0.0, 1.0)

	# Update pursuit state with hysteresis to avoid rapid flickering
	if _player_attention >= detection_threshold:
		_pursuing = true
	elif _player_attention < warning_threshold * 0.6:
		_pursuing = false

	# Stun: entering covered space while the drone is actively alarmed
	if _in_covered_zone and _player_attention >= warning_threshold and not _stunned:
		_stunned = true
		_stun_timer = stun_duration
		_pursuing = false
		_player_attention = clampf(_player_attention, 0.0, warning_threshold)


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


func _process_disabled(delta: float) -> void:
	var target := _crash_target
	if not _crash_complete:
		global_position = global_position.move_toward(target, crash_fall_speed * delta)
		if global_position.distance_to(target) < 0.12:
			global_position = target
			_crash_complete = true

	var target_roll := -0.65
	var target_pitch := 0.42
	rotation.z = lerp_angle(rotation.z, target_roll, delta * 4.0)
	rotation.x = lerp_angle(rotation.x, target_pitch, delta * 4.0)
	rotation.y = lerp_angle(rotation.y, rotation.y + 0.18, delta * 0.6)

	rotor_left.rotate_y(rotor_speed * delta * 0.18)
	rotor_right.rotate_y(-rotor_speed * delta * 0.18)

	var flicker := 0.45 + 0.35 * sin(_time * 17.0)
	red_light.light_energy = flicker if not _crash_complete else flicker * 0.45
