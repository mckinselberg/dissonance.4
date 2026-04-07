extends CanvasLayer

@export var pause_action: StringName = &"ui_cancel"

const _REBIND_ACTIONS := [
	{action = &"move_forward", label = "Forward"},
	{action = &"move_back", label = "Back"},
	{action = &"move_left", label = "Left"},
	{action = &"move_right", label = "Right"},
	{action = &"move_jump", label = "Jump"},
	{action = &"move_sprint", label = "Sprint"},
	{action = &"player_regulate", label = "Regulate"},
	{action = &"player_rest", label = "Rest"},
	{action = &"player_interact", label = "Interact"},
	{action = &"player_flashlight", label = "Flashlight"},
]

var _player: Node3D
var _is_open: bool = false
var _awaiting_rebind_action: StringName = &""
var _rebind_buttons: Dictionary = {}
var _default_keybinds: Dictionary = {}

@onready var _backdrop: ColorRect = $Backdrop
@onready var _panel: PanelContainer = $Panel
@onready var _resume_button: Button = $Panel/Margin/VBox/Buttons/ResumeButton
@onready var _restart_button: Button = $Panel/Margin/VBox/Buttons/RestartButton
@onready var _new_game_button: Button = $Panel/Margin/VBox/Buttons/NewGameButton
@onready var _reset_settings_button: Button = $Panel/Margin/VBox/Buttons/ResetSettingsButton
@onready var _mouse_slider: HSlider = $Panel/Margin/VBox/Settings/MouseRow/MouseSlider
@onready var _mouse_value: Label = $Panel/Margin/VBox/Settings/MouseRow/MouseValue
@onready var _volume_slider: HSlider = $Panel/Margin/VBox/Settings/VolumeRow/VolumeSlider
@onready var _volume_value: Label = $Panel/Margin/VBox/Settings/VolumeRow/VolumeValue
@onready var _fullscreen_toggle: CheckBox = $Panel/Margin/VBox/Settings/FullscreenToggle
@onready var _rebind_status: Label = $Panel/Margin/VBox/Rebinds/RebindStatus


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_apply_styles()
	_resume_button.pressed.connect(_close_menu)
	_restart_button.pressed.connect(_restart_scene)
	_new_game_button.pressed.connect(_new_game)
	_reset_settings_button.pressed.connect(_reset_settings)
	_mouse_slider.value_changed.connect(_on_mouse_sensitivity_changed)
	_volume_slider.value_changed.connect(_on_master_volume_changed)
	_fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	_capture_default_keybinds()
	_bind_rebind_buttons()
	_sync_from_runtime()


func setup(player: Node3D) -> void:
	_player = player
	_sync_from_runtime()


func _unhandled_input(event: InputEvent) -> void:
	if _awaiting_rebind_action != &"":
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode == KEY_ESCAPE:
				_cancel_rebind_capture()
			else:
				_apply_rebind(_awaiting_rebind_action, event.physical_keycode)
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed(pause_action):
		if _is_open:
			_close_menu()
		else:
			_open_menu()
		get_viewport().set_input_as_handled()


func _open_menu() -> void:
	if _is_open:
		return
	_is_open = true
	get_tree().paused = true
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_resume_button.grab_focus()


func _close_menu() -> void:
	if not _is_open:
		return
	_cancel_rebind_capture()
	_is_open = false
	hide()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _restart_scene() -> void:
	get_tree().paused = false
	_is_open = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().reload_current_scene()


func _new_game() -> void:
	SaveLoad.delete_save()
	get_tree().paused = false
	_is_open = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().reload_current_scene()


func _sync_from_runtime() -> void:
	if _player != null and is_instance_valid(_player):
		var mouse_sensitivity: float = float(_player.get("mouse_sensitivity"))
		_mouse_slider.value = mouse_sensitivity
		_mouse_value.text = "%.4f" % mouse_sensitivity
	else:
		_mouse_value.text = "%.4f" % _mouse_slider.value

	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		var volume_db := AudioServer.get_bus_volume_db(master_bus)
		var volume_linear := db_to_linear(volume_db)
		_volume_slider.value = volume_linear
		_volume_value.text = "%d%%" % int(round(volume_linear * 100.0))

	var window_mode := DisplayServer.window_get_mode()
	_fullscreen_toggle.button_pressed = window_mode == DisplayServer.WINDOW_MODE_FULLSCREEN
	_refresh_rebind_labels()


