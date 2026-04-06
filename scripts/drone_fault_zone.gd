extends Node3D

@export var interact_action: StringName = &"player_interact"
@export var single_use: bool = true

var _player_inside: bool = false
var _spent: bool = false
var _salvage_area: Area3D
var _salvage_label: Label3D
var _player_at_crash: bool = false
var _salvaged: bool = false

@onready var _interact_area: Area3D = $InteractArea
@onready var _fault_zone: Area3D = $FaultZone
@onready var _fault_shape: CollisionShape3D = $FaultZone/CollisionShape3D
@onready var _crash_marker: Marker3D = $CrashMarker
@onready var _status_label: Label3D = $StatusLabel
@onready var _control_light: OmniLight3D = $ControlLight
@onready var _crash_label: Label3D = get_node_or_null("CrashLabel") as Label3D
@onready var _crash_light: OmniLight3D = get_node_or_null("CrashLight") as OmniLight3D
@onready var _maintenance_note: Label3D = get_node_or_null("MaintenanceNote") as Label3D


func _ready() -> void:
	_interact_area.body_entered.connect(_on_interact_body_entered)
	_interact_area.body_exited.connect(_on_interact_body_exited)
	_set_crash_site_active(false)
	_sync_state_text()
	_setup_salvage_area()


func _process(_delta: float) -> void:
	if _spent:
		return
	if _player_inside:
		_sync_state_text()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(interact_action):
		return

	var handled := false

	if _player_inside and not _spent:
		_try_fault_relay()
		handled = true

	if _player_at_crash and not _salvaged:
		_do_salvage()
		handled = true

	if handled:
		get_viewport().set_input_as_handled()


func _try_fault_relay() -> void:
	var drone := _find_target_drone()
	if drone == null:
		_status_label.text = "Fault relay: no target"
		_control_light.light_color = Color(0.98, 0.72, 0.22)
		return
	if drone.has_method("trigger_fault_takedown") and drone.call("trigger_fault_takedown", _crash_marker.global_position):
		if single_use:
			_spent = true
		_status_label.text = "Fault relay: tripped"
		_control_light.light_color = Color(0.95, 0.22, 0.18)
		_control_light.light_energy = 2.4
		_set_crash_site_active(true)


func _do_salvage() -> void:
	_salvaged = true
	var player := _find_crash_player()
	if player != null:
		player.set("has_regulator", true)
		SaveLoad.has_regulator = true
		SaveLoad.drone_disabled = true
		SaveLoad.save_game()
	if _salvage_label:
		_salvage_label.text = "Signal Phase Regulator taken\nBring to relay"
		var tween := create_tween()
		tween.tween_interval(2.5)
		tween.tween_callback(_salvage_label.hide)


func _on_interact_body_entered(body: Node) -> void:
	if body is CharacterBody3D:
		_player_inside = true
		_sync_state_text()


func _on_interact_body_exited(body: Node) -> void:
	if body is CharacterBody3D:
		_player_inside = false
		_sync_state_text()


func _find_target_drone() -> Node3D:
	for candidate in get_tree().get_nodes_in_group("drones"):
		var drone := candidate as Node3D
		if drone == null:
			continue
		if drone.has_method("is_disabled") and drone.call("is_disabled"):
			continue
		if _is_point_inside_fault_zone(drone.global_position):
			return drone
	return null


func _is_point_inside_fault_zone(point: Vector3) -> bool:
	var box_shape := _fault_shape.shape as BoxShape3D
	if box_shape == null:
		return false
	var local_point := _fault_zone.to_local(point)
	var half_extents := box_shape.size * 0.5
	return (
		abs(local_point.x) <= half_extents.x and
		abs(local_point.y) <= half_extents.y and
		abs(local_point.z) <= half_extents.z
	)


func _sync_state_text() -> void:
	if _spent:
		_status_label.text = "Fault relay spent"
		_control_light.light_color = Color(0.95, 0.22, 0.18)
		_control_light.light_energy = 1.2
		return
	if _player_inside:
		var target_ready := _find_target_drone() != null
		_status_label.text = "Fault relay [G] ready" if target_ready else "Fault relay [G] standby"
		_control_light.light_color = Color(0.98, 0.52, 0.18) if target_ready else Color(0.95, 0.82, 0.38)
		_control_light.light_energy = 2.2 if target_ready else 1.8
		return
	_status_label.text = "Fault relay"
	_control_light.light_color = Color(0.72, 0.82, 0.98)
	_control_light.light_energy = 1.1


func _set_crash_site_active(active: bool) -> void:
	if _crash_label:
		_crash_label.visible = active
	if _crash_light:
		_crash_light.visible = active
		_crash_light.light_energy = 1.6 if active else 0.0
	if _maintenance_note:
		_maintenance_note.visible = not active
	if _salvage_area:
		_salvage_area.monitoring = active
	if _salvage_label:
		_salvage_label.visible = false


func _setup_salvage_area() -> void:
	_salvage_area = Area3D.new()
	_salvage_area.monitoring = false
	_salvage_area.body_entered.connect(_on_salvage_body_entered)
	_salvage_area.body_exited.connect(_on_salvage_body_exited)
	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.4
	col.shape = sphere
	_salvage_area.add_child(col)
	_crash_marker.add_child(_salvage_area)

	_salvage_label = Label3D.new()
	_salvage_label.text = "Salvage [G]\nSignal Phase Regulator"
	_salvage_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_salvage_label.modulate = Color(0.95, 0.78, 0.28)
	_salvage_label.font_size = 32
	_salvage_label.position = Vector3(0.0, 1.4, 0.0)
	_salvage_label.visible = false
	_crash_marker.add_child(_salvage_label)


func _on_salvage_body_entered(body: Node) -> void:
	if body is CharacterBody3D:
		_player_at_crash = true
		if _salvage_label and not _salvaged:
			_salvage_label.visible = true


func _on_salvage_body_exited(body: Node) -> void:
	if body is CharacterBody3D:
		_player_at_crash = false
		if _salvage_label and not _salvaged:
			_salvage_label.visible = false


func _find_crash_player() -> Node3D:
	if _salvage_area == null:
		return null
	for body in _salvage_area.get_overlapping_bodies():
		if body is CharacterBody3D:
			return body
	return null
