class_name MusicalCollectible
extends Area3D

var symbol: String = "♪"
var collection_manager: CollectionManager = null

var _label: Label3D
var _time: float = 0.0
var _collected: bool = false


func _ready() -> void:
	_label = Label3D.new()
	_label.text = symbol
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color(1.0, 0.88, 0.3)
	_label.font_size = 72
	_label.outline_size = 6
	_label.pixel_size = 0.008
	add_child(_label)

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.2
	col.shape = shape
	add_child(col)

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

	# Ascending C major triad arpeggio: C5 → E5 → G5
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