func _on_mouse_sensitivity_changed(value: float) -> void:
	_mouse_value.text = "%.4f" % value
	if _player != null and is_instance_valid(_player):
		_player.set("mouse_sensitivity", value)
	SaveLoad.mouse_sensitivity = value
	SaveLoad.save_game()


func _on_master_volume_changed(value: float) -> void:
	_volume_value.text = "%d%%" % int(round(value * 100.0))
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(max(value, 0.001)))
	SaveLoad.master_volume_linear = value
	SaveLoad.save_game()


func _on_fullscreen_toggled(button_pressed: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if button_pressed else DisplayServer.WINDOW_MODE_WINDOWED
	)
	SaveLoad.fullscreen = button_pressed
	SaveLoad.save_game()


func _capture_default_keybinds() -> void:
	_default_keybinds.clear()
	for entry in _REBIND_ACTIONS:
		var action: StringName = entry.action
		var default_code: int = KEY_NONE
		for action_event in InputMap.action_get_events(action):
			if action_event is InputEventKey:
				var key_event := action_event as InputEventKey
				if key_event.physical_keycode != KEY_NONE:
					default_code = int(key_event.physical_keycode)
					break
		_default_keybinds[action] = default_code


func _reset_settings() -> void:
	SaveLoad.reset_runtime_settings()

	if _player != null and is_instance_valid(_player):
		_player.set("mouse_sensitivity", SaveLoad.mouse_sensitivity)
	_mouse_slider.value = SaveLoad.mouse_sensitivity

	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(max(SaveLoad.master_volume_linear, 0.001)))
	_volume_slider.value = SaveLoad.master_volume_linear

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	_fullscreen_toggle.button_pressed = false

	for action_name in _default_keybinds.keys():
		var action: StringName = action_name
		var keycode: int = int(_default_keybinds[action_name])
		if keycode == KEY_NONE:
			continue
		if not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = keycode
		InputMap.action_add_event(action, ev)

	_rebind_status.text = "Settings reset to defaults."
	_refresh_rebind_labels()


func _apply_styles() -> void:
	_backdrop.color = Color(0.02, 0.02, 0.04, 0.72)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.04, 0.07, 0.94)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(0.52, 0.56, 0.68, 0.7)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	_panel.add_theme_stylebox_override("panel", panel_style)


func _bind_rebind_buttons() -> void:
	for entry in _REBIND_ACTIONS:
		var action: StringName = entry.action
		var button := get_node("Panel/Margin/VBox/Rebinds/%sRow/BindButton" % String(action)) as Button
		if button == null:
			continue
		_rebind_buttons[action] = button
		button.pressed.connect(_begin_rebind_capture.bind(action))


func _begin_rebind_capture(action: StringName) -> void:
	_awaiting_rebind_action = action
	_rebind_status.text = "Press a key for %s. Esc cancels." % _get_rebind_label(action)
	_refresh_rebind_labels()


func _cancel_rebind_capture() -> void:
	_awaiting_rebind_action = &""
	_rebind_status.text = "Click a bind button to assign a key."
	_refresh_rebind_labels()


func _apply_rebind(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)
	SaveLoad.set_keybind(action, keycode)
	_cancel_rebind_capture()


func _refresh_rebind_labels() -> void:
	for entry in _REBIND_ACTIONS:
		var action: StringName = entry.action
		var button := _rebind_buttons.get(action) as Button
		if button == null:
			continue
		if _awaiting_rebind_action == action:
			button.text = "Press key..."
		else:
			button.text = _get_action_binding_text(action)


func _get_action_binding_text(action: StringName) -> String:
	for action_event in InputMap.action_get_events(action):
		if action_event is InputEventKey:
			var key_event := action_event as InputEventKey
			if key_event.physical_keycode != KEY_NONE:
				return OS.get_keycode_string(key_event.physical_keycode)
	return "Unbound"


func _get_rebind_label(action: StringName) -> String:
	for entry in _REBIND_ACTIONS:
		if entry.action == action:
			return String(entry.label)
	return String(action)
