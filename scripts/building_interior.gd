@tool
extends Node3D

const _CONCRETE := preload("res://materials/concrete_dark.tres")
const _METAL    := preload("res://materials/metal_guard.tres")
const _WINDOW   := preload("res://materials/window_warm.tres")


func _ready() -> void:
	if get_child_count() > 0:
		return
	_spawn_exterior()
	_spawn_lobby()
	_spawn_stairwell()
	_spawn_second_floor()
	_spawn_windows()
	_spawn_lights()
	_spawn_alley()


# ── Exterior shell ──────────────────────────────────────────────────────────

func _spawn_exterior() -> void:
	# Building footprint: X -10.8 → -22.3 (11.5m wide), Z -23.5 → -42.5 (19m deep), H 12m
	# Front face — left of door (gap: Z -31.8 → -34.2 = 2.4m wide at Z=-33)
	_solid(Vector3(-11.1, 6.0, -27.65), Vector3(0.6, 12.0, 8.3), _CONCRETE)
	# Front face — right of door
	_solid(Vector3(-11.1, 6.0, -38.35), Vector3(0.6, 12.0, 8.3), _CONCRETE)
	# Front face — lintel above door opening (door center Z=-33, width 2.4, clears 2.4m height)
	_solid(Vector3(-11.1, 8.2, -33.0), Vector3(0.6, 7.6, 2.4), _CONCRETE)
	# Back wall
	_solid(Vector3(-22.05, 6.0, -33.0), Vector3(0.5, 12.0, 19.0), _CONCRETE)
	# Left end wall (Z=-23.5)
	_solid(Vector3(-16.55, 6.0, -23.75), Vector3(11.5, 12.0, 0.5), _CONCRETE)
	# Right end wall (Z=-42.5)
	_solid(Vector3(-16.55, 6.0, -42.25), Vector3(11.5, 12.0, 0.5), _CONCRETE)
	# Roof
	_solid(Vector3(-16.55, 12.25, -33.0), Vector3(11.5, 0.5, 19.0), _CONCRETE)
	# Small entrance step — deco only, no collision (step height blocks move_and_slide)
	_deco(Vector3(-10.4, 0.08, -33.0), Vector3(0.4, 0.16, 2.4), _CONCRETE)
	# Number plate above door
	_deco(Vector3(-10.7, 2.6, -33.0), Vector3(0.06, 0.28, 0.5), _METAL)


# ── Ground floor lobby ──────────────────────────────────────────────────────

func _spawn_lobby() -> void:
	# Floor overlay (visual only — ground provides collision)
	_deco(Vector3(-16.55, 0.01, -33.0), Vector3(10.9, 0.02, 18.5), _CONCRETE)

	# Lobby ceiling — two pieces with stairwell gap (gap: X -14→-21.5, Z -36→-41)
	# Piece A: X -10.8 → -14.0
	_solid(Vector3(-12.4, 4.1, -33.0), Vector3(3.2, 0.2, 18.5), _CONCRETE)
	# Piece B: X -14 → -21.5, Z -23.5 → -36
	_solid(Vector3(-17.75, 4.1, -29.75), Vector3(7.5, 0.2, 12.5), _CONCRETE)
	# Piece C: X -14 → -21.5, Z -41 → -42.5 (landing pad at top of ramp)
	_solid(Vector3(-17.75, 4.1, -41.75), Vector3(7.5, 0.2, 1.5), _CONCRETE)


# ── Stairwell ───────────────────────────────────────────────────────────────

func _spawn_stairwell() -> void:
	# Ramp: Z -36→-41 (run 5m), Y 0→4 (rise 4m)
	var ramp := StaticBody3D.new()
	ramp.position = Vector3(-17.75, 2.0, -38.5)
	ramp.rotation.x = atan2(4.0, 5.0)
	add_child(ramp)
	var ramp_col := CollisionShape3D.new()
	var ramp_shape := BoxShape3D.new()
	ramp_shape.size = Vector3(7.5, 0.35, 6.4)
	ramp_col.shape = ramp_shape
	ramp.add_child(ramp_col)
	var ramp_mesh := MeshInstance3D.new()
	var ramp_box := BoxMesh.new()
	ramp_box.size = ramp_shape.size
	ramp_mesh.mesh = ramp_box
	ramp_mesh.material_override = _CONCRETE
	ramp.add_child(ramp_mesh)

	# Visual step strips — horizontal boxes placed above ramp surface in world space
	for i in range(8):
		var frac := (float(i) + 0.5) / 8.0
		var sz := -36.0 - frac * 5.0
		var sy := frac * 4.0
		_deco(Vector3(-17.75, sy + 0.2, sz), Vector3(7.2, 0.1, 0.54), _CONCRETE)

	# Handrail (right side of stairwell, X = -14.5)
	var rail := StaticBody3D.new()
	rail.position = Vector3(-14.5, 2.9, -38.5)
	rail.rotation.x = atan2(4.0, 5.0)
	add_child(rail)
	var rail_col := CollisionShape3D.new()
	var rail_shape := BoxShape3D.new()
	rail_shape.size = Vector3(0.12, 0.12, 6.4)
	rail_col.shape = rail_shape
	rail.add_child(rail_col)
	var rail_mesh := MeshInstance3D.new()
	var rail_box := BoxMesh.new()
	rail_box.size = rail_shape.size
	rail_mesh.mesh = rail_box
	rail_mesh.material_override = _METAL
	rail.add_child(rail_mesh)


