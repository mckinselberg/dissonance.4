class_name CollectionManager
extends Node

signal item_collected(count: int, total: int)
signal all_collected

var _count: int = 0
var _total: int = 0


func register_total(n: int) -> void:
	_total = n


func on_collect() -> void:
	_count = min(_count + 1, _total)
	item_collected.emit(_count, _total)
	if _count >= _total:
		all_collected.emit()


func get_count() -> int:
	return _count


func get_total() -> int:
	return _total
