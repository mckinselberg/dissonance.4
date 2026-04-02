@tool
extends Node3D

const _SYMBOLS := ["\u2669", "\u266A", "\u266B", "\u266C", "\u266D", "\u266E", "\u266F", "\u266B", "\u266A", "\u2669"]

const _POSITIONS := [
	Vector3(2.0, 1.5, -8.0),
	Vector3(-7.5, 1.8, -22.5),
	Vector3(6.2, 1.6, -35.0),
	Vector3(-8.5, 1.8, -46.0),
	Vector3(-12.2, 1.5, -62.0),
	Vector3(5.0, 1.8, -55.0),
	Vector3(12.2, 1.5, -85.0),
	Vector3(-6.0, 1.6, -75.0),
	Vector3(7.5, 1.8, -95.0),
	Vector3(0.0, 2.0, -112.0),
]


func _ready() -> void:
	if get_child_count() > 0:
		return
	_build()


func _build() -> void:
	var manager := CollectionManager.new()
	manager.name = "CollectionManager"
	manager.register_total(_POSITIONS.size())
	add_child(manager)

	for i in range(_POSITIONS.size()):
		var collectible := MusicalCollectible.new()
		collectible.name = "Collectible_%02d" % (i + 1)
		collectible.symbol = _SYMBOLS[i]
		collectible.collection_manager = manager
		collectible.position = _POSITIONS[i]
		add_child(collectible)
