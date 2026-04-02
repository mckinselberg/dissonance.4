extends Node3D

const SceneProps        := preload("res://scripts/scene_props.gd")
const ZonesSetup        := preload("res://scripts/zones_setup.gd")
const CollectiblesSetup := preload("res://scripts/collectibles_setup.gd")
const PlayerHudScene    := preload("res://scenes/player_hud.tscn")

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

	_apply_scene_runtime_adjustments()

	for mist in [mist_a, mist_b]:
		if mist.has_method("set_phase_offset"):
			mist.call("set_phase_offset", randf_range(0.0, TAU))

	var energy_scale := 2.370
	for child in street_lights.get_children():
		var lamp_light: OmniLight3D = child.get_node_or_null("LampLight")
		if lamp_light:
			lamp_light.light_energy *= energy_scale

	var scene_props_root := _find_node("Gameplay/SceneProps", "SceneProps")
	if scene_props_root == null:
		var props_spawner := SceneProps.new()
		add_child(props_spawner)
		props_spawner.setup(self)

	var zones_root := _find_node("Gameplay/Zones", "Zones")
	if zones_root == null:
		var zones_spawner := ZonesSetup.new()
		add_child(zones_spawner)
		zones_spawner.setup(self)

	var collection_mgr := _resolve_collection_manager()

	var hud := _find_node("UI/PlayerHUD", "PlayerHUD")
	if hud == null:
		hud = PlayerHudScene.instantiate()
		var ui_root := _find_node("UI")
		if ui_root:
			ui_root.add_child(hud)
		else:
			add_child(hud)
	hud.setup(player)
	if collection_mgr != null:
		hud.setup_collection(collection_mgr)


func _apply_scene_runtime_adjustments() -> void:
	# Remove original rear wall at Z=-128.5 so the extended boulevard is reachable.
	# boulevard_terminus.gd places a new wall at Z=-345.
	var rear_mesh := get_node_or_null("LevelBounds/RearWall")
	if rear_mesh:
		rear_mesh.queue_free()
	var rear_body := get_node_or_null("LevelBounds/RearWall_Body")
	if rear_body:
		rear_body.queue_free()


func _resolve_collection_manager() -> CollectionManager:
	var collectibles_root := _find_node("Gameplay/Collectibles", "Collectibles")
	if collectibles_root != null:
		var existing_manager := collectibles_root.get_node_or_null("CollectionManager") as CollectionManager
		if existing_manager != null:
			return existing_manager

	var collectibles_spawner := CollectiblesSetup.new()
	add_child(collectibles_spawner)
	return collectibles_spawner.setup(self)


func _find_node(primary_path: String, fallback_path: String = "") -> Node:
	var node := get_node_or_null(primary_path)
	if node != null:
		return node
	if fallback_path != "":
		return get_node_or_null(fallback_path)
	return null
