@tool
class_name ZoneArea3D
extends Area3D

@export var sensory_exposure: float = 0.0
@export var social_exposure: float = 0.0
@export var rest_input: float = 0.0
@export var musical_regulation: float = 0.0
@export var solitude_regulation: float = 0.0
@export var calming_input: float = 0.0
@export var zone_label: String = "Zone"
@export var zone_priority: int = 0

var _preview_mesh: MeshInstance3D
var _preview_label: Label3D


func _ready() -> void:
	if Engine.is_editor_hint():
		_update_editor_preview()
		return

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _notification(what: int) -> void:
	if not Engine.is_editor_hint():
		return

	if what == NOTIFICATION_ENTER_TREE or what == NOTIFICATION_READY:
		call_deferred("_update_editor_preview")


func _validate_property(_property: Dictionary) -> void:
	if Engine.is_editor_hint():
		call_deferred("_update_editor_preview")


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D and body.has_method("register_zone"):
		body.register_zone(self)


func _on_body_exited(body: Node) -> void:
	if body is CharacterBody3D and body.has_method("unregister_zone"):
		body.unregister_zone(self)


func _update_editor_preview() -> void:
	var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null:
		return
	var box_shape := collision.shape as BoxShape3D
	if box_shape == null:
		return

	if _preview_mesh == null or not is_instance_valid(_preview_mesh):
		_preview_mesh = get_node_or_null("EditorPreviewMesh") as MeshInstance3D
	if _preview_mesh == null:
		_preview_mesh = MeshInstance3D.new()
		_preview_mesh.name = "EditorPreviewMesh"
		add_child(_preview_mesh)

	if _preview_label == null or not is_instance_valid(_preview_label):
		_preview_label = get_node_or_null("EditorPreviewLabel") as Label3D
	if _preview_label == null:
		_preview_label = Label3D.new()
		_preview_label.name = "EditorPreviewLabel"
		_preview_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_preview_label.font_size = 36
		_preview_label.outline_size = 6
		_preview_label.pixel_size = 0.006
		add_child(_preview_label)

	var mesh := BoxMesh.new()
	mesh.size = box_shape.size
	_preview_mesh.mesh = mesh
	_preview_mesh.position = collision.position
	_preview_mesh.material_override = _build_preview_material()
	_preview_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_preview_label.text = "%s  p%d" % [zone_label, zone_priority]
	_preview_label.position = collision.position + Vector3(0.0, box_shape.size.y * 0.5 + 0.4, 0.0)
	_preview_label.modulate = _zone_preview_color()


func _build_preview_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var zone_color := _zone_preview_color()
	material.albedo_color = Color(zone_color, 0.12)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.no_depth_test = false
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _zone_preview_color() -> Color:
	if musical_regulation > 0.0:
		return Color(0.47, 0.78, 0.95)
	if rest_input > 0.0 or calming_input > 0.0:
		return Color(0.52, 0.88, 0.58)
	if solitude_regulation > 0.0:
		return Color(0.62, 0.78, 0.58)
	if sensory_exposure > social_exposure:
		return Color(0.95, 0.36, 0.34)
	if social_exposure > 0.0:
		return Color(0.96, 0.64, 0.28)
	return Color(0.72, 0.72, 0.76)