# ── Second floor ────────────────────────────────────────────────────────────

func _spawn_second_floor() -> void:
	# 2nd floor ceiling
	_solid(Vector3(-16.55, 7.9, -33.0), Vector3(11.5, 0.2, 19.0), _CONCRETE)

	# Interior dividing wall at Z=-27 — creates Milo's door frame
	_solid(Vector3(-12.1, 6.0, -27.0), Vector3(2.6, 3.8, 0.25), _CONCRETE)
	_solid(Vector3(-19.4, 6.0, -27.0), Vector3(5.8, 3.8, 0.25), _CONCRETE)
	# Lintel above door
	_solid(Vector3(-14.95, 7.15, -27.0), Vector3(3.1, 1.5, 0.25), _CONCRETE)

	# Milo's door slab
	var door_mat := StandardMaterial3D.new()
	door_mat.albedo_color = Color(0.12, 0.10, 0.09)
	door_mat.roughness = 0.85
	_deco(Vector3(-14.95, 5.1, -27.12), Vector3(1.8, 2.2, 0.1), door_mat)

	# Emissive underslip — warm light seeping under the door
	var slip_mat := StandardMaterial3D.new()
	slip_mat.albedo_color = Color(0.08, 0.04, 0.01)
	slip_mat.emission_enabled = true
	slip_mat.emission = Color(0.95, 0.62, 0.18)
	slip_mat.emission_energy_multiplier = 2.2
	_deco(Vector3(-14.95, 4.06, -27.12), Vector3(1.6, 0.08, 0.08), slip_mat)

	# Name plate beside door
	_deco(Vector3(-13.2, 5.45, -27.05), Vector3(0.06, 0.32, 0.55), _METAL)

	# Floor tile overlay for 2nd floor (visual)
	_deco(Vector3(-16.55, 4.01, -33.0), Vector3(10.9, 0.02, 18.5), _CONCRETE)


# ── Exterior windows ────────────────────────────────────────────────────────

func _spawn_windows() -> void:
	_deco(Vector3(-10.65, 1.5, -26.5), Vector3(0.1, 1.4, 0.9), _WINDOW)
	_deco(Vector3(-10.65, 1.5, -30.5), Vector3(0.1, 1.4, 0.9), _WINDOW)
	_deco(Vector3(-10.65, 5.8, -26.5), Vector3(0.1, 1.6, 1.0), _WINDOW)
	_deco(Vector3(-10.65, 5.8, -30.5), Vector3(0.1, 1.6, 1.0), _WINDOW)
	_deco(Vector3(-10.65, 9.2, -36.0), Vector3(0.1, 1.4, 1.2), _WINDOW)
	_deco(Vector3(-10.65, 9.2, -27.0), Vector3(0.1, 1.4, 1.0), _WINDOW)


# ── Interior lights ─────────────────────────────────────────────────────────

func _spawn_lights() -> void:
	_light(Vector3(-15.0, 3.0, -29.0), Color(0.90, 0.72, 0.45), 1.4, 7.0)
	_light(Vector3(-17.75, 1.8, -38.5), Color(0.85, 0.65, 0.38), 0.9, 5.0)
	_light(Vector3(-17.75, 4.8, -40.5), Color(0.70, 0.70, 0.78), 0.8, 4.5)
	_light(Vector3(-15.5, 7.2, -33.0), Color(0.55, 0.58, 0.72), 0.6, 6.0)
	_light(Vector3(-11.5, 2.8, -33.0), Color(0.88, 0.70, 0.42), 1.0, 5.0)


# ── Side alley ──────────────────────────────────────────────────────────────

func _spawn_alley() -> void:
	_solid(Vector3(-16.15, 3.0, -47.75), Vector3(10.7, 6.0, 0.5), _CONCRETE)
	_solid(Vector3(-10.8, 3.0, -45.0), Vector3(0.4, 6.0, 5.0), _CONCRETE)
	_deco(Vector3(-16.15, 0.01, -45.0), Vector3(10.7, 0.02, 5.0), _CONCRETE)
	_solid(Vector3(-19.5, 0.5, -45.5), Vector3(1.2, 1.0, 2.2), _METAL)

	var puddle_mat := StandardMaterial3D.new()
	puddle_mat.albedo_color = Color(0.06, 0.07, 0.08)
	puddle_mat.metallic = 0.9
	puddle_mat.roughness = 0.04
	_deco(Vector3(-14.0, 0.005, -44.5), Vector3(1.8, 0.01, 1.2), puddle_mat)

	_light(Vector3(-16.15, 4.5, -45.0), Color(0.48, 0.50, 0.58), 0.5, 6.0)


# ── Helpers ──────────────────────────────────────────────────────────────────

func _solid(pos: Vector3, size: Vector3, mat: Material) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	add_child(body)
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


func _deco(pos: Vector3, size: Vector3, mat: Material) -> void:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.position = pos
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_inst.mesh = mesh
	mesh_inst.material_override = mat
	add_child(mesh_inst)


func _light(pos: Vector3, color: Color, energy: float, range_m: float) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_m
	light.shadow_enabled = true
	add_child(light)
