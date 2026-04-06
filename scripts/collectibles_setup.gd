extends Node

const _SYMBOLS := ["♩", "♪", "♫", "♬", "♭", "♮", "♯", "♫", "♪", "♩"]

const _POSITIONS := [
	Vector3(2.0,   1.5,   -8.0),   # 1. Near spawn — easy intro
	Vector3(-7.5,  1.8,  -22.5),   # 2. On left utility box
	Vector3(6.2,   1.6,  -35.0),   # 3. Mid corridor right wall
	Vector3(-8.5,  1.8,  -46.0),   # 4. Tuning nook entrance
	Vector3(-12.2, 1.5,  -62.0),   # 5. Inside left alcove
	Vector3(5.0,   1.8,  -55.0),   # 6. Mid corridor left stretch
	Vector3(12.2,  1.5,  -85.0),   # 7. Inside right alcove
	Vector3(-6.0,  1.6,  -75.0),   # 8. Far left wall
	Vector3(7.5,   1.8,  -95.0),   # 9. Near right dumpster
	Vector3(0.0,   2.0, -112.0),   # 10. Far end of boulevard
]


func setup(root: Node3D) -> CollectionManager:
	var manager := CollectionManager.new()
	manager.name = "CollectionManager"
	root.add_child(manager)
	manager.register_total(_POSITIONS.size())

	# Restore already-collected count so HUD starts accurate
	for id in SaveLoad.collected_ids:
		if id >= 0 and id < _POSITIONS.size():
			manager.on_collect()

	for i in range(_POSITIONS.size()):
		var c := MusicalCollectible.new()
		c.symbol = _SYMBOLS[i]
		c.collection_manager = manager
		c.collectible_index = i
		c.position = _POSITIONS[i]
		root.add_child(c)

	queue_free()
	return manager
