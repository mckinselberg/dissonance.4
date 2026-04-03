extends CanvasLayer

@export var pause_action: StringName = &"ui_cancel"

var _player: Node3D
var _is_open: bool = false

@onready var _backdrop: ColorRect = $Backdrop
@onready var _panel: PanelContainer = $Panel
@onready var _resume_button: Button = $Panel/Margin/VBox/Buttons/ResumeButton
@onready var _restart_button: Button = $Panel/Margin/VBox/Buttons/RestartButton
@onready var _mouse_slider: HSlider = $Panel/Margin/VBox/Settings/MouseRow/MouseSlider
@onready var _mouse_value: Label = $Panel/Margin/VBox/Settings/MouseRow/MouseValue
@onready var _volume_slider: HSlider = $Panel/Margin/VBox/Settings/VolumeRow/VolumeSlider
@onready var _volume_value: Label = $Panel/Margin/VBox/Settings/VolumeRow/VolumeValue
@onready var _fullscreen_toggle: CheckBox = $Panel/Margin/VBox/Settings/FullscreenToggle


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_apply_styles()
	_resume_button.pressed.connect(_close_menu)
	_restart_button.pressed.connect(_restart_scene)
	_mouse_slider.value_changed.connect(_on_mouse_sensitivity_changed)
	_volume_slider.value_changed.connect(_on_master_volume_changed)
	_fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	_sync_from_runtime()


func setup(player: Node3D) -> void:
	_player = player
	_sync_from_runtime()


func _unhandled_input(event: InputEvent) -> void:
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
	_is_open = false
	hide()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _restart_scene() -> void:
	get_tree().paused = false
	_is_open = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().reload_current_scene()


func _sync_from_runtime() -> void:
	if _player != null and is_instance_valid(_player):
		var mouse_sensitivity := float(_player.get("mouse_sensitivity"))
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


func _on_mouse_sensitivity_changed(value: float) -> void:
	_mouse_value.text = "%.4f" % value
	if _player != null and is_instance_valid(_player):
		_player.set("mouse_sensitivity", value)


func _on_master_volume_changed(value: float) -> void:
	_volume_value.text = "%d%%" % int(round(value * 100.0))
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(max(value, 0.001)))


func _on_fullscreen_toggled(button_pressed: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if button_pressed else DisplayServer.WINDOW_MODE_WINDOWED
	)


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
