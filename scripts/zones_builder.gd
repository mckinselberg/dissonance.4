@tool
extends Node3D

@export var show_editor_legend: bool = true


func _ready() -> void:
	if get_node_or_null("Open_Boulevard_Zone") == null:
		_build()
	if Engine.is_editor_hint():
		call_deferred("_sync_editor_legend")


func _notification(what: int) -> void:
	if not Engine.is_editor_hint():
		return
	if what == NOTIFICATION_READY or what == NOTIFICATION_ENTER_TREE:
		call_deferred("_sync_editor_legend")


func _build() -> void:
	_make_zone(
		"Open_Boulevard_Zone",
		"Open Boulevard",
		3,
		Vector3(0.0, 2.5, -95.0),
		Vector3(16.0, 5.0, 170.0),
		{sensory_exposure = 0.10, social_exposure = 0.65}
	)
	_make_zone(
		"Drone_Path_Zone",
		"Drone Path",
		4,
		Vector3(0.0, 7.0, -100.0),
		Vector3(12.0, 6.0, 130.0),
		{sensory_exposure = 0.80, social_exposure = 0.15}
	)
	_make_zone(
		"Alcove_Left_Zone",
		"Alcove",
		5,
		Vector3(-11.75, 1.25, -62.0),
		Vector3(2.5, 2.5, 14.0),
		{rest_input = 1.25, calming_input = 0.72, solitude_regulation = 0.55}
	)
	_make_zone(
		"Alcove_Right_Zone",
		"Alcove",
		5,
		Vector3(11.75, 1.25, -85.0),
		Vector3(2.5, 2.5, 14.0),
		{rest_input = 1.25, calming_input = 0.72, solitude_regulation = 0.55}
	)
	_make_zone(
		"Tuning_Nook_Zone",
		"Tuning Nook",
		6,
		Vector3(-9.0, 1.5, -45.0),
		Vector3(3.0, 3.0, 5.0),
		{musical_regulation = 0.95, rest_input = 0.5, calming_input = 0.9, solitude_regulation = 0.3}
	)
	_make_zone(
		"Milos_Building_Zone",
		"Milo's Building",
		7,
		Vector3(-16.0, 4.0, -33.0),
		Vector3(12.0, 8.0, 18.0),
		{rest_input = 0.8, calming_input = 0.6, solitude_regulation = 0.7}
	)
	_make_zone(
		"Alley_Zone",
		"Alley",
		6,
		Vector3(-16.0, 1.5, -45.0),
		Vector3(12.0, 3.0, 10.0),
		{solitude_regulation = 0.65, rest_input = 0.4}
	)


func _make_zone(node_name: String, label: String, priority: int, pos: Vector3, size: Vector3, props: Dictionary) -> void:
	var zone := ZoneArea3D.new()
	zone.name = node_name
	zone.position = pos
	zone.zone_label = label
	zone.zone_priority = priority
	for key in props:
		zone.set(key, props[key])

	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	zone.add_child(col)

	add_child(zone)


func _sync_editor_legend() -> void:
	var root := get_node_or_null("EditorZoneLegend") as Node3D
	if not show_editor_legend:
		if root:
			root.queue_free()
		return

	if root == null:
		root = Node3D.new()
		root.name = "EditorZoneLegend"
		add_child(root)

	var lines := [
		["Zones", Color(0.95, 0.95, 0.98)],
		["Blue: musical", Color(0.47, 0.78, 0.95)],
		["Green: rest/calming", Color(0.52, 0.88, 0.58)],
		["Olive: solitude", Color(0.62, 0.78, 0.58)],
		["Red: sensory pressure", Color(0.95, 0.36, 0.34)],
		["Amber: social pressure", Color(0.96, 0.64, 0.28)],
	]

	for child in root.get_children():
		child.queue_free()

	for i in range(lines.size()):
		var label := Label3D.new()
		label.name = "LegendLine_%02d" % i
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 30 if i == 0 else 24
		label.outline_size = 5
		label.pixel_size = 0.005
		label.text = lines[i][0]
		label.modulate = lines[i][1]
		label.position = Vector3(-20.0, 4.5 - i * 0.45, 10.0)
		root.add_child(label)
