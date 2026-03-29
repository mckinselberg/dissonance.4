extends Node3D

const SceneProps        := preload("res://scripts/scene_props.gd")
const ZonesSetup        := preload("res://scripts/zones_setup.gd")
const PlayerHud         := preload("res://scripts/player_hud.gd")
const CollectiblesSetup := preload("res://scripts/collectibles_setup.gd")

@onready var drone: Node3D = $Drone
@onready var drone_route: Node3D = $DroneRoute
@onready var mist_a: GPUParticles3D = $MistParticles_A
@onready var mist_b: GPUParticles3D = $MistParticles_B
@onready var street_lights: Node3D = $StreetLights
@onready var player: Node3D = $Player


func _ready() -> void:
	randomize()

	if drone.has_method("randomize_motion"):
		drone.call("randomize_motion", randf_range(0.0, TAU))
	if drone.has_method("set_route"):
		drone.call("set_route", drone_route)
	if drone.has_method("set_player"):
		drone.call("set_player", player)
	if drone.has_method("set_route_gizmo_visible"):
		drone.call("set_route_gizmo_visible", true)

	_apply_scene_defaults()

	for mist in [mist_a, mist_b]:
		if mist.has_method("set_phase_offset"):
			mist.call("set_phase_offset", randf_range(0.0, TAU))

	var energy_scale := 2.370
	for child in street_lights.get_children():
		var lamp_light: OmniLight3D = child.get_node_or_null("LampLight")
		if lamp_light:
			lamp_light.light_energy *= energy_scale

	var props_spawner := SceneProps.new()
	add_child(props_spawner)
	props_spawner.setup(self)

	var zones_spawner := ZonesSetup.new()
	add_child(zones_spawner)
	zones_spawner.setup(self)

	var collectibles_spawner := CollectiblesSetup.new()
	add_child(collectibles_spawner)
	var collection_mgr := collectibles_spawner.setup(self)

	var hud := PlayerHud.new()
	add_child(hud)
	hud.setup(player)
	hud.setup_collection(collection_mgr)


func _apply_scene_defaults() -> void:
	var dir_light := get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if dir_light:
		dir_light.light_energy = 0.550
		dir_light.light_volumetric_fog_energy = 0.280

	_set_fog_density("FogVolumes/GroundFog_A", 0.160)
	_set_fog_density("FogVolumes/GroundFog_B", 0.090)
	_set_fog_density("FogVolumes/MidFog_A", 0.020)

	# Remove original rear wall at Z=-128.5 so the extended boulevard is reachable.
	# boulevard_terminus.gd places a new wall at Z=-345.
	var rear_mesh := get_node_or_null("LevelBounds/RearWall")
	if rear_mesh:
		rear_mesh.queue_free()
	var rear_body := get_node_or_null("LevelBounds/RearWall_Body")
	if rear_body:
		rear_body.queue_free()


func _set_fog_density(path: String, density: float) -> void:
	var vol := get_node_or_null(path) as FogVolume
	if vol == null:
		return
	var mat := vol.material as FogMaterial
	if mat:
		mat.density = density
