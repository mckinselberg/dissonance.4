class_name ZoneArea3D
extends Area3D

@export var sensory_exposure: float = 0.0
@export var social_exposure: float = 0.0
@export var rest_input: float = 0.0
@export var musical_regulation: float = 0.0
@export var solitude_regulation: float = 0.0
@export var calming_input: float = 0.0
@export var zone_label: String = "Zone"
@export var zone_priority: int = 0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D and body.has_method("register_zone"):
		body.register_zone(self)


func _on_body_exited(body: Node) -> void:
	if body is CharacterBody3D and body.has_method("unregister_zone"):
		body.unregister_zone(self)
