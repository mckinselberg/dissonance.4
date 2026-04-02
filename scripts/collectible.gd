@tool
class_name MusicalCollectible
extends Area3D

var symbol: String = "\u266A"
var collection_manager: CollectionManager = null

var _label: Label3D
var _editor_label: Label3D
var _editor_aura: MeshInstance3D
var _time: float = 0.0
var _collected: bool = false


func _ready() -> void:
	_label = get_node_or_null("Label3D") as Label3D
	if _label == null:
		_label = Label3D.new()
		_label.name = "Label3D"
		_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_label.modulate = Color(1.0, 0.88, 0.3)
		_label.font_size = 72
		_label.outline_size = 6
		_label.pixel_size = 0.008
		add_child(_label)
	_label.text = symbol

	var col := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col == null:
		col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var shape := SphereShape3D.new()
		shape.radius = 1.2
		col.shape = shape
		add_child(col)

	if Engine.is_editor_hint():
		_update_editor_preview()
		set_process(false)
		return

	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _collected:
		return
	_time += delta
	_label.position.y = sin(_time * 1.5) * 0.1
	_label.modulate.a = 0.8 + sin(_time * 2.2) * 0.2


func _on_body_entered(body: Node) -> void:
	if _collected or not (body is CharacterBody3D):
		return
	_collected = true
	_play_collect_sound()
	if collection_manager != null:
		collection_manager.on_collect()
	queue_free()


func _update_editor_preview() -> void:
	_editor_aura = get_node_or_null("EditorAura") as MeshInstance3D
	if _editor_aura == null:
		_editor_aura = MeshInstance3D.new()
		_editor_aura.name = "EditorAura"
		add_child(_editor_aura)

	var aura_mesh := CylinderMesh.new()
	aura_mesh.top_radius = 0.42
	aura_mesh.bottom_radius = 0.42
	aura_mesh.height = 0.04
	aura_mesh.radial_segments = 24
	_editor_aura.mesh = aura_mesh
	_editor_aura.position = Vector3(0.0, -0.55, 0.0)
	_editor_aura.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var aura_material := StandardMaterial3D.new()
	aura_material.albedo_color = Color(1.0, 0.88, 0.3, 0.32)
	aura_material.emission_enabled = true
	aura_material.emission = Color(1.0, 0.88, 0.3)
	aura_material.emission_energy_multiplier = 0.35
	aura_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	aura_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	aura_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_editor_aura.material_override = aura_material

	_editor_label = get_node_or_null("EditorLabel") as Label3D
	if _editor_label == null:
		_editor_label = Label3D.new()
		_editor_label.name = "EditorLabel"
		_editor_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_editor_label.font_size = 28
		_editor_label.outline_size = 5
		_editor_label.pixel_size = 0.005
		add_child(_editor_label)

	_editor_label.text = name
	_editor_label.position = Vector3(0.0, 0.45, 0.0)
	_editor_label.modulate = Color(0.95, 0.92, 0.65)


func _play_collect_sound() -> void:
	var player := AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 44100.0
	gen.buffer_length = 0.4
	player.stream = gen
	player.volume_db = -6.0
	get_tree().current_scene.add_child(player)
	player.play()
	var pb := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		player.queue_free()
		return

	var notes := [523.25, 659.25, 783.99]
	var durations := [0.07, 0.07, 0.12]
	for n in range(notes.size()):
		var freq: float = notes[n]
		var dur: float = durations[n]
		var count := int(dur * 44100.0)
		for i in range(count):
			var t := float(i) / 44100.0
			var sample := sin(TAU * freq * t) * exp(-t * 14.0) * 0.38
			pb.push_frame(Vector2(sample, sample))

	get_tree().create_timer(0.5).timeout.connect(player.queue_free)
