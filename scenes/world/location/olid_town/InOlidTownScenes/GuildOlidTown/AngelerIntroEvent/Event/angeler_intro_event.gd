extends Node
class_name AngelerIntroEvent

@export var completed_flag: String = "ANGELER_INTRO_DONE"

@export var angeler_path: NodePath
@export var angeler_camera_path: NodePath
@export var blend_camera_path: NodePath

# Ruta única por ahora
@export var path_to_player: NodePath
@export var path_to_desk: NodePath
@export var desk_trigger_path: NodePath
@export var path_to_exit: NodePath

var angeler: Angeler
var player: Node
var player_camera: Camera2D
var angeler_camera: Camera2D
var blend_camera: Camera2D

var is_running := false
var path_player: Path2D
var path_desk: Path2D
var path_exit: Path2D

var desk_trigger: Area2D
var waiting_player_at_desk := false
var desk_dialog_started := false

@export var receptionist_path: NodePath
var receptionist: Node

var angeler_dialog_lines: Array[String] = [
	"Auren! It’s good to see you. I heard you’re an adventurer now, just like me.",
	"My name is Angeler. I’m a Rank C adventurer, and I specialize in close combat with a sword.",
	"I’m really bad at magic… so I always stick to swords!",
	"I’m a huge admirer of your parents! They’re both magnificent adventurers—you’ll have to introduce me to them someday.",
	"Oh, right! I’ll teach you all the basics you need to know… where should I start?",
	"First, I’ll show you how the Adventurers’ Guild works. Please, follow me.",
]

var angeler_desk_dialog_lines: Array[String] = [
	"This is the guild board. The receptionist will show you the quests compatible with your adventurer rank.",
	"To see which quests you can accept, just talk to her and go to the [Select Quest] section.",
	"There you’ll see all the available quests that match your rank!",
	"To view your active quests and their progress, press the [G] key. You can also check your stats menu there.",
	"Once you complete a quest, you must go to the nearest guild and turn it in under the [Turn In Quest] section.",
	"The Kingdom built guilds in most cities across the continent, so they’re easy to find. They all look the same from the outside.",
	"Hmm… oh, right! You can’t turn in quests that aren’t completed. If you try to turn in an unfinished quest, you could be fined.",
	"Try talking to the receptionist to learn more about how the guild works."
]

var angeler_phase_3_dialog_lines: Array[String] = [
	"Alright, now you know how adventurers’ guilds work. Each quest will grant you rewards and experience to improve your skills.",
	"From here on, you’ll be able to accept quests on your own to grow stronger.",
	"You’re free to go wherever you want, whenever you want—but be careful. If you’re not strong enough, some monster could easily kill you.",
	"And… well, I wouldn’t like to lose someone like you so quickly. Please, be careful!",
	"Before I go, let me explain a few more details. All over the world there are chests that help adventurers; they usually contain money and potions.",
	"To open these chests, we usually use brute force, since we don’t have keys. Just hit them a few times!",
	"Coins are used for trading in cities or with traveling merchants. You can obtain bronze coins, silver tablets, and gold medallions.",
	"Gold medallions are very rare. I believe the continent’s government has almost all of them.",
	"Let’s see, let’s see… what else might I be forgetting? Oh, right!",
	"Monsters… you see… due to my rank, I’ve never had the chance to face magnificent monsters like a dragon or a hydra.",
	"They’re extremely dangerous, and only the best among us can face them. Even then, surviving such encounters is very difficult.",
	"However, for low-rank adventurers like you and me, monsters are easier to hunt and harvest for resources.",
	"That’s right! Every monster leaves something behind when it dies. Often it can be sold for money, and other times it’s used to craft weapons and tools.",
	"Sorry, I talked too much! This world just has so many things to explain…",
	"The best part of being an adventurer is that you can discover all of it on your own. I don’t want to take that joy away from you.",
	"I just wanted to explain a little… really, sorry! I’ll let you continue.",
	"We’ll be seeing each other often, Auren. Good luck!"
]

const DIALOG_BOX_SCENE := preload("res://UIs/DialogBox/dialog_box.tscn")

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

	# Ruta hacia el jugador
	path_player = get_node_or_null(path_to_player)
	if not path_player:
		push_error("Path AngelerToPlayer no encontrado")
		_abort_event()
		return

	# Ruta hacia el escritorio de recepcion
	path_desk = get_node_or_null(path_to_desk)
	if not path_desk:
		push_error("Path AngelerToDesk no encontrado")
		_abort_event()
		return
	
	# Area para activar fase del desk
	desk_trigger = get_node_or_null(desk_trigger_path)
	if not desk_trigger:
		push_error("DeskTriggerArea no encontrada")
		_abort_event()
		return

	desk_trigger.body_entered.connect(_on_desk_trigger_body_entered)

	receptionist = get_node_or_null(receptionist_path)
	if not receptionist:
		push_error("Recepcionista no encontrada")
		_abort_event()
		return
	
	path_exit = get_node_or_null(path_to_exit)
	if not path_exit:
		push_error("Path AngelerToExit no encontrado")
		_abort_event()
		return
	
	# ----------------------------
	# Bloquear jugador
	# ----------------------------

	player.can_move = false
	player.can_dash = false

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

	# Esperar a que termine la ruta
	await _wait_for_angeler_path_end()

	# Iniciar presentación
	_start_angeler_dialog()

