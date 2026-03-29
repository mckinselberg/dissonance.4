extends CanvasLayer

var _player: Node3D
var _camera: Camera3D
var _bars: Dictionary = {}
var _zone_label: Label
var _state_zone_label: Label
var _hint_label: Label
var _collect_label: Label
var _flashlight_btn: Button
var _completion_panel: Control
var _gameover_panel: Control
var _overlay: ColorRect

const _OVERLAY_COLOR := Color(0.62, 0.02, 0.48)
const _BURNOUT_THRESHOLD := 0.65
const _BURNOUT_TIME_TO_GAMEOVER := 3.0

var _burnout_exposure_time: float = 0.0
var _burnout_triggered: bool = false


func setup(player: Node3D) -> void:
	_player = player
	_camera = player.get_node_or_null("Head/Camera3D")
	_build_ui()


func setup_collection(manager: CollectionManager) -> void:
	_collect_label.text = "♪  0 / %d" % manager.get_total()
	manager.item_collected.connect(_on_item_collected)
	manager.all_collected.connect(_on_all_collected)


func _on_item_collected(count: int, total: int) -> void:
	_collect_label.text = "♪  %d / %d" % [count, total]


func _on_all_collected() -> void:
	_collect_label.text = "♪  ✓ complete"
	_collect_label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.6))
	_completion_panel.visible = true
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

	# Overlay: pulse intensity scales with threat
	var pulse := sin(Time.get_ticks_msec() * 0.006) * 0.05 * threat
	_overlay.color = Color(_OVERLAY_COLOR, clamp(threat * 0.32 + pulse, 0.0, 0.38))

	# Camera jitter: quadratic ramp so it only kicks in at real threat
	if _camera != null:
		if threat > 0.15:
			var jitter := threat * threat * 0.025
			_camera.h_offset = randf_range(-jitter, jitter)
			_camera.v_offset = randf_range(-jitter, jitter)
		else:
			_camera.h_offset = lerp(_camera.h_offset, 0.0, delta * 10.0)
			_camera.v_offset = lerp(_camera.v_offset, 0.0, delta * 10.0)


func _update_flashlight_btn() -> void:
	if _player == null or _flashlight_btn == null:
		return
	var fl := _player.get_node_or_null("Head/Flashlight")
	if fl == null:
		return
	var on: bool = fl.visible
	_flashlight_btn.text = ("◉  light  [F]" if on else "○  light  [F]")
	var col := Color(0.95, 0.92, 0.6) if on else Color(0.55, 0.55, 0.45)
	_flashlight_btn.add_theme_color_override("font_color", col)


func _on_flashlight_btn_pressed() -> void:
	if _player != null and _player.has_method("toggle_flashlight"):
		_player.call("toggle_flashlight")


func _update_burnout_timer(state: StateModel, delta: float) -> void:
	# Drone threat is the primary pressure — don't wait for full state model chain
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


func _build_ui() -> void:
	layer = 5

	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(_OVERLAY_COLOR, 0.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -220.0
	panel.offset_top = 16.0
	panel.offset_right = -16.0
	panel.offset_bottom = 362.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.05, 0.72)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	margin.add_child(vbox)

	_zone_label = _make_label("—", Color(0.9, 0.85, 0.7))
	vbox.add_child(_zone_label)

	_state_zone_label = _make_label("neutral", Color(0.6, 0.65, 0.75))
	vbox.add_child(_state_zone_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Signal visibility is the primary stealth metric — shown first and larger
	_add_bar(vbox, "signal", "Signal", Color(0.85, 0.25, 0.22), 2)
	_add_bar(vbox, "coherence", "Coherence", Color(0.25, 0.72, 0.78), 1)

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	_add_bar(vbox, "focus", "Focus", Color(0.42, 0.62, 0.88))
	_add_bar(vbox, "energy", "Energy", Color(0.38, 0.78, 0.48))
	_add_bar(vbox, "mood", "Mood", Color(0.72, 0.52, 0.82))
	_add_bar(vbox, "social", "Social Load", Color(0.88, 0.55, 0.22))
	_add_bar(vbox, "sensory", "Sensory Load", Color(0.88, 0.32, 0.32))
	_add_bar(vbox, "burnout", "Burnout Risk", Color(0.95, 0.18, 0.18))

	var sep3 := HSeparator.new()
	vbox.add_child(sep3)

	_hint_label = _make_label("", Color(0.65, 0.65, 0.55))
	vbox.add_child(_hint_label)

	var sep4 := HSeparator.new()
	vbox.add_child(sep4)

	_collect_label = _make_label("♪  — / —", Color(0.85, 0.78, 0.35))
	_collect_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(_collect_label)

	var sep5 := HSeparator.new()
	vbox.add_child(sep5)

	_flashlight_btn = Button.new()
	_flashlight_btn.text = "○  light  [F]"
	_flashlight_btn.flat = true
	_flashlight_btn.add_theme_font_size_override("font_size", 10)
	_flashlight_btn.add_theme_color_override("font_color", Color(0.55, 0.55, 0.45))
	_flashlight_btn.add_theme_color_override("font_hover_color", Color(0.85, 0.82, 0.6))
	_flashlight_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_flashlight_btn.pressed.connect(_on_flashlight_btn_pressed)
	vbox.add_child(_flashlight_btn)

	# Completion panel — centered, hidden until all collected
	_completion_panel = _build_completion_panel()
	_completion_panel.visible = false
	add_child(_completion_panel)

	# Game-over panel — hidden until burnout threshold
	_gameover_panel = _build_gameover_panel()
	_gameover_panel.visible = false
	add_child(_gameover_panel)


func _add_bar(parent: VBoxContainer, key: String, label_text: String, color: Color, width_scale: int = 1) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(88.0, 0.0)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	row.add_child(lbl)

	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = 0.0
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size = Vector2(0.0, 6.0 * width_scale)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = color
	bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.12, 0.12, 0.14)
	bar.add_theme_stylebox_override("background", bg_style)

	row.add_child(bar)
	_bars[key] = bar


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
		_zone_label.text = "—"

	var in_rest: bool = _player.get("_in_rest_zone") == true
	if in_rest:
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


func _build_completion_panel() -> Control:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -240.0
	panel.offset_top = -80.0
	panel.offset_right = 240.0
	panel.offset_bottom = 80.0

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
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "♫  All signals recovered  ♫"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.4))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "The signal harmonizes."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color(0.72, 0.65, 0.85))
	vbox.add_child(subtitle)

	return panel


func _build_gameover_panel() -> Control:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -280.0
	panel.offset_top = -100.0
	panel.offset_right = 280.0
	panel.offset_bottom = 100.0

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
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "SIGNAL OVERLOAD"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.12, 0.35))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "The signal consumes you.\nRestarting..."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color(0.78, 0.55, 0.68))
	vbox.add_child(subtitle)

	return panel


func _make_label(text: String, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", color)
	return lbl
