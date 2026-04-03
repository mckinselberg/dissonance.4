extends Node3D

const SceneProps        := preload("res://scripts/scene_props.gd")
const ZonesSetup        := preload("res://scripts/zones_setup.gd")
const CollectiblesSetup := preload("res://scripts/collectibles_setup.gd")
const PlayerHudScene    := preload("res://scenes/player_hud.tscn")

var drone: Node3D
var drone_route: Node3D
var mist_a: GPUParticles3D
var mist_b: GPUParticles3D
var street_lights: Node3D
var player: Node3D


func _ready() -> void:
	randomize()
	_resolve_scene_nodes()

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
		if mist != null and mist.has_method("set_phase_offset"):
			mist.call("set_phase_offset", randf_range(0.0, TAU))

	var energy_scale := 2.370
	if street_lights != null:
		for child in street_lights.get_children():
			var lamp_light: OmniLight3D = child.get_node_or_null("LampLight")
			if lamp_light:
				lamp_light.light_energy *= energy_scale

	var scene_props_root := _find_node("SceneProps", "Gameplay/SceneProps")
	if scene_props_root == null:
		scene_props_root = _ensure_content_root("SceneProps")
		SceneProps.new().setup(scene_props_root)

	var zones_root := _find_node("Zones", "Gameplay/Zones")
	if zones_root == null:
		zones_root = _ensure_content_root("Zones")
		ZonesSetup.new().setup(zones_root)

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


func _resolve_scene_nodes() -> void:
	drone = _find_node("Gameplay/Drone", "Drone") as Node3D
	drone_route = _find_node("Gameplay/DroneRoute", "DroneRoute") as Node3D
	mist_a = _find_node("World/MistParticles_A", "MistParticles_A") as GPUParticles3D
	mist_b = _find_node("World/MistParticles_B", "MistParticles_B") as GPUParticles3D
	street_lights = _find_node("World/StreetLights", "StreetLights") as Node3D
	player = _find_node("Gameplay/Player", "Player") as Node3D


func _apply_scene_runtime_adjustments() -> void:
	# Remove original rear wall at Z=-128.5 so the extended boulevard is reachable.
	# boulevard_terminus.gd places a new wall at Z=-345.
	var rear_mesh := _find_node("World/LevelBounds/RearWall", "LevelBounds/RearWall")
	if rear_mesh:
		rear_mesh.queue_free()
	var rear_body := _find_node("World/LevelBounds/RearWall_Body", "LevelBounds/RearWall_Body")
	if rear_body:
		rear_body.queue_free()


func _resolve_collection_manager() -> CollectionManager:
	var collectibles_root := _find_node("Collectibles", "Gameplay/Collectibles")
	if collectibles_root != null:
		var existing_manager := collectibles_root.get_node_or_null("CollectionManager") as CollectionManager
		if existing_manager != null:
			return existing_manager

	collectibles_root = _ensure_content_root("Collectibles")
	return CollectiblesSetup.new().setup(collectibles_root)


func _ensure_content_root(node_name: String) -> Node3D:
	var existing := get_node_or_null(node_name) as Node3D
	if existing != null:
		return existing

	var root := Node3D.new()
	root.name = node_name
	add_child(root)
	return root


func _find_node(primary_path: String, fallback_path: String = "") -> Node:
	var node := get_node_or_null(primary_path)
	if node != null:
		return node
	if fallback_path != "":
		return get_node_or_null(fallback_path)
	return null
