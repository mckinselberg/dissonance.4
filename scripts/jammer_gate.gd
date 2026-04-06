extends Node3D

@onready var _trigger_area: Area3D = $TriggerArea
@onready var _barrier_mesh: MeshInstance3D = $BarrierMesh
@onready var _gate_light: OmniLight3D = $GateLight
@onready var _gate_label: Label3D = get_node_or_null("GateLabel") as Label3D

var _player_nearby: bool = false
var _is_open: bool = false
var _time: float = 0.0


func _ready() -> void:
	_trigger_area.body_entered.connect(_on_body_entered)
	_trigger_area.body_exited.connect(_on_body_exited)
	_update_visual()


func _process(delta: float) -> void:
	_time += delta

	if _player_nearby:
		var player := _find_player()
		var jammer_on := false
		if player != null and player.get("jammer_active"):
			jammer_on = true
		if jammer_on and not _is_open:
			_is_open = true
			_update_visual()
		elif not jammer_on and _is_open:
			_is_open = false
			_update_visual()

	if not _is_open and _barrier_mesh != null:
		var mat := _barrier_mesh.get_active_material(0) as StandardMaterial3D
		if mat != null:
			mat.albedo_color.a = 0.45 + 0.2 * sin(_time * 2.2)


func _update_visual() -> void:
	if _barrier_mesh:
		_barrier_mesh.visible = not _is_open
	if _gate_light:
		_gate_light.light_color = Color(0.22, 0.92, 0.55) if _is_open else Color(0.92, 0.12, 0.12)
		_gate_light.light_energy = 1.6
	if _gate_label:
		if _is_open:
			_gate_label.text = "Suppression field active"
			_gate_label.modulate = Color(0.3, 1.0, 0.6)
		else:
			_gate_label.text = "Surveillance zone\n[J] activate jammer to cross"
			_gate_label.modulate = Color(0.95, 0.35, 0.22)


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D:
		_player_nearby = true


func _on_body_exited(body: Node) -> void:
	if body is CharacterBody3D:
		_player_nearby = false


func _find_player() -> Node3D:
	for body in _trigger_area.get_overlapping_bodies():
		if body is CharacterBody3D:
			return body
	return null
