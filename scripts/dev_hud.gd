extends CanvasLayer

const TOGGLE_ACTION := &"dev_hud_toggle"

@export var debug_overlay_enabled: bool = false

const PRESET_NIGHT := {
	"ambient_energy": 0.30,
	"exposure": 1.08,
	"directional_energy": 0.28,
	"streetlight_multiplier": 1.0,
	"glow_strength": 0.6,
	"fog_density": 0.015,
	"volumetric_fog_density": 0.009,
	"ground_fog_a": 0.28,
	"ground_fog_b": 0.20,
	"mid_fog_a": 0.10,
	"background_color": Color(0.018, 0.019, 0.023),
}

const PRESET_DAY := {
	"ambient_energy": 0.55,
	"exposure": 1.20,
	"directional_energy": 0.55,
	"streetlight_multiplier": 0.3,
	"glow_strength": 0.2,
	"fog_density": 0.004,
	"volumetric_fog_density": 0.002,
	"ground_fog_a": 0.05,
	"ground_fog_b": 0.04,
	"mid_fog_a": 0.02,
	"background_color": Color(0.38, 0.52, 0.72),
}

var _environment: Environment
var _directional_light: DirectionalLight3D
var _street_lights: Node3D
var _drone: Node3D
var _fog_materials: Dictionary = {}
var _streetlight_base_energy: Dictionary = {}
var _streetlight_base_volumetric: Dictionary = {}

var _panel: PanelContainer
var _rows: Dictionary = {}
var _dump_text: TextEdit
var _copy_button: Button


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if not debug_overlay_enabled:
		set_process_unhandled_input(false)
		return
	_ensure_input_action()
	_build_ui()
	call_deferred("_bind_scene")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(TOGGLE_ACTION):
		_toggle_visibility()
		get_viewport().set_input_as_handled()


func _bind_scene() -> void:
	var root := get_parent()
	if root != null and root.name == "Debug":
		root = root.get_parent()
	if root == null:
		return

	var world_environment: WorldEnvironment = _find_node(root, "WorldEnvironment", "World/WorldEnvironment") as WorldEnvironment
	_directional_light = _find_node(root, "DirectionalLight3D", "World/DirectionalLight3D") as DirectionalLight3D
	_street_lights = _find_node(root, "StreetLights", "World/StreetLights") as Node3D
	_drone = _find_node(root, "Drone", "Gameplay/Drone") as Node3D

	if world_environment:
		_environment = world_environment.environment

	var fog_group: Node3D = _find_node(root, "FogVolumes", "World/FogVolumes") as Node3D
	if fog_group:
		for fog_volume in fog_group.get_children():
			if fog_volume is FogVolume and fog_volume.material is FogMaterial:
				_fog_materials[fog_volume.name] = fog_volume.material

	if _street_lights:
		for child in _street_lights.get_children():
			var lamp: OmniLight3D = child.get_node_or_null("LampLight")
			if lamp:
				_streetlight_base_energy[lamp] = lamp.light_energy
				_streetlight_base_volumetric[lamp] = lamp.light_volumetric_fog_energy

	_sync_from_scene()


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "DevPanel"
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.offset_left = 16.0
	_panel.offset_top = 16.0
	_panel.offset_right = 356.0
	_panel.offset_bottom = 592.0
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "Dev Lighting HUD"
	layout.add_child(title)

	var hint := Label.new()
	hint.text = "F1 toggle, drag sliders live"
	layout.add_child(hint)

	_build_preset_buttons(layout)

	_add_slider(layout, "ambient_energy", "Ambient", 0.0, 0.6, 0.01)
	_add_slider(layout, "exposure", "Exposure", 0.6, 1.4, 0.01)
	_add_slider(layout, "directional_energy", "Moon Fill", 0.0, 0.6, 0.01)
	_add_slider(layout, "streetlight_multiplier", "Streetlights", 0.4, 2.4, 0.01)
	_add_slider(layout, "glow_strength", "Glow", 0.0, 1.2, 0.01)
	_add_slider(layout, "fog_density", "Fog Density", 0.0, 0.05, 0.001)
	_add_slider(layout, "volumetric_fog_density", "Vol Fog", 0.0, 0.04, 0.001)
	_add_slider(layout, "ground_fog_a", "Ground Fog A", 0.0, 0.7, 0.01)
	_add_slider(layout, "ground_fog_b", "Ground Fog B", 0.0, 0.6, 0.01)
	_add_slider(layout, "mid_fog_a", "Mid Fog", 0.0, 0.4, 0.01)

	var button_row := HBoxContainer.new()
	layout.add_child(button_row)

	_copy_button = Button.new()
	_copy_button.text = "Copy Current Values"
	_copy_button.pressed.connect(_copy_current_values)
	button_row.add_child(_copy_button)

	var gizmo_toggle := CheckBox.new()
	gizmo_toggle.text = "Route Gizmo"
	gizmo_toggle.button_pressed = true
	gizmo_toggle.toggled.connect(_on_route_gizmo_toggled)
	button_row.add_child(gizmo_toggle)

	var mute_toggle := CheckBox.new()
	mute_toggle.text = "Mute"
	mute_toggle.button_pressed = false
	mute_toggle.toggled.connect(_on_mute_toggled)
	button_row.add_child(mute_toggle)

	var dump_label := Label.new()
	dump_label.text = "Runtime value dump"
	layout.add_child(dump_label)

	_dump_text = TextEdit.new()
	_dump_text.custom_minimum_size = Vector2(0.0, 180.0)
	_dump_text.editable = false
	_dump_text.scroll_fit_content_height = false
	_dump_text.wrap_mode = TextEdit.LINE_WRAPPING_NONE
	layout.add_child(_dump_text)


