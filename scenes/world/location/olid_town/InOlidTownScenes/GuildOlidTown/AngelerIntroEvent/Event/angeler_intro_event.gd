extends Node
class_name AngelerIntroEvent

@export var completed_flag: String = "ANGELER_INTRO_DONE"

@export var angeler_path: NodePath
@export var angeler_camera_path: NodePath
@export var blend_camera_path: NodePath

# Ruta única por ahora
@export var path_to_player: NodePath

var angeler: Angeler
var player: Node
var player_camera: Camera2D
var angeler_camera: Camera2D
var blend_camera: Camera2D

var is_running := false
var path_player: Path2D


func start_event() -> void:
	if is_running:
		return

	print("Angeler Intro Event iniciado")
	is_running = true

	# ----------------------------
	# Obtener referencias
	# ----------------------------

	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_error("Jugador no encontrado")
		_abort_event()
		return

	var cams = get_tree().get_nodes_in_group("player_camera")
	if cams.is_empty():
		push_error("No se encontró la cámara del jugador")
		_abort_event()
		return
	player_camera = cams[0]

	angeler = get_node_or_null(angeler_path) as Angeler
	if not angeler:
		push_error("Angeler no encontrada o tipo incorrecto")
		_abort_event()
		return

	angeler_camera = get_node_or_null(angeler_camera_path)
	if not angeler_camera:
		push_error("Cámara de Angeler no encontrada")
		_abort_event()
		return

	blend_camera = get_node_or_null(blend_camera_path)
	if not blend_camera:
		push_error("BlendCamera no encontrada")
		_abort_event()
		return

	path_player = get_node_or_null(path_to_player)
	if not path_player:
		push_error("Path AngelerToPlayer no encontrado")
		_abort_event()
		return

	# ----------------------------
	# Bloquear jugador
	# ----------------------------

	player.can_move = false

	# ----------------------------
	# Secuencia de cámara
	# ----------------------------

	SmoothCameraChanger.play_cutscene(
		player_camera,
		angeler_camera,
		blend_camera,
		1.2,
		2.5,
		Callable(self, "_on_focus_angeler"),
		Callable(self, "_on_camera_sequence_finished"),
		false
	)


func _on_focus_angeler() -> void:
	print("Cámara enfocando a Angeler")

	if angeler:
		angeler.play_hiya_voice()


func _on_camera_sequence_finished() -> void:
	print("Secuencia de cámara terminada")

	# ÚNICA ACCIÓN DEL EVENTO POR AHORA
	_start_angeler_to_player()


func _start_angeler_to_player() -> void:
	print("Iniciando ruta AngelerToPlayer")

	if not angeler:
		return

	angeler.start_scripted_move(path_player)


func _abort_event() -> void:
	if player:
		player.can_move = true

	is_running = false
