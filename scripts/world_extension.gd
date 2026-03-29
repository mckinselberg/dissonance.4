@tool
extends Node3D

const _WET_GROUND   := preload("res://materials/wet_ground.tres")
const _CONCRETE_MAT := preload("res://materials/concrete_dark.tres")
const _METAL_MAT    := preload("res://materials/metal_guard.tres")
const _PUDDLE_MAT   := preload("res://materials/puddle.tres")
const _STREETLIGHT  := preload("res://scenes/streetlight.tscn")
const _TOWER_SCENE  := preload("res://scenes/tower_block.tscn")


func _ready() -> void:
	if get_child_count() > 0:
		return
	_spawn_ground()
	_spawn_streetlights()
	_spawn_fog_volumes()
	_spawn_props()
	_spawn_skyline()


# ── Ground Z -128 → -192 ──────────────────────────────────────────────────────

func _spawn_ground() -> void:
	_solid(Vector3(0.0, -0.1, -160.0), Vector3(80.0, 0.2, 64.0), _WET_GROUND)
	_solid(Vector3(-11.0, 0.12, -160.0), Vector3(4.0, 0.24, 64.0), _CONCRETE_MAT)
	_solid(Vector3( 11.0, 0.12, -160.0), Vector3(4.0, 0.24, 64.0), _CONCRETE_MAT)
	# No rear wall here — boulevard_terminus places it further back


# ── Streetlights ──────────────────────────────────────────────────────────────

func _spawn_streetlights() -> void:
	var placements := [
		Vector3(-9.5, 0.0, -98.0),
		Vector3( 9.5, 0.0, -122.0),
		Vector3(-9.5, 0.0, -148.0),
	]
	for pos in placements:
		var lamp := _STREETLIGHT.instantiate()
		lamp.position = pos
		add_child(lamp)


# ── Fog volumes ───────────────────────────────────────────────────────────────

func _spawn_fog_volumes() -> void:
	_fog(Vector3(-4.0, 1.4, -152.0), Vector3(40.0,  2.8, 44.0), 0.22)
	_fog(Vector3( 6.0, 6.0, -172.0), Vector3(50.0, 12.0, 38.0), 0.08)


# ── Props ─────────────────────────────────────────────────────────────────────

func _spawn_props() -> void:
	_solid(Vector3(-8.5, 0.3, -136.0), Vector3(0.5, 0.6, 0.4), _CONCRETE_MAT)
	_solid(Vector3( 8.2, 0.3, -155.0), Vector3(0.4, 0.6, 0.5), _CONCRETE_MAT)
	_solid(Vector3(-7.5, 0.5, -178.0), Vector3(1.2, 1.0, 2.2), _METAL_MAT)
	_solid(Vector3( 5.0, 0.25, -145.0), Vector3(2.5, 0.5, 0.5), _CONCRETE_MAT)
	_puddle(Vector3(-2.5, 0.005, -133.0), Vector2(2.0, 1.4))
	_puddle(Vector3( 3.5, 0.005, -168.0), Vector2(1.8, 1.2))


# ── Skyline towers ────────────────────────────────────────────────────────────

func _spawn_skyline() -> void:
	var towers := [
		[Vector3(-42.0, 0.0, -222.0), Vector3(0.90, 1.20, 0.90)],
		[Vector3( 28.0, 0.0, -245.0), Vector3(1.05, 0.95, 1.10)],
	]
	for entry: Array in towers:
		var tower := _TOWER_SCENE.instantiate()
		tower.position = entry[0]
		tower.scale = entry[1]
		add_child(tower)


# ── Helpers ───────────────────────────────────────────────────────────────────

func _solid(pos: Vector3, size: Vector3, mat: Material) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	add_child(body)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	body.add_child(mi)


func _puddle(pos: Vector3, size: Vector2) -> void:
	var mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = size
	mi.mesh = plane
	mi.material_override = _PUDDLE_MAT
	mi.position = pos
	add_child(mi)


func _fog(pos: Vector3, size: Vector3, density: float) -> void:
	var vol := FogVolume.new()
	vol.position = pos
	vol.size = size
	var fog_mat := FogMaterial.new()
	fog_mat.density = density
	vol.material = fog_mat
	add_child(vol)
