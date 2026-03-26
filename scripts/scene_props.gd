extends Node

const _TOWER_SCENE := preload("res://scenes/tower_block.tscn")
const _CONCRETE_MAT := preload("res://materials/concrete_dark.tres")
const _METAL_MAT := preload("res://materials/metal_guard.tres")
const _PUDDLE_MAT := preload("res://materials/puddle.tres")


func setup(root: Node3D) -> void:
	_spawn_props(root)
	_spawn_puddles(root)
	_spawn_skyline(root)
	_spawn_alcoves(root)
	queue_free()


# ── Props: utility boxes, dumpsters, sign plates ───────────────────────────

func _spawn_props(root: Node3D) -> void:
	var utility_boxes := [
		[Vector3(-8.5, 0.3, -22.0), Vector3(0.5, 0.6, 0.4)],
		[Vector3(8.2, 0.3, -38.0), Vector3(0.4, 0.6, 0.5)],
		[Vector3(-8.6, 0.3, -58.0), Vector3(0.5, 0.6, 0.4)],
		[Vector3(8.3, 0.3, -74.0), Vector3(0.4, 0.6, 0.5)],
	]
	for entry in utility_boxes:
		_make_box(root, entry[0], entry[1], _CONCRETE_MAT)

	var dumpsters := [
		[Vector3(-7.5, 0.5, -90.0), Vector3(1.2, 1.0, 2.2)],
		[Vector3(7.2, 0.5, -105.0), Vector3(1.4, 1.0, 2.0)],
	]
	for entry in dumpsters:
		_make_box(root, entry[0], entry[1], _METAL_MAT)

	# Wall-mounted sign plates (thin, slightly emissive look via metal material)
	var signs := [
		[Vector3(-8.8, 1.8, -30.0), Vector3(0.06, 0.5, 0.9)],
		[Vector3(8.8, 1.8, -50.0), Vector3(0.06, 0.5, 0.9)],
		[Vector3(-8.8, 1.8, -70.0), Vector3(0.06, 0.4, 0.7)],
	]
	for entry in signs:
		_make_box(root, entry[0], entry[1], _METAL_MAT)


# ── Puddles: high-reflectivity ground planes ────────────────────────────────

func _spawn_puddles(root: Node3D) -> void:
	var puddles := [
		[Vector3(-3.2, 0.005, -18.0), Vector2(1.8, 1.2)],
		[Vector3(2.8, 0.005, -34.0), Vector2(2.4, 1.6)],
		[Vector3(-1.5, 0.005, -52.0), Vector2(1.4, 1.0)],
		[Vector3(4.0, 0.005, -68.0), Vector2(2.0, 1.4)],
		[Vector3(-4.5, 0.005, -84.0), Vector2(1.6, 1.2)],
		[Vector3(1.2, 0.005, -100.0), Vector2(2.2, 1.8)],
	]
	for entry in puddles:
		_make_puddle(root, entry[0], entry[1])


# ── Skyline: extra distant towers ───────────────────────────────────────────

func _spawn_skyline(root: Node3D) -> void:
	var towers := [
		[Vector3(-28.0, 0.0, -165.0), Vector3(0.85, 1.3, 0.85)],
		[Vector3(22.0, 0.0, -175.0), Vector3(1.1, 0.75, 1.0)],
		[Vector3(-15.0, 0.0, -190.0), Vector3(0.7, 1.4, 0.8)],
		[Vector3(35.0, 0.0, -205.0), Vector3(0.95, 1.1, 1.2)],
	]
	for entry in towers:
		var tower := _TOWER_SCENE.instantiate()
		tower.position = entry[0]
		tower.scale = entry[1]
		root.add_child(tower)


# ── Alcoves: shallow side recesses off the main corridor ────────────────────

func _spawn_alcoves(root: Node3D) -> void:
	# Left alcove near Z = -55: three walls forming a pocket
	_make_box(root, Vector3(-10.5, 1.25, -55.0), Vector3(0.25, 2.5, 0.1), _CONCRETE_MAT)  # entrance lip
	_make_box(root, Vector3(-13.0, 1.25, -62.0), Vector3(0.25, 2.5, 14.0), _CONCRETE_MAT) # side wall
	_make_box(root, Vector3(-10.5, 1.25, -69.0), Vector3(0.25, 2.5, 0.1), _CONCRETE_MAT)  # far lip
	_make_box(root, Vector3(-11.75, 1.25, -62.0), Vector3(2.5, 2.5, 0.25), _CONCRETE_MAT) # back wall

	# Right alcove near Z = -80: mirror layout
	_make_box(root, Vector3(10.5, 1.25, -78.0), Vector3(0.25, 2.5, 0.1), _CONCRETE_MAT)
	_make_box(root, Vector3(13.0, 1.25, -85.0), Vector3(0.25, 2.5, 14.0), _CONCRETE_MAT)
	_make_box(root, Vector3(10.5, 1.25, -92.0), Vector3(0.25, 2.5, 0.1), _CONCRETE_MAT)
	_make_box(root, Vector3(11.75, 1.25, -85.0), Vector3(2.5, 2.5, 0.25), _CONCRETE_MAT)


# ── Helpers ──────────────────────────────────────────────────────────────────

func _make_box(root: Node3D, pos: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	root.add_child(body)

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh
	mesh_inst.material_override = material
	body.add_child(mesh_inst)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)


func _make_puddle(root: Node3D, pos: Vector3, size: Vector2) -> void:
	var mesh_inst := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = size
	mesh_inst.mesh = plane
	mesh_inst.material_override = _PUDDLE_MAT
	mesh_inst.position = pos
	root.add_child(mesh_inst)
