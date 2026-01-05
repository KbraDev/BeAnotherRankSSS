extends Area2D

@export var king_path: NodePath
@export var king_camera_path: NodePath
@export var blend_camera_path: NodePath
@export var focus_duration: float = 3.0
@export var blend_time: float = 1.5
@export var boss_fade_duration: float = 0.3
@export var room_blocker_path: NodePath
@export var village_music_path: NodePath
@export var boss_music_path: NodePath


var king
var king_camera
var player_camera
var blend_camera
var room_blocker: StaticBody2D

var triggered := false

var village_music: AudioStreamPlayer2D
var boss_music: AudioStreamPlayer2D


func _ready():
	monitoring = false
	await get_tree().process_frame
	monitoring = true
	
	# Si el evento ya fue completado → eliminar todo
	if GameState.has_flag("KingGlobbinEvent"):
		_cleanup_completed_event()
		return

	connect("body_entered", Callable(self, "_on_body_entered"))

	village_music = get_node_or_null(village_music_path)
	boss_music = get_node_or_null(boss_music_path)

	king = get_node_or_null(king_path)
	king_camera = get_node_or_null(king_camera_path)
	blend_camera = get_node_or_null(blend_camera_path)

	if room_blocker_path != NodePath():
		room_blocker = get_node_or_null(room_blocker_path)

	if room_blocker:
		_set_room_blocker(false)
		
	# conectando muerte del boss
	if king and king.has_signal("boss_defeated"):
		king.connect("boss_defeated", Callable(self, "_on_boss_defeated"))
		

func _on_body_entered(body):
	if triggered or not body.is_in_group("player"):
		return
	
	# 🎵 Fade out música de la aldea
	fade_out_music(village_music, 1.5)
	
	# Obtener la cámara ACTUAL del jugador
	var cams = get_tree().get_nodes_in_group("player_camera")
	if cams.is_empty():
		push_error("No player_camera found for boss cutscene")
		return

	player_camera = cams[0]

	# Seguridad extra
	if not is_instance_valid(player_camera):
		push_error("Player camera reference is invalid")
		return

	triggered = true
	monitoring = false
	$CollisionShape2D.disabled = true

	# 🔒 BLOQUEAR LA SALA
	_set_room_blocker(true)
	
	# Activamos boss pero permanece congelado
	king.activate(false)

	# Ocultar UI durante intro
	if king.boss_ui:
		king.boss_ui.visible = false
		king.boss_ui.modulate.a = 0

	SmoothCameraChanger.play_cutscene(
		player_camera,
		king_camera,
		blend_camera,
		blend_time,
		focus_duration,
		Callable(self, "_on_focus_king"),
		Callable(self, "_on_camera_sequence_finished"),
		true # YES shake
	)

func _on_camera_sequence_finished():
	if king:
		king.can_move = true

	# Fade-in UI boss
	if king.boss_ui:
		var ui = king.boss_ui
		ui.visible = true
		ui.modulate.a = 0

		var t = create_tween()
		t.tween_property(ui, "modulate:a", 1.0, boss_fade_duration)
	
	# 🎵 Iniciar música del boss
	fade_in_music(boss_music, 0.8)

	# Start AI
	if king.has_node("AI"):
		king.get_node("AI").set_active(true)
	




func _on_focus_king():
	if king and king.war_scream:
		king.war_scream.play()
		

func _set_room_blocker(active: bool) -> void:
	if not room_blocker:
		return

	for child in room_blocker.get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", not active)
			
func _cleanup_completed_event() -> void:
	print("[EVENT] KingGlobbinEvent already completed → cleaning up")

	# Eliminar boss
	if king and is_instance_valid(king):
		king.queue_free()

	# Eliminar trigger
	queue_free()

func _on_boss_defeated() -> void:
	print("[EVENT] Boss defeated → Unlocking room")

	# 🔓 Desbloquear la sala
	if room_blocker:
		room_blocker.queue_free()

	# Limpieza del trigger del evento
	queue_free()
	
	# 🎵 Transición de música al completar evento
	fade_out_music(boss_music, 1.0)
	fade_in_music(village_music, 1.2)

func fade_out_music(player: AudioStreamPlayer2D, duration: float = 1.0) -> void:
	if not player or not player.playing:
		return

	var t = create_tween()
	t.tween_property(player, "volume_db", -80.0, duration)
	t.tween_callback(Callable(player, "stop"))


func fade_in_music(player: AudioStreamPlayer2D, duration: float = 1.0, target_db: float = 0.0) -> void:
	if not player:
		return

	player.volume_db = -80.0
	player.play()

	var t = create_tween()
	t.tween_property(player, "volume_db", target_db, duration)
