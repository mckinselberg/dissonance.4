extends CanvasLayer

var _player: Node3D
var _bars: Dictionary = {}
var _zone_label: Label
var _state_zone_label: Label
var _hint_label: Label


func setup(player: Node3D) -> void:
	_player = player
	_build_ui()


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var state: StateModel = _player.get("state")
	if state == null:
		return
	_update_bars(state)
	_update_labels(state)


func _build_ui() -> void:
	layer = 5

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -220.0
	panel.offset_top = 16.0
	panel.offset_right = -16.0
	panel.offset_bottom = 320.0

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


func _add_bar(parent: VBoxContainer, key: String, label_text: String, color: Color, scale: int = 1) -> void:
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
	bar.custom_minimum_size = Vector2(0.0, 6.0 * scale)

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


func _make_label(text: String, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", color)
	return lbl