func _add_slider(parent: VBoxContainer, key: String, label_text: String, min_value: float, max_value: float, step: float) -> void:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 2)
	parent.add_child(section)

	var row_header := HBoxContainer.new()
	section.add_child(row_header)

	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_header.add_child(label)

	var value_label := Label.new()
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size = Vector2(58.0, 0.0)
	row_header.add_child(value_label)

	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_slider_changed.bind(key))
	section.add_child(slider)

	_rows[key] = {
		"slider": slider,
		"value_label": value_label,
	}


func _sync_from_scene() -> void:
	if _environment == null:
		return

	_set_slider_value("ambient_energy", _environment.ambient_light_energy)
	_set_slider_value("exposure", _environment.tonemap_exposure)
	_set_slider_value("directional_energy", _directional_light.light_energy if _directional_light else 0.0)
	_set_slider_value("streetlight_multiplier", 1.0)
	_set_slider_value("glow_strength", _environment.glow_strength)
	_set_slider_value("fog_density", _environment.fog_density)
	_set_slider_value("volumetric_fog_density", _environment.volumetric_fog_density)
	_set_slider_value("ground_fog_a", _get_fog_density("GroundFog_A"))
	_set_slider_value("ground_fog_b", _get_fog_density("GroundFog_B"))
	_set_slider_value("mid_fog_a", _get_fog_density("MidFog_A"))
	_refresh_dump_text()


func _set_slider_value(key: String, value: float) -> void:
	if not _rows.has(key):
		return

	var slider: HSlider = _rows[key]["slider"]
	slider.set_value_no_signal(value)
	_update_value_label(key, value)


func _update_value_label(key: String, value: float) -> void:
	if not _rows.has(key):
		return

	var value_label: Label = _rows[key]["value_label"]
	value_label.text = "%.3f" % value


func _on_slider_changed(value: float, key: String) -> void:
	_update_value_label(key, value)

	if _environment == null:
		return

	match key:
		"ambient_energy":
			_environment.ambient_light_energy = value
		"exposure":
			_environment.tonemap_exposure = value
		"directional_energy":
			if _directional_light:
				_directional_light.light_energy = value
		"streetlight_multiplier":
			_apply_streetlight_multiplier(value)
		"glow_strength":
			_environment.glow_strength = value
		"fog_density":
			_environment.fog_density = value
		"volumetric_fog_density":
			_environment.volumetric_fog_density = value
		"ground_fog_a":
			_set_fog_density("GroundFog_A", value)
		"ground_fog_b":
			_set_fog_density("GroundFog_B", value)
		"mid_fog_a":
			_set_fog_density("MidFog_A", value)

	_refresh_dump_text()


func _apply_streetlight_multiplier(multiplier: float) -> void:
	for lamp in _streetlight_base_energy.keys():
		if is_instance_valid(lamp):
			lamp.light_energy = _streetlight_base_energy[lamp] * multiplier
			lamp.light_volumetric_fog_energy = _streetlight_base_volumetric[lamp] * multiplier


func _get_fog_density(fog_key: String) -> float:
	var fog_material: FogMaterial = _fog_materials.get(fog_key)
	return fog_material.density if fog_material else 0.0


