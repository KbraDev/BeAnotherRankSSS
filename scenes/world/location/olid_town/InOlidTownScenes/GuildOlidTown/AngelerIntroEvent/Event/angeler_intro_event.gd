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
	"¡Auren! Qué bueno verte. Escuché que ya eres un aventurero, igual que yo.",
	"Me llamo Angeler, soy una aventurera de rango C y me especializo en el combate cuerpo a cuerpo con espada.",
	"La magia no se me da nada bien… ¡así que siempre opto por las espadas!",
	"¡Soy una gran admiradora de tus padres! Ambos son magníficos aventureros; tienes que presentármelos algún día.",
	"¡Cierto! yo te enseñaré todo lo basico que necesitas saber... ¿por donde empiezo?",
	"Primero te enseñaré cómo funciona el gremio de aventureros. Sígueme, por favor.",
]

var angeler_desk_dialog_lines: Array[String] = [
	"Este es el tablón del gremio. La recepcionista se encargará de mostrarte las misiones compatibles con tu rango de aventurero.",
	"Para saber qué misiones puedes aceptar, basta con hablar con ella e ir al apartado de [Seleccionar misión].",
	"¡Ahí verás todas las misiones disponibles y compatibles contigo!",
	"Para ver tus misiones activas y su progreso, presiona la tecla [G]. También podrás revisar tu menú de estadísticas.",
	"Al terminar una misión, deberás acudir al gremio más cercano para entregarla en el apartado de [Entregar misión].",
	"El Reino se encargó de construir gremios en la mayoría de las ciudades del continente, así que será fácil encontrarlos. Todos lucen igual por fuera.",
	"Hmm… ¡ah, cierto! No podrás entregar misiones que no estén completas. Si intentas entregar una misión sin terminar, podrían multarte.",
	"Prueba hablar con la recepcionista para que conozcas mejor cómo funciona el gremio."
]

var angeler_phase_3_dialog_lines: Array[String] = [
	"Muy bien, ahora ya sabes cómo funcionan los gremios de aventureros. Cada misión te dará recompensas y experiencia para mejorar tus habilidades.",
	"A partir de aquí, podrás aceptar misiones por tu cuenta para hacerte más fuerte.",
	"Eres libre de ir a donde quieras, cuando quieras, pero ten cuidado: si no eres lo suficientemente fuerte, algún monstruo podría eliminarte fácilmente.",
	"Y… bueno, no me gustaría perder a alguien como tú tan rápido. ¡Por favor, ten cuidado!",
	"Antes de despedirme, déjame explicarte algunos detalles más. Por todo el mundo hay cofres que ayudan a los aventureros; suelen contener dinero y pociones.",
	"Para abrir estos cofres solemos usar la fuerza bruta, ya que no contamos con llaves. ¡Basta con golpearlos unas cuantas veces!",
	"Las monedas te servirán para comerciar en ciudades o con vendedores ambulantes. Podrás obtener monedas de bronce, tablillas de plata y medallones de oro.",
	"Los medallones de oro son muy raros. Yo creo que el gobierno del continente los tiene casi todos.",
	"A ver, a ver… ¿qué más puedo estar olvidando? ¡Ah, sí!",
	"Los monstruos… verás… debido a mi rango, nunca he tenido la oportunidad de enfrentar monstruos magníficos como un dragón o una hidra.",
	"Son extremadamente peligrosos, y solo los mejores entre nosotros pueden enfrentarlos. Aun así, salir con vida de algo así es muy difícil.",
	"Sin embargo, para aventureros de rango bajo como tú y yo, los monstruos son más fáciles de cazar y obtener sus recursos.",
	"¡Así es! Cada monstruo deja algo al morir. Muchas veces sirve para venderlo por dinero, y otras para fabricar armas y herramientas.",
	"¡Perdón, ya hablé demasiado! Es que este mundo tiene muchísimas cosas que explicar…",
	"Lo mejor de ser aventurero es que puedes descubrirlas todas por tu cuenta. No quiero quitarte el placer de aprender por ti mismo.",
	"Solo quería explicarte un poco… de verdad, ¡perdón! Te dejaré continuar.",
	"Nos estaremos viendo seguido, Auren. ¡Mucha suerte!"
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
