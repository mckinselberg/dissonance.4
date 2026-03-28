extends Node


func setup(root: Node3D) -> void:
	# Pull back the existing flat mist sheets so they read as background haze.
	# GPUParticles3D is Node3D — use process_material color alpha, not modulate.
	for node_name in ["MistParticles_A", "MistParticles_B"]:
		var existing := root.get_node_or_null(node_name) as GPUParticles3D
		if existing == null:
			continue
		var pm := existing.process_material as ParticleProcessMaterial
		if pm == null:
			continue
		pm = pm.duplicate() as ParticleProcessMaterial
		pm.color = Color(1.0, 1.0, 1.0, 0.55)
		existing.process_material = pm

	# Ground tendril layer — low wisps crawling at foot level
	for z: float in [-20.0, -60.0, -100.0]:
		_spawn_ground_tendril(root, z)

	# Mid haze layer — barely visible volume above head height
	for z: float in [-35.0, -90.0]:
		_spawn_mid_haze(root, z)

	queue_free()


func _spawn_ground_tendril(root: Node3D, z: float) -> void:
	var particles := GPUParticles3D.new()
	particles.position = Vector3(0.0, 0.3, z)
	particles.amount = 140
	particles.lifetime = 22.0
	particles.preprocess = 15.0

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.68, 0.70, 0.72, 0.18)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED

	var quad := QuadMesh.new()
	quad.size = Vector2(1.1, 0.45)
	quad.material = mat
	particles.draw_pass_1 = quad

	var proc_mat := ParticleProcessMaterial.new()
	proc_mat.direction = Vector3(0.6, 0.0, 0.4)
	proc_mat.spread = 72.0
	proc_mat.initial_velocity_min = 0.02
	proc_mat.initial_velocity_max = 0.07
	proc_mat.scale_min = 0.6
	proc_mat.scale_max = 1.8
	proc_mat.angular_velocity_min = -0.04
	proc_mat.angular_velocity_max = 0.04
	proc_mat.damping_min = 0.06
	proc_mat.damping_max = 0.15

	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(1, 1, 1, 0.0),
		Color(1, 1, 1, 1.0),
		Color(1, 1, 1, 1.0),
		Color(1, 1, 1, 0.0),
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.1, 0.85, 1.0])
	var ramp_tex := GradientTexture1D.new()
	ramp_tex.gradient = gradient
	proc_mat.color_ramp = ramp_tex

	particles.process_material = proc_mat
	root.add_child(particles)


func _spawn_mid_haze(root: Node3D, z: float) -> void:
	var particles := GPUParticles3D.new()
	particles.position = Vector3(0.0, 3.5, z)
	particles.amount = 40
	particles.lifetime = 28.0
	particles.preprocess = 20.0

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.62, 0.63, 0.66, 0.09)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED

	var quad := QuadMesh.new()
	quad.size = Vector2(3.5, 2.0)
	quad.material = mat
	particles.draw_pass_1 = quad

	var proc_mat := ParticleProcessMaterial.new()
	proc_mat.direction = Vector3(-0.5, 0.02, 0.3)
	proc_mat.spread = 20.0
	proc_mat.initial_velocity_min = 0.03
	proc_mat.initial_velocity_max = 0.10
	proc_mat.scale_min = 0.8
	proc_mat.scale_max = 1.6

	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(1, 1, 1, 0.0),
		Color(1, 1, 1, 1.0),
		Color(1, 1, 1, 1.0),
		Color(1, 1, 1, 0.0),
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.15, 0.80, 1.0])
	var ramp_tex := GradientTexture1D.new()
	ramp_tex.gradient = gradient
	proc_mat.color_ramp = ramp_tex

	particles.process_material = proc_mat
	root.add_child(particles)
