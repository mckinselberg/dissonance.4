extends CanvasLayer

var _player: Node3D
var _camera: Camera3D
var _bars: Dictionary = {}

@onready var _overlay: ColorRect = $Overlay
@onready var _status_panel: PanelContainer = $StatusPanel
@onready var _zone_label: Label = $StatusPanel/Margin/VBox/ZoneLabel
@onready var _state_zone_label: Label = $StatusPanel/Margin/VBox/StateZoneLabel
@onready var _hint_label: Label = $StatusPanel/Margin/VBox/HintLabel
@onready var _collect_label: Label = $StatusPanel/Margin/VBox/CollectLabel
@onready var _flashlight_btn: Button = $StatusPanel/Margin/VBox/FlashlightButton
@onready var _completion_panel: PanelContainer = $CompletionPanel
@onready var _gameover_panel: PanelContainer = $GameOverPanel

const _OVERLAY_COLOR := Color(0.62, 0.02, 0.48)
const _BURNOUT_THRESHOLD := 0.65
const _BURNOUT_TIME_TO_GAMEOVER := 5.0

var _burnout_exposure_time: float = 0.0
var _burnout_triggered: bool = false


func _ready() -> void:
	_bind_bars()
	_apply_scene_styles()
	_flashlight_btn.pressed.connect(_on_flashlight_btn_pressed)


func setup(player: Node3D) -> void:
	_player = player
	_camera = player.get_node_or_null("Head/Camera3D")


func setup_collection(manager: CollectionManager) -> void:
	_collect_label.text = "Signal  0 / %d" % manager.get_total()
	manager.item_collected.connect(_on_item_collected)
	manager.all_collected.connect(_on_all_collected)


func _on_item_collected(count: int, total: int) -> void:
	_collect_label.text = "Signal  %d / %d" % [count, total]


func _on_all_collected() -> void:
	_collect_label.text = "Signal complete"
	_collect_label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.6))
	_completion_panel.visible = true
	_completion_panel.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(4.5)
	tween.tween_property(_completion_panel, "modulate:a", 0.0, 1.2)
	tween.tween_callback(_completion_panel.hide)


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var state: StateModel = _player.get("state")
	if state == null:
		return
	_update_bars(state)
	_update_labels(state)
	_update_threat_fx(delta)
	_update_flashlight_btn()
	if not _burnout_triggered:
		_update_burnout_timer(state, delta)


func _update_threat_fx(delta: float) -> void:
	var threat := _compute_drone_threat()
	var pulse := sin(Time.get_ticks_msec() * 0.006) * 0.05 * threat
	_overlay.color = Color(_OVERLAY_COLOR, clamp(threat * 0.32 + pulse, 0.0, 0.38))

	if _camera != null:
		if threat > 0.15:
			var jitter := threat * threat * 0.025
			_camera.h_offset = randf_range(-jitter, jitter)
			_camera.v_offset = randf_range(-jitter, jitter)
		else:
			_camera.h_offset = lerp(_camera.h_offset, 0.0, delta * 10.0)
			_camera.v_offset = lerp(_camera.v_offset, 0.0, delta * 10.0)


func _update_flashlight_btn() -> void:
	if _player == null:
		return
	var fl := _player.get_node_or_null("Head/Flashlight")
	if fl == null:
		return
	var on: bool = fl.visible
	_flashlight_btn.text = ("Active light [F]" if on else "Light [F]")
	var col := Color(0.95, 0.92, 0.6) if on else Color(0.55, 0.55, 0.45)
	_flashlight_btn.add_theme_color_override("font_color", col)


func _on_flashlight_btn_pressed() -> void:
	if _player != null and _player.has_method("toggle_flashlight"):
		_player.call("toggle_flashlight")


func _update_burnout_timer(state: StateModel, delta: float) -> void:
	var drone_threat := _compute_drone_threat()
	var pressure: float = max(state.burnout_risk, drone_threat)
	if pressure >= _BURNOUT_THRESHOLD:
		_burnout_exposure_time += delta
		if _burnout_exposure_time >= _BURNOUT_TIME_TO_GAMEOVER:
			_trigger_burnout_gameover()
	else:
		_burnout_exposure_time = max(0.0, _burnout_exposure_time - delta * 0.5)


func _trigger_burnout_gameover() -> void:
	_burnout_triggered = true
	_overlay.color = Color(_OVERLAY_COLOR, 0.85)
	_gameover_panel.visible = true
	var tween := create_tween()
	tween.tween_interval(2.5)
	tween.tween_callback(Callable(get_tree(), "reload_current_scene"))


func _compute_drone_threat() -> float:
	if _player == null:
		return 0.0
	var drones := get_tree().get_nodes_in_group("drones")
	var max_threat := 0.0
	var player_pos := _player.global_position
	for drone in drones:
		if not drone.has_method("get_alert_level"):
			continue
		var alert: float = drone.call("get_alert_level")
		var dist: float = player_pos.distance_to(drone.global_position)
		var detection_range: float = float(drone.get("detection_range"))
		var dist_factor: float = clamp(1.0 - dist / (detection_range * 1.5), 0.0, 1.0)
		max_threat = max(max_threat, alert * (0.5 + dist_factor * 0.5))
	return clamp(max_threat, 0.0, 1.0)


