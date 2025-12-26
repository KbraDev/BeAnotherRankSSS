extends Node
class_name AngelerIntroEvent

@export var completed_flag: String = "ANGELER_INTRO_DONE"

var player: Node = null
var is_running: bool = false


func start_event() -> void:
	if is_running:
		return

	print("Angeler Intro Event iniciado")
	is_running = true

	player = get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = false
		print("jugador bloqueado")

	# aquí luego irá:
	# - mirar al jugador
	# - diálogo
	# - cámara
	# por ahora lo cerramos de inmediato
	_complete_event()


func _complete_event() -> void:
	if player:
		player.can_move = true

	GameState.set_flag(completed_flag)
	is_running = false

	print("Angeler Intro Event completado")
