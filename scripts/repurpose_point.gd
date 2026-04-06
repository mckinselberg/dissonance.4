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
		# Tuning sequence: descends from 440 Hz to 220 Hz as component locks in
		var freq: float = lerpf(440.0, 220.0, progress)
		var warble: float = 1.0 + 0.08 * sin(TAU * 5.5 * t) * (1.0 - progress)
		var amp := sin(PI * progress) * 0.38
		var sample := sin(TAU * freq * warble * t) * amp
		sample += sin(TAU * freq * 2.0 * warble * t) * amp * 0.22
		pb.push_frame(Vector2(clamp(sample, -0.95, 0.95), clamp(sample, -0.95, 0.95)))
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_callback(player_audio.queue_free)