func _bind_bars() -> void:
	_bars = {
		"signal": $StatusPanel/Margin/VBox/SignalRow/SignalBar,
		"coherence": $StatusPanel/Margin/VBox/CoherenceRow/CoherenceBar,
		"focus": $StatusPanel/Margin/VBox/FocusRow/FocusBar,
		"energy": $StatusPanel/Margin/VBox/EnergyRow/EnergyBar,
		"mood": $StatusPanel/Margin/VBox/MoodRow/MoodBar,
		"social": $StatusPanel/Margin/VBox/SocialRow/SocialBar,
		"sensory": $StatusPanel/Margin/VBox/SensoryRow/SensoryBar,
		"burnout": $StatusPanel/Margin/VBox/BurnoutRow/BurnoutBar,
	}


func _apply_scene_styles() -> void:
	_overlay.color = Color(_OVERLAY_COLOR, 0.0)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.04, 0.05, 0.72)
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	_status_panel.add_theme_stylebox_override("panel", panel_style)

	_apply_label_style(_zone_label, Color(0.9, 0.85, 0.7), 10)
	_apply_label_style(_state_zone_label, Color(0.6, 0.65, 0.75), 10)
	_apply_label_style(_hint_label, Color(0.65, 0.65, 0.55), 10)
	_apply_label_style(_collect_label, Color(0.85, 0.78, 0.35), 11)

	for row_name in [
		"SignalRow", "CoherenceRow", "FocusRow", "EnergyRow",
		"MoodRow", "SocialRow", "SensoryRow", "BurnoutRow"
	]:
		var row := $StatusPanel/Margin/VBox.get_node(row_name) as HBoxContainer
		var label := row.get_node("Label") as Label
		_apply_label_style(label, Color(0.75, 0.75, 0.75), 10)

	_flashlight_btn.add_theme_font_size_override("font_size", 10)
	_flashlight_btn.add_theme_color_override("font_color", Color(0.55, 0.55, 0.45))
	_flashlight_btn.add_theme_color_override("font_hover_color", Color(0.85, 0.82, 0.6))

	_apply_bar_style(_bars["signal"], Color(0.85, 0.25, 0.22))
	_apply_bar_style(_bars["coherence"], Color(0.25, 0.72, 0.78))
	_apply_bar_style(_bars["focus"], Color(0.42, 0.62, 0.88))
	_apply_bar_style(_bars["energy"], Color(0.38, 0.78, 0.48))
	_apply_bar_style(_bars["mood"], Color(0.72, 0.52, 0.82))
	_apply_bar_style(_bars["social"], Color(0.88, 0.55, 0.22))
	_apply_bar_style(_bars["sensory"], Color(0.88, 0.32, 0.32))
	_apply_bar_style(_bars["burnout"], Color(0.95, 0.18, 0.18))

	_apply_completion_style()
	_apply_gameover_style()


func _update_bars(state: StateModel) -> void:
	_set_bar("signal", state.signal_visibility)
	_set_bar("coherence", state.harmonic_coherence)
	_set_bar("focus", state.focus)
	_set_bar("energy", state.energy)
	_set_bar("mood", state.mood)
	_set_bar("social", state.social_load)
	_set_bar("sensory", state.sensory_load)
	_set_bar("burnout", state.burnout_risk)


func _update_labels(state: StateModel) -> void:
	_state_zone_label.text = state.zone

	var zones: Array = _player.get("active_zones")
	if zones != null and not zones.is_empty():
		var best: Object = zones[0]
		for z in zones:
			if int(z.get("zone_priority")) > int(best.get("zone_priority")):
				best = z
		_zone_label.text = str(best.get("zone_label"))
	else:
		_zone_label.text = "-"

	var in_rest: bool = _player.get("_in_rest_zone") == true
	var jammer_active: bool = _player.get("jammer_active") == true
	var jammer_charges: int = int(_player.get("jammer_charges"))
	var has_regulator: bool = _player.get("has_regulator") == true
	var can_grab: bool = false
	if _player.get("can_grab_drone"):
		can_grab = true

	if can_grab:
		_hint_label.text = "[SPACE] pull down"
	elif jammer_active:
		_hint_label.text = "Jammer active"
	elif jammer_charges > 0:
		_hint_label.text = "[J] jammer ready"
	elif has_regulator:
		_hint_label.text = "Bring component to relay"
	elif in_rest:
		_hint_label.text = "[E] rest"
	elif state.burnout_risk > 0.65:
		_hint_label.text = "burnout edge"
	elif state.signal_visibility > 0.6:
		_hint_label.text = "[R] regulate"
	else:
		_hint_label.text = ""


func _set_bar(key: String, value: float) -> void:
	if _bars.has(key):
		_bars[key].value = value


func _apply_completion_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.02, 0.08, 0.88)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_color = Color(0.62, 0.02, 0.48, 0.6)
	_completion_panel.add_theme_stylebox_override("panel", style)

	var title := $CompletionPanel/Margin/VBox/Title as Label
	var subtitle := $CompletionPanel/Margin/VBox/Subtitle as Label
	_apply_label_style(title, Color(0.95, 0.88, 0.4), 16)
	_apply_label_style(subtitle, Color(0.72, 0.65, 0.85), 11)


func _apply_gameover_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.01, 0.04, 0.95)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.88, 0.05, 0.35, 0.9)
	_gameover_panel.add_theme_stylebox_override("panel", style)

	var title := $GameOverPanel/Margin/VBox/Title as Label
	var subtitle := $GameOverPanel/Margin/VBox/Subtitle as Label
	_apply_label_style(title, Color(1.0, 0.12, 0.35), 22)
	_apply_label_style(subtitle, Color(0.78, 0.55, 0.68), 11)


func _apply_bar_style(bar: ProgressBar, color: Color) -> void:
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = color
	bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.12, 0.12, 0.14)
	bar.add_theme_stylebox_override("background", bg_style)


func _apply_label_style(lbl: Label, color: Color, font_size: int) -> void:
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
