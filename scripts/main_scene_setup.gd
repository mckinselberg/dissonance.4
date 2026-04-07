extends Node3D

var drone: Node3D
var drone_route: Node3D
var mist_a: GPUParticles3D
var mist_b: GPUParticles3D
var street_lights: Node3D
var player: Node3D


func _ready() -> void:
	randomize()
	_resolve_scene_nodes()

	if drone != null and drone.has_method("randomize_motion"):
		drone.call("randomize_motion", randf_range(0.0, TAU))
	if drone != null and drone.has_method("set_route"):
		drone.call("set_route", drone_route)
	if drone != null and drone.has_method("set_player"):
		drone.call("set_player", player)
	if drone != null and drone.has_method("set_route_gizmo_visible"):
		drone.call("set_route_gizmo_visible", true)
	_apply_saved_runtime_settings()

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

	_require_authored_node("SceneProps", "Gameplay/SceneProps", "SceneProps root")
	_require_authored_node("Zones", "Gameplay/Zones", "Zones root")

	var collection_mgr := _resolve_collection_manager()

	var hud := _require_authored_node("UI/PlayerHUD", "PlayerHUD", "PlayerHUD scene")
	if hud != null and hud.has_method("setup"):
		hud.call("setup", player)
	if collection_mgr != null:
		if hud != null and hud.has_method("setup_collection"):
			hud.call("setup_collection", collection_mgr)

	var pause_menu := _require_authored_node("UI/PauseMenu", "PauseMenu", "PauseMenu scene")
	if pause_menu != null and pause_menu.has_method("setup"):
		pause_menu.call("setup", player)

	_restore_save_state()


func _apply_saved_runtime_settings() -> void:
	if player != null:
		player.set("mouse_sensitivity", SaveLoad.mouse_sensitivity)

	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(max(SaveLoad.master_volume_linear, 0.001)))

	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if SaveLoad.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)

	for action_name in SaveLoad.keybinds.keys():
		var action: StringName = action_name
		var keycode: int = int(SaveLoad.keybinds[action_name])
		if keycode == KEY_NONE:
			continue
		_apply_keybind(action, keycode)


func _apply_keybind(action: StringName, keycode: int) -> void:
	if not InputMap.has_action(action):
		return
	InputMap.action_erase_events(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)


func _restore_save_state() -> void:
	# Restore player progression from SaveLoad autoload
	if player != null:
		if SaveLoad.has_regulator:
			player.set("has_regulator", true)
		if SaveLoad.jammer_charges > 0:
			player.set("jammer_charges", SaveLoad.jammer_charges)

	# Restore drone fault state
	if SaveLoad.drone_disabled and drone != null and drone.has_method("trigger_fault_takedown"):
		# Drone was already crashed — teleport it below ground and disable
		drone.global_position = Vector3(0.0, -20.0, 0.0)
		drone.call("trigger_fault_takedown", drone.global_position)


func _resolve_scene_nodes() -> void:
	drone = _require_authored_node("Gameplay/Drone", "Drone", "Drone") as Node3D
	drone_route = _require_authored_node("Gameplay/DroneRoute", "DroneRoute", "DroneRoute") as Node3D
	mist_a = _require_authored_node("World/MistParticles_A", "MistParticles_A", "MistParticles_A") as GPUParticles3D
	mist_b = _require_authored_node("World/MistParticles_B", "MistParticles_B", "MistParticles_B") as GPUParticles3D
	street_lights = _require_authored_node("World/StreetLights", "StreetLights", "StreetLights") as Node3D
	player = _require_authored_node("Gameplay/Player", "Player", "Player") as Node3D


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
	var collectibles_root := _require_authored_node("Collectibles", "Gameplay/Collectibles", "Collectibles root")
	if collectibles_root == null:
		return null

	var existing_manager := collectibles_root.get_node_or_null("CollectionManager") as CollectionManager
	if existing_manager != null:
		return existing_manager

	push_warning("Missing authored CollectionManager under Collectibles root. The vertical slice should not rely on runtime fallback creation here.")
	return null


func _require_authored_node(primary_path: String, fallback_path: String, label: String) -> Node:
	var primary := get_node_or_null(primary_path)
	if primary != null:
		return primary

	if fallback_path != "":
		var fallback := get_node_or_null(fallback_path)
		if fallback != null:
			push_warning("%s is still using legacy path '%s'. Move it to '%s'." % [label, fallback_path, primary_path])
			return fallback

	push_warning("Missing authored %s at '%s'." % [label, primary_path])
	return null


func _find_node(primary_path: String, fallback_path: String = "") -> Node:
	var node := get_node_or_null(primary_path)
	if node != null:
		return node
	if fallback_path != "":
		return get_node_or_null(fallback_path)
	return null
