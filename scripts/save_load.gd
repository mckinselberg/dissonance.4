## SaveLoad — autoloaded singleton
## Persists game progress to user://save.json between sessions.
##
## Saved fields:
##   collected_ids   Array[int]   indices of collected musical items
##   has_regulator   bool
##   jammer_charges  int
##   drone_disabled  bool
extends Node

const _SAVE_PATH := "user://save.json"

# Loaded at startup; scripts read from here before the scene populates.
var collected_ids: Array[int] = []
var has_regulator: bool = false
var jammer_charges: int = 0
var drone_disabled: bool = false
var mouse_sensitivity: float = 0.0025
var master_volume_linear: float = 1.0
var fullscreen: bool = false
var keybinds: Dictionary = {}


func _ready() -> void:
	load_game()


## Call after any state change that should persist.
func save_game() -> void:
	var data := {
		"collected_ids": collected_ids,
		"has_regulator": has_regulator,
		"jammer_charges": jammer_charges,
		"drone_disabled": drone_disabled,
		"mouse_sensitivity": mouse_sensitivity,
		"master_volume_linear": master_volume_linear,
		"fullscreen": fullscreen,
		"keybinds": keybinds,
	}
	var file := FileAccess.open(_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveLoad: could not open %s for writing (err %d)" % [_SAVE_PATH, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(data))
	file.close()


func load_game() -> void:
	if not FileAccess.file_exists(_SAVE_PATH):
		return
	var file := FileAccess.open(_SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("SaveLoad: could not open %s for reading (err %d)" % [_SAVE_PATH, FileAccess.get_open_error()])
		return
	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_warning("SaveLoad: corrupt save file, resetting.")
		_reset()
		return

	var d: Dictionary = parsed as Dictionary
	collected_ids.clear()
	if d.has("collected_ids") and d["collected_ids"] is Array:
		for id in d["collected_ids"]:
			collected_ids.append(int(id))
	has_regulator  = bool(d.get("has_regulator",  false))
	jammer_charges = int(d.get("jammer_charges",  0))
	drone_disabled = bool(d.get("drone_disabled",  false))
	mouse_sensitivity = float(d.get("mouse_sensitivity", 0.0025))
	master_volume_linear = float(d.get("master_volume_linear", 1.0))
	fullscreen = bool(d.get("fullscreen", false))
	keybinds.clear()
	if d.has("keybinds") and d["keybinds"] is Dictionary:
		var kb: Dictionary = d["keybinds"] as Dictionary
		for k in kb.keys():
			keybinds[StringName(k)] = int(kb[k])


func delete_save() -> void:
	_reset()
	if FileAccess.file_exists(_SAVE_PATH):
		DirAccess.remove_absolute(_SAVE_PATH)


func mark_collected(index: int) -> void:
	if not collected_ids.has(index):
		collected_ids.append(index)
		save_game()


func is_collected(index: int) -> bool:
	return collected_ids.has(index)


func set_keybind(action: StringName, keycode: Key) -> void:
	keybinds[action] = int(keycode)
	save_game()


func reset_runtime_settings() -> void:
	mouse_sensitivity = 0.0025
	master_volume_linear = 1.0
	fullscreen = false
	keybinds.clear()
	save_game()


func _reset() -> void:
	collected_ids.clear()
	has_regulator  = false
	jammer_charges = 0
	drone_disabled = false
	mouse_sensitivity = 0.0025
	master_volume_linear = 1.0
	fullscreen = false
	keybinds.clear()
