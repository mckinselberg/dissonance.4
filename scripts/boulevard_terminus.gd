@tool
extends Node3D

const _WET_GROUND   := preload("res://materials/wet_ground.tres")
const _CONCRETE_MAT := preload("res://materials/concrete_dark.tres")
const _METAL_MAT    := preload("res://materials/metal_guard.tres")
const _PUDDLE_MAT   := preload("res://materials/puddle.tres")
const _STREETLIGHT  := preload("res://scenes/streetlight.tscn")


func _ready() -> void:
	if get_child_count() > 0:
		return
	_spawn_ground()
	_spawn_streetlights()
	_spawn_fog_volumes()
	_spawn_props()
	_spawn_terminus_building()


# ── Ground Z -192 → -342 ──────────────────────────────────────────────────────

func _spawn_ground() -> void:
	_solid(Vector3(0.0, -0.1, -267.0), Vector3(80.0, 0.2, 150.0), _WET_GROUND)
	_solid(Vector3(-11.0, 0.12, -267.0), Vector3(4.0, 0.24, 150.0), _CONCRETE_MAT)
	_solid(Vector3( 11.0, 0.12, -267.0), Vector3(4.0, 0.24, 150.0), _CONCRETE_MAT)
	_solid(Vector3(0.0, 8.0, -345.0), Vector3(100.0, 16.0, 1.0), _CONCRETE_MAT)


# ── Streetlights ──────────────────────────────────────────────────────────────

func _spawn_streetlights() -> void:
	var placements := [
		Vector3( 9.5, 0.0, -173.0),
		Vector3(-9.5, 0.0, -198.0),
		Vector3( 9.5, 0.0, -223.0),
		Vector3(-9.5, 0.0, -248.0),
		Vector3( 9.5, 0.0, -273.0),
		Vector3(-9.5, 0.0, -298.0),
		Vector3( 9.5, 0.0, -318.0),
	]
	for pos in placements:
		var lamp := _STREETLIGHT.instantiate()
		lamp.position = pos
		add_child(lamp)


# ── Fog volumes ───────────────────────────────────────────────────────────────

func _spawn_fog_volumes() -> void:
	_fog(Vector3( 4.0, 1.4, -230.0), Vector3(45.0,  2.8, 50.0), 0.20)
	_fog(Vector3(-5.0, 5.5, -278.0), Vector3(55.0, 10.0, 50.0), 0.07)
	_fog(Vector3( 0.0, 2.0, -318.0), Vector3(60.0,  4.0, 40.0), 0.30)


# ── Props ─────────────────────────────────────────────────────────────────────

func _spawn_props() -> void:
	_solid(Vector3(-8.2, 0.3, -210.0), Vector3(0.5, 0.6, 0.4), _CONCRETE_MAT)
	_solid(Vector3( 7.8, 0.5, -238.0), Vector3(1.2, 1.0, 2.2), _METAL_MAT)
	_solid(Vector3(-6.5, 0.25, -262.0), Vector3(2.5, 0.5, 0.5), _CONCRETE_MAT)
	_solid(Vector3( 8.0, 0.3, -295.0), Vector3(0.4, 0.6, 0.5), _CONCRETE_MAT)
	_puddle(Vector3(-3.0, 0.005, -218.0), Vector2(2.2, 1.5))
	_puddle(Vector3( 4.5, 0.005, -255.0), Vector2(1.6, 1.0))
	_puddle(Vector3(-1.5, 0.005, -307.0), Vector2(3.0, 2.0))


# ── Terminus building ─────────────────────────────────────────────────────────

func _spawn_terminus_building() -> void:
	# Central tower: 20m wide × 30m tall × 8m deep
	_solid(Vector3(0.0, 15.0, -329.0), Vector3(20.0, 30.0, 8.0), _CONCRETE_MAT)
	_window_grid(-324.8, -8.0, 5, 4.0, 1.5, 9, 3.0, 1.6, 2.2)

	# Left wing: 12m wide × 20m tall × 6m deep
	_solid(Vector3(-16.0, 10.0, -328.0), Vector3(12.0, 20.0, 6.0), _CONCRETE_MAT)
	_window_grid(-324.8, -21.0, 3, 4.0, 1.5, 5, 3.5, 1.4, 2.0)

	# Right tower: 8m wide × 24m tall × 6m deep
	_solid(Vector3(14.0, 12.0, -328.0), Vector3(8.0, 24.0, 6.0), _CONCRETE_MAT)
	_window_grid(-324.8, 11.5, 2, 5.0, 1.5, 7, 3.2, 1.3, 2.0)

	# Connecting low plinth
	_solid(Vector3(-5.0, 2.5, -327.0), Vector3(10.0, 5.0, 4.0), _CONCRETE_MAT)

	_light(Vector3(-7.0,  0.4, -322.0), Color(0.95, 0.55, 0.18), 2.2, 10.0)
	_light(Vector3( 7.0,  0.4, -322.0), Color(0.95, 0.55, 0.18), 2.2, 10.0)
	_light(Vector3(-18.0, 0.4, -322.0), Color(0.88, 0.48, 0.14), 1.6,  8.0)
	_light(Vector3( 16.0, 0.4, -322.0), Color(0.88, 0.48, 0.14), 1.6,  8.0)
	_light(Vector3(  0.0, 8.0, -322.0), Color(0.62, 0.68, 0.82), 1.0, 12.0)
	_light(Vector3(  0.0, 30.5, -329.0), Color(0.95, 0.12, 0.08), 1.8, 6.0)
	_light(Vector3(-16.0, 20.5, -328.0), Color(0.90, 0.10, 0.06), 1.4, 5.0)


func _window_grid(face_z: float,
		x_start: float, cols: int, col_spacing: float,
		y_start: float, rows: int, row_spacing: float,
		win_w: float, win_h: float) -> void:
	for r in range(rows):
		for c in range(cols):
			var idx := r * cols + c
			var pattern := idx % 7
			if pattern == 5:
				continue
			var energy: float
			var color: Color
			if pattern <= 3:
				energy = 2.0 + (idx % 3) * 0.5
				color = Color(0.98, 0.60, 0.22)
			else:
				energy = 0.7
				color = Color(0.72, 0.38, 0.14)
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.08, 0.06, 0.04)
			mat.emission_enabled = true
			mat.emission = color
			mat.emission_energy_multiplier = energy
			var inst := MeshInstance3D.new()
			inst.position = Vector3(x_start + c * col_spacing, y_start + r * row_spacing, face_z)
			var mesh := BoxMesh.new()
			mesh.size = Vector3(win_w, win_h, 0.08)
			inst.mesh = mesh
			inst.material_override = mat
			add_child(inst)


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


func _light(pos: Vector3, color: Color, energy: float, range_m: float) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_m
	light.shadow_enabled = true
	add_child(light)
