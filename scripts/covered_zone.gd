@tool
class_name CoveredZone
extends Area3D

@export var zone_label: String = "Covered"

func _ready() -> void:
	add_to_group("covered_zones")

func contains_point(point: Vector3) -> bool:
	for child in get_children():
		var shape_owner := child as CollisionShape3D
		if shape_owner == null:
			continue
		var box := shape_owner.shape as BoxShape3D
		if box == null:
			continue
		var local_pt := to_local(point)
		var half := box.size * 0.5
		if abs(local_pt.x) <= half.x and abs(local_pt.y) <= half.y and abs(local_pt.z) <= half.z:
			return true
	return false
