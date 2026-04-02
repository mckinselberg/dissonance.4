@tool
extends Node3D

const _TOWER_SCENE := preload("res://scenes/tower_block.tscn")
const _CONCRETE_MAT := preload("res://materials/concrete_dark.tres")
const _METAL_MAT := preload("res://materials/metal_guard.tres")
const _PUDDLE_MAT := preload("res://materials/puddle.tres")


func _ready() -> void:
	if get_child_count() > 0:
		return
	_build()


func _build() -> void:
	_spawn_props()
	_spawn_puddles()
	_spawn_skyline()
	_spawn_alcoves()


func _spawn_props() -> void:
	var utility_boxes := [
		[Vector3(-8.5, 0.3, -22.0), Vector3(0.5, 0.6, 0.4)],
		[Vector3(8.2, 0.3, -38.0), Vector3(0.4, 0.6, 0.5)],
		[Vector3(-8.6, 0.3, -58.0), Vector3(0.5, 0.6, 0.4)],
		[Vector3(8.3, 0.3, -74.0), Vector3(0.4, 0.6, 0.5)],
	]
	for i in range(utility_boxes.size()):
		var entry: Array = utility_boxes[i]
		_make_box("UtilityBox_%02d" % (i + 1), entry[0], entry[1], _CONCRETE_MAT)

	var dumpsters := [
		[Vector3(-7.5, 0.5, -90.0), Vector3(1.2, 1.0, 2.2)],
		[Vector3(7.2, 0.5, -105.0), Vector3(1.4, 1.0, 2.0)],
	]
	for i in range(dumpsters.size()):
		var entry: Array = dumpsters[i]
		_make_box("Dumpster_%02d" % (i + 1), entry[0], entry[1], _METAL_MAT)

	var signs := [
		[Vector3(-8.8, 1.8, -30.0), Vector3(0.06, 0.5, 0.9)],
		[Vector3(8.8, 1.8, -50.0), Vector3(0.06, 0.5, 0.9)],
		[Vector3(-8.8, 1.8, -70.0), Vector3(0.06, 0.4, 0.7)],
	]
	for i in range(signs.size()):
		var entry: Array = signs[i]
		_make_box("Sign_%02d" % (i + 1), entry[0], entry[1], _METAL_MAT)


func _spawn_puddles() -> void:
	var puddles := [
		[Vector3(-3.2, 0.005, -18.0), Vector2(1.8, 1.2)],
		[Vector3(2.8, 0.005, -34.0), Vector2(2.4, 1.6)],
		[Vector3(-1.5, 0.005, -52.0), Vector2(1.4, 1.0)],
		[Vector3(4.0, 0.005, -68.0), Vector2(2.0, 1.4)],
		[Vector3(-4.5, 0.005, -84.0), Vector2(1.6, 1.2)],
		[Vector3(1.2, 0.005, -100.0), Vector2(2.2, 1.8)],
	]
	for i in range(puddles.size()):
		var entry: Array = puddles[i]
		_make_puddle("Puddle_%02d" % (i + 1), entry[0], entry[1])


func _spawn_skyline() -> void:
	var towers := [
		[Vector3(-28.0, 0.0, -165.0), Vector3(0.85, 1.3, 0.85)],
		[Vector3(22.0, 0.0, -175.0), Vector3(1.1, 0.75, 1.0)],
		[Vector3(-15.0, 0.0, -190.0), Vector3(0.7, 1.4, 0.8)],
		[Vector3(35.0, 0.0, -205.0), Vector3(0.95, 1.1, 1.2)],
	]
	for i in range(towers.size()):
		var entry: Array = towers[i]
		var tower := _TOWER_SCENE.instantiate()
		tower.name = "SkylineTower_%02d" % (i + 1)
		tower.position = entry[0]
		tower.scale = entry[1]
		add_child(tower)


func _spawn_alcoves() -> void:
	_make_box("AlcoveLeft_EntranceLip", Vector3(-10.5, 1.25, -55.0), Vector3(0.25, 2.5, 0.1), _CONCRETE_MAT)
	_make_box("AlcoveLeft_SideWall", Vector3(-13.0, 1.25, -62.0), Vector3(0.25, 2.5, 14.0), _CONCRETE_MAT)
	_make_box("AlcoveLeft_FarLip", Vector3(-10.5, 1.25, -69.0), Vector3(0.25, 2.5, 0.1), _CONCRETE_MAT)
	_make_box("AlcoveLeft_BackWall", Vector3(-11.75, 1.25, -62.0), Vector3(2.5, 2.5, 0.25), _CONCRETE_MAT)

	_make_box("AlcoveRight_EntranceLip", Vector3(10.5, 1.25, -78.0), Vector3(0.25, 2.5, 0.1), _CONCRETE_MAT)
	_make_box("AlcoveRight_SideWall", Vector3(13.0, 1.25, -85.0), Vector3(0.25, 2.5, 14.0), _CONCRETE_MAT)
	_make_box("AlcoveRight_FarLip", Vector3(10.5, 1.25, -92.0), Vector3(0.25, 2.5, 0.1), _CONCRETE_MAT)
	_make_box("AlcoveRight_BackWall", Vector3(11.75, 1.25, -85.0), Vector3(2.5, 2.5, 0.25), _CONCRETE_MAT)


func _make_box(node_name: String, pos: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	add_child(body)

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "Mesh"
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh
	mesh_inst.material_override = material
	body.add_child(mesh_inst)

	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)


func _make_puddle(node_name: String, pos: Vector3, size: Vector2) -> void:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = node_name
	var plane := PlaneMesh.new()
	plane.size = size
	mesh_inst.mesh = plane
	mesh_inst.material_override = _PUDDLE_MAT
	mesh_inst.position = pos
	add_child(mesh_inst)
