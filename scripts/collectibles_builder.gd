@tool
extends Node3D

const _SYMBOLS := ["\u2669", "\u266A", "\u266B", "\u266C", "\u266D", "\u266E", "\u266F", "\u266B", "\u266A", "\u2669"]

@export var show_editor_path: bool = true
@export var show_editor_legend: bool = true

const _POSITIONS := [
	Vector3(2.0, 1.5, -8.0),
	Vector3(-7.5, 1.8, -22.5),
	Vector3(6.2, 1.6, -35.0),
	Vector3(-8.5, 1.8, -46.0),
	Vector3(-12.2, 1.5, -62.0),
	Vector3(5.0, 1.8, -55.0),
	Vector3(12.2, 1.5, -85.0),
	Vector3(-6.0, 1.6, -75.0),
	Vector3(7.5, 1.8, -95.0),
	Vector3(0.0, 2.0, -112.0),
]


func _ready() -> void:
	if get_node_or_null("CollectionManager") == null:
		_build()
	if Engine.is_editor_hint():
		call_deferred("_sync_editor_helpers")


func _notification(what: int) -> void:
	if not Engine.is_editor_hint():
		return
	if what == NOTIFICATION_READY or what == NOTIFICATION_ENTER_TREE:
		call_deferred("_sync_editor_helpers")


func _build() -> void:
	var manager := CollectionManager.new()
	manager.name = "CollectionManager"
	manager.register_total(_POSITIONS.size())
	add_child(manager)

	for i in range(_POSITIONS.size()):
		var collectible := MusicalCollectible.new()
		collectible.name = "Collectible_%02d" % (i + 1)
		collectible.symbol = _SYMBOLS[i]
		collectible.collection_manager = manager
		collectible.position = _POSITIONS[i]
		add_child(collectible)


func _sync_editor_helpers() -> void:
	_sync_editor_path()
	_sync_editor_legend()


func _sync_editor_path() -> void:
	var existing := get_node_or_null("EditorCollectiblePath") as MeshInstance3D
	if not show_editor_path:
		if existing:
			existing.queue_free()
		return

	if existing == null:
		existing = MeshInstance3D.new()
		existing.name = "EditorCollectiblePath"
		add_child(existing)

	var immediate := ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.92, 0.86, 0.34, 0.92)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true
	immediate.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, material)
	for point in _POSITIONS:
		immediate.surface_add_vertex(point + Vector3(0.0, 0.08, 0.0))
	immediate.surface_end()
	existing.mesh = immediate
	existing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _sync_editor_legend() -> void:
	var existing := get_node_or_null("EditorCollectibleLegend") as Label3D
	if not show_editor_legend:
		if existing:
			existing.queue_free()
		return

	if existing == null:
		existing = Label3D.new()
		existing.name = "EditorCollectibleLegend"
		existing.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		existing.font_size = 32
		existing.outline_size = 6
		existing.pixel_size = 0.005
		add_child(existing)

	existing.text = "Collectible route"
	existing.position = Vector3(0.0, 3.4, -8.0)
	existing.modulate = Color(0.95, 0.92, 0.65)
