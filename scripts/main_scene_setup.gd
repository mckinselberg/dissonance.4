extends Node3D

const SceneProps        := preload("res://scripts/scene_props.gd")
const ZonesSetup        := preload("res://scripts/zones_setup.gd")
const PlayerHud         := preload("res://scripts/player_hud.gd")
const CollectiblesSetup := preload("res://scripts/collectibles_setup.gd")
const BuildingInterior  := preload("res://scripts/building_interior.gd")
const MistSetup         := preload("res://scripts/mist_setup.gd")
const WorldExtension    := preload("res://scripts/world_extension.gd")

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

	for mist in [mist_a, mist_b]:
		if mist.has_method("set_phase_offset"):
			mist.call("set_phase_offset", randf_range(0.0, TAU))

	var energy_scale := randf_range(0.92, 1.05)
	for child in street_lights.get_children():
		var lamp_light: OmniLight3D = child.get_node_or_null("LampLight")
		if lamp_light:
			lamp_light.light_energy *= energy_scale

	var building_spawner := BuildingInterior.new()
	add_child(building_spawner)
	building_spawner.setup(self)

	var mist_spawner := MistSetup.new()
	add_child(mist_spawner)
	mist_spawner.setup(self)

	var world_ext := WorldExtension.new()
	add_child(world_ext)
	world_ext.setup(self)

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
