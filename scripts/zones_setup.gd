extends Node


func setup(root: Node3D) -> void:
	# Open boulevard: social pressure along the main corridor
	_make_zone(root, "Open Boulevard", 3,
		Vector3(0.0, 2.5, -95.0), Vector3(16.0, 5.0, 170.0),
		{sensory_exposure = 0.10, social_exposure = 0.65}
	)

	# Drone path: sensory pressure under the patrol route
	_make_zone(root, "Drone Path", 4,
		Vector3(0.0, 7.0, -100.0), Vector3(12.0, 6.0, 130.0),
		{sensory_exposure = 0.80, social_exposure = 0.15}
	)

	# Left alcove: rest and recovery
	_make_zone(root, "Alcove", 5,
		Vector3(-11.75, 1.25, -62.0), Vector3(2.5, 2.5, 14.0),
		{rest_input = 1.25, calming_input = 0.72, solitude_regulation = 0.55}
	)

	# Right alcove: rest and recovery
	_make_zone(root, "Alcove", 5,
		Vector3(11.75, 1.25, -85.0), Vector3(2.5, 2.5, 14.0),
		{rest_input = 1.25, calming_input = 0.72, solitude_regulation = 0.55}
	)

	# Tuning nook: musical regulation, highest priority
	_make_zone(root, "Tuning Nook", 6,
		Vector3(-9.0, 1.5, -45.0), Vector3(3.0, 3.0, 5.0),
		{musical_regulation = 0.95, rest_input = 0.5, calming_input = 0.9, solitude_regulation = 0.3}
	)

	# Milo's building interior: calm, solitude, rest
	_make_zone(root, "Milo's Building", 7,
		Vector3(-16.0, 4.0, -33.0), Vector3(12.0, 8.0, 18.0),
		{rest_input = 0.8, calming_input = 0.6, solitude_regulation = 0.7}
	)

	# Side alley beside the building: quieter than the boulevard
	_make_zone(root, "Alley", 6,
		Vector3(-16.0, 1.5, -45.0), Vector3(12.0, 3.0, 10.0),
		{solitude_regulation = 0.65, rest_input = 0.4}
	)

	queue_free()


func _make_zone(root: Node3D, label: String, priority: int, pos: Vector3, size: Vector3, props: Dictionary) -> void:
	var zone := ZoneArea3D.new()
	zone.name = label.replace(" ", "_") + "_Zone"
	zone.position = pos
	zone.zone_label = label
	zone.zone_priority = priority
	for key in props:
		zone.set(key, props[key])

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	zone.add_child(col)

	root.add_child(zone)