func _set_fog_density(fog_key: String, value: float) -> void:
	var fog_material: FogMaterial = _fog_materials.get(fog_key)
	if fog_material:
		fog_material.density = value


func _toggle_visibility() -> void:
	visible = not visible
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _ensure_input_action() -> void:
	if not InputMap.has_action(TOGGLE_ACTION):
		InputMap.add_action(TOGGLE_ACTION)

	for action_event in InputMap.action_get_events(TOGGLE_ACTION):
		if action_event is InputEventKey and action_event.physical_keycode == KEY_F1:
			return

	var event := InputEventKey.new()
	event.physical_keycode = KEY_F1
	InputMap.action_add_event(TOGGLE_ACTION, event)


func _refresh_dump_text() -> void:
	if _dump_text == null or _environment == null:
		return

	var lines := PackedStringArray()
	lines.append("# Environment")
	lines.append("ambient_light_energy = %.3f" % _environment.ambient_light_energy)
	lines.append("ambient_light_color = %s" % _format_color(_environment.ambient_light_color))
	lines.append("tonemap_exposure = %.3f" % _environment.tonemap_exposure)
	lines.append("glow_strength = %.3f" % _environment.glow_strength)
	lines.append("fog_density = %.3f" % _environment.fog_density)
	lines.append("volumetric_fog_density = %.3f" % _environment.volumetric_fog_density)

	if _directional_light:
		lines.append("")
		lines.append("# DirectionalLight3D")
		lines.append("light_energy = %.3f" % _directional_light.light_energy)
		lines.append("light_volumetric_fog_energy = %.3f" % _directional_light.light_volumetric_fog_energy)

	lines.append("")
	lines.append("# FogVolumes")
	lines.append("GroundFog_A.density = %.3f" % _get_fog_density("GroundFog_A"))
	lines.append("GroundFog_B.density = %.3f" % _get_fog_density("GroundFog_B"))
	lines.append("MidFog_A.density = %.3f" % _get_fog_density("MidFog_A"))

	var streetlight_multiplier := _get_slider_value("streetlight_multiplier")
	lines.append("")
	lines.append("# Streetlights")
	lines.append("multiplier = %.3f" % streetlight_multiplier)

	lines.append("")
	lines.append("# Drone")
	lines.append("route_gizmo_visible = %s" % str(_is_route_gizmo_visible()))

	_dump_text.text = "\n".join(lines)


func _copy_current_values() -> void:
	_refresh_dump_text()
	DisplayServer.clipboard_set(_dump_text.text)
	_copy_button.text = "Copied"


func _get_slider_value(key: String) -> float:
	if not _rows.has(key):
		return 0.0
	var slider: HSlider = _rows[key]["slider"]
	return slider.value


func _format_color(color: Color) -> String:
	return "Color(%.3f, %.3f, %.3f, %.3f)" % [color.r, color.g, color.b, color.a]


func _on_mute_toggled(button_pressed: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), button_pressed)


func _on_route_gizmo_toggled(button_pressed: bool) -> void:
	if _drone and _drone.has_method("set_route_gizmo_visible"):
		_drone.call("set_route_gizmo_visible", button_pressed)
	_refresh_dump_text()


func _is_route_gizmo_visible() -> bool:
	if _drone == null:
		return false
	var root := get_parent()
	if root != null and root.name == "Debug":
		root = root.get_parent()
	var route_root := _find_node(root, "DroneRoute", "Gameplay/DroneRoute") if root else null
	var gizmo := route_root.get_node_or_null("RouteGizmo") if route_root else null
	return gizmo.visible if gizmo else false


func _build_preset_buttons(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)

	var night_btn := Button.new()
	night_btn.text = "Night"
	night_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	night_btn.pressed.connect(_apply_preset.bind(PRESET_NIGHT))
	row.add_child(night_btn)

	var day_btn := Button.new()
	day_btn.text = "Day"
	day_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	day_btn.pressed.connect(_apply_preset.bind(PRESET_DAY))
	row.add_child(day_btn)


func _apply_preset(preset: Dictionary) -> void:
	for key in preset:
		if key == "background_color":
			if _environment:
				_environment.background_color = preset[key]
			continue
		if _rows.has(key):
			_rows[key]["slider"].value = preset[key]
	_refresh_dump_text()


func _find_node(root: Node, direct_path: String, nested_path: String) -> Node:
	var node := root.get_node_or_null(direct_path)
	if node != null:
		return node
	return root.get_node_or_null(nested_path)
