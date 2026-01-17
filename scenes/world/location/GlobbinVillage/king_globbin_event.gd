extends Node
class_name KingGlobbinEventController

@export var king_path: NodePath
@export var room_blocker_path: NodePath
@export var village_music_path: NodePath
@export var boss_music_path: NodePath

@export var focus_duration := 3.0
@export var blend_time := 1.5
@export var boss_ui_fade := 0.3

var king: KingGlobbin
var room_blocker: Node
var village_music: AudioStreamPlayer2D
var boss_music: AudioStreamPlayer2D
var player_camera: Camera2D

var started := false

func _ready() -> void:
	if GameState.has_flag("KingGlobbinEvent"):
		_cleanup_completed_event()
		return

	king = get_node_or_null(king_path)
	room_blocker = get_node_or_null(room_blocker_path)
	village_music = get_node_or_null(village_music_path)
	boss_music = get_node_or_null(boss_music_path)

	if king and king.has_signal("boss_defeated"):
		king.boss_defeated.connect(_on_boss_defeated)

	_set_room_blocker(false)

func start_event() -> void:
	if started:
		return
	started = true

	_set_room_blocker(true)
	_fade_out_music(village_music, 1.5)

	player_camera = _get_player_camera()
	if not player_camera:
		push_error("EventController: No player camera")
		return

	# Boss UI oculta durante intro
	if king and king.boss_ui:
		king.boss_ui.visible = false
		king.boss_ui.modulate.a = 0.0

	SmoothCameraChanger.play_cutscene(
		player_camera,
		king.king_camera,
		king.blend_camera,
		blend_time,
		focus_duration,
		Callable(self, "_on_focus_king"),
		Callable(self, "_on_intro_finished"),
		true
	)

func _on_focus_king() -> void:
	if king and king.war_scream:
		king.war_scream.play()

func _on_intro_finished() -> void:
	if king:
		king.activate(true)

	# Mostrar UI del boss
	if king and king.boss_ui:
		king.boss_ui.visible = true
		king.boss_ui.modulate.a = 0.0
		var t := create_tween()
		t.tween_property(king.boss_ui, "modulate:a", 1.0, boss_ui_fade)

	_fade_in_music(boss_music, 0.8)

func _on_boss_defeated() -> void:
	GameState.set_flag("KingGlobbinEvent")

	_fade_out_music(boss_music, 1.0)
	_fade_in_music(village_music, 1.2)

	if room_blocker:
		room_blocker.queue_free()

	queue_free()

func _cleanup_completed_event() -> void:
	if king:
		king.queue_free()
	queue_free()

# ---------------------------------------------------

func _set_room_blocker(active: bool) -> void:
	if not room_blocker:
		return
	for c in room_blocker.get_children():
		if c is CollisionShape2D:
			c.set_deferred("disabled", not active)

func _get_player_camera() -> Camera2D:
	var cams := get_tree().get_nodes_in_group("player_camera")
	return cams[0] if not cams.is_empty() else null

func _fade_out_music(player: AudioStreamPlayer2D, time := 1.0) -> void:
	if not player or not player.playing:
		return
	var t := create_tween()
	t.tween_property(player, "volume_db", -80.0, time)
	t.tween_callback(Callable(player, "stop"))

func _fade_in_music(player: AudioStreamPlayer2D, time := 1.0, target := 0.0) -> void:
	if not player:
		return
	player.volume_db = -80.0
	player.play()
	var t := create_tween()
	t.tween_property(player, "volume_db", target, time)
