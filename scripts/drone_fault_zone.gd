extends Node3D

@export var interact_action: StringName = &"player_interact"
@export var single_use: bool = true

var _player_inside: bool = false
var _spent: bool = false

@onready var _interact_area: Area3D = $InteractArea
@onready var _fault_zone: Area3D = $FaultZone
@onready var _fault_shape: CollisionShape3D = $FaultZone/CollisionShape3D
@onready var _crash_marker: Marker3D = $CrashMarker
@onready var _status_label: Label3D = $StatusLabel
@onready var _control_light: OmniLight3D = $ControlLight


func _ready() -> void:
	_interact_area.body_entered.connect(_on_interact_body_entered)
	_interact_area.body_exited.connect(_on_interact_body_exited)
	_sync_state_text()


func _unhandled_input(event: InputEvent) -> void:
	if not _player_inside or _spent:
		return
	if not event.is_action_pressed(interact_action):
		return

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
		get_viewport().set_input_as_handled()


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
		_status_label.text = "Fault relay [G]"
		_control_light.light_color = Color(0.95, 0.82, 0.38)
		_control_light.light_energy = 1.8
		return
	_status_label.text = "Fault relay"
	_control_light.light_color = Color(0.72, 0.82, 0.98)
	_control_light.light_energy = 1.1
