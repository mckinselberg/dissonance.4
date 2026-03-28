extends Node

const _WET_GROUND   := preload("res://materials/wet_ground.tres")
const _CONCRETE_MAT := preload("res://materials/concrete_dark.tres")
const _METAL_MAT    := preload("res://materials/metal_guard.tres")
const _PUDDLE_MAT   := preload("res://materials/puddle.tres")
const _STREETLIGHT  := preload("res://scenes/streetlight.tscn")
const _TOWER_SCENE  := preload("res://scenes/tower_block.tscn")


func setup(root: Node3D) -> void:
	_spawn_ground(root)
	_spawn_streetlights(root)
	_spawn_fog_volumes(root)
	_spawn_props(root)
	_spawn_skyline(root)
	queue_free()


# ── Ground, sidewalks, rear wall ─────────────────────────────────────────────

func _spawn_ground(root: Node3D) -> void:
	# Roadway extension: Z -128 → -192
	_solid(root, Vector3(0.0, -0.1, -160.0), Vector3(80.0, 0.2, 64.0), _WET_GROUND)
	# Left sidewalk
	_solid(root, Vector3(-11.0, 0.12, -160.0), Vector3(4.0, 0.24, 64.0), _CONCRETE_MAT)
	# Right sidewalk
	_solid(root, Vector3(11.0, 0.12, -160.0), Vector3(4.0, 0.24, 64.0), _CONCRETE_MAT)
	# Rear boundary wall — defines the visual end of the world
	_solid(root, Vector3(0.0, 4.0, -193.0), Vector3(84.0, 8.0, 1.0), _CONCRETE_MAT)


# ── Streetlights: alternating sides, continuing existing pattern ─────────────

func _spawn_streetlights(root: Node3D) -> void:
	var placements := [
		Vector3(-9.5, 0.0, -98.0),
		Vector3( 9.5, 0.0, -122.0),
		Vector3(-9.5, 0.0, -148.0),
	]
	for pos in placements:
		var lamp := _STREETLIGHT.instantiate()
		lamp.position = pos
		root.add_child(lamp)


# ── Fog volumes: ground pool + elevated haze ─────────────────────────────────

func _spawn_fog_volumes(root: Node3D) -> void:
	_make_fog_volume(root, Vector3(-4.0, 1.4, -152.0), Vector3(40.0, 2.8, 44.0), 0.22)
	_make_fog_volume(root, Vector3( 6.0, 6.0, -172.0), Vector3(50.0, 12.0, 38.0), 0.08)


# ── Scattered props ───────────────────────────────────────────────────────────

func _spawn_props(root: Node3D) -> void:
	# Utility boxes
	_solid(root, Vector3(-8.5, 0.3, -136.0), Vector3(0.5, 0.6, 0.4), _CONCRETE_MAT)
	_solid(root, Vector3( 8.2, 0.3, -155.0), Vector3(0.4, 0.6, 0.5), _CONCRETE_MAT)

	# Dumpster
	_solid(root, Vector3(-7.5, 0.5, -178.0), Vector3(1.2, 1.0, 2.2), _METAL_MAT)

	# Concrete barrier blocking path centre — forces player to route around
	_solid(root, Vector3(5.0, 0.25, -145.0), Vector3(2.5, 0.5, 0.5), _CONCRETE_MAT)

	# Puddles
	_puddle(root, Vector3(-2.5, 0.005, -133.0), Vector2(2.0, 1.4))
	_puddle(root, Vector3( 3.5, 0.005, -168.0), Vector2(1.8, 1.2))


# ── Additional skyline towers ─────────────────────────────────────────────────

func _spawn_skyline(root: Node3D) -> void:
	var towers := [
		[Vector3(-42.0, 0.0, -222.0), Vector3(0.90, 1.20, 0.90)],
		[Vector3( 28.0, 0.0, -245.0), Vector3(1.05, 0.95, 1.10)],
	]
	for entry: Array in towers:
		var tower := _TOWER_SCENE.instantiate()
		tower.position = entry[0]
		tower.scale = entry[1]
		root.add_child(tower)


# ── Helpers ───────────────────────────────────────────────────────────────────

func _solid(root: Node3D, pos: Vector3, size: Vector3, mat: Material) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	root.add_child(body)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_inst.mesh = mesh
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)


func _puddle(root: Node3D, pos: Vector3, size: Vector2) -> void:
	var mesh_inst := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = size
	mesh_inst.mesh = plane
	mesh_inst.material_override = _PUDDLE_MAT
	mesh_inst.position = pos
	root.add_child(mesh_inst)


func _make_fog_volume(root: Node3D, pos: Vector3, size: Vector3, density: float) -> void:
	var vol := FogVolume.new()
	vol.position = pos
	vol.size = size
	var fog_mat := FogMaterial.new()
	fog_mat.density = density
	vol.material = fog_mat
	root.add_child(vol)