func _start_angeler_to_desk() -> void:
	print("Iniciando ruta AngelerToDesk")

	if not angeler or not path_desk:
		return

	angeler.start_scripted_move(path_desk)

	await _wait_for_angeler_path_end()

	_on_angeler_reached_desk()


func _wait_for_angeler_path_end() -> void:
	while angeler and not angeler.scripted_move_finished():
		await get_tree().process_frame

func _on_angeler_reached_desk() -> void:
	print("Angeler llegó al escritorio")

	waiting_player_at_desk = true

	if player:
		player.can_move = true
		player.can_dash = true

	# Escuchar cuando el jugador termine con la recepcionista
	if receptionist and not receptionist.interaction_finished.is_connected(_on_receptionist_interaction_finished):
		receptionist.interaction_finished.connect(
			_on_receptionist_interaction_finished,
			CONNECT_ONE_SHOT
		)

	is_running = true


func _on_desk_trigger_body_entered(body: Node) -> void:
	if not waiting_player_at_desk:
		return
	if desk_dialog_started:
		return
	if body != player:
		return

	print("Jugador llegó junto a Angeler en el escritorio")

	desk_dialog_started = true
	desk_trigger.monitoring = false

	_start_angeler_desk_dialog()

func _start_angeler_dialog() -> void:
	print("Iniciando diálogo de Angeler")

	var world_manager := get_tree().root.get_node("WorldManager")
	var dialog_box := world_manager.get_node("HUD/DialogBox") as DialogBox

	if not dialog_box:
		push_error("DialogBox no encontrado en HUD")
		return

	dialog_box.show_dialog(
		angeler_dialog_lines,
		angeler.portrait
	)

	dialog_box.dialog_finished.connect(
		Callable(self, "_on_angeler_dialog_finished"),
		CONNECT_ONE_SHOT
	)

func _on_angeler_dialog_finished() -> void:
	print("Diálogo de Angeler terminado")

	_start_angeler_to_desk()

func _start_angeler_desk_dialog() -> void:
	print("Iniciando diálogo del escritorio")

	var world_manager := get_tree().root.get_node("WorldManager")
	var dialog_box := world_manager.get_node("HUD/DialogBox") as DialogBox

	if not dialog_box:
		push_error("DialogBox no encontrado en HUD")
		return

	dialog_box.show_dialog(
		angeler_desk_dialog_lines,
		angeler.portrait
	)

	dialog_box.dialog_finished.connect(
		Callable(self, "_on_desk_dialog_finished"),
		CONNECT_ONE_SHOT
	)
	
func _on_desk_dialog_finished() -> void:
	print("Diálogo del escritorio terminado")

	# Aquí puedes marcar flags o activar sistemas
	# GameState.set_flag(completed_flag)

	waiting_player_at_desk = false
	is_running = false


func _abort_event() -> void:
	if player:
		player.can_move = true

	is_running = false


func _on_receptionist_interaction_finished() -> void:
	print("Interacción con recepcionista finalizada")

	_lock_receptionist()
	_start_angeler_phase_3_dialog()

func _lock_receptionist() -> void:
	if receptionist:
		receptionist.set_process(false)
		receptionist.set_physics_process(false)

func _unlock_receptionist() -> void:
	if receptionist:
		receptionist.set_process(true)
		receptionist.set_physics_process(true)

func _start_angeler_phase_3_dialog() -> void:
	print("Iniciando diálogo final de Angeler")

	var world_manager := get_tree().root.get_node("WorldManager")
	var dialog_box := world_manager.get_node("HUD/DialogBox") as DialogBox

	if not dialog_box:
		push_error("DialogBox no encontrado")
		return

	dialog_box.show_dialog(
		angeler_phase_3_dialog_lines,
		angeler.portrait
	)

	dialog_box.dialog_finished.connect(
		Callable(self, "_on_angeler_phase_3_finished"),
		CONNECT_ONE_SHOT
	)


func _start_angeler_exit() -> void:
	if not angeler or not path_exit:
		return

	print("Iniciando salida de Angeler")

	angeler.start_scripted_move(path_exit)

	await _wait_for_angeler_path_end()

	if angeler:
		angeler.queue_free()
		angeler = null

func _on_angeler_phase_3_finished() -> void:
	print("Evento AngelerIntro finalizado")

	_unlock_receptionist()

	GameState.set_flag(completed_flag)

	await _start_angeler_exit()

	is_running = false
