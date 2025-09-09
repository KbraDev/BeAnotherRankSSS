extends CharacterBody2D
## Script de la recepcionista del gremio.
## Se encarga de manejar la interacción con el jugador, abrir diálogos,
## mostrar menús de misiones y desactivar el ataque del jugador mientras interactúa.

# --- Referencias a nodos de la escena ---
@onready var animation = $AnimatedSprite2D
@onready var interacUIAnimation = $InteractUI
@onready var dialog_box = get_tree().get_root().get_node("WorldManager/HUD/DialogBox")
@onready var menu_ui = get_tree().get_root().get_node("WorldManager/HUD/ReceptionMenu")
@onready var mission_menu = get_tree().get_root().get_node("WorldManager/HUD/MissionSelectedMenu")
@onready var mission_delivery_menu = get_tree().get_root().get_node("WorldManager/HUD/MissionDeliveryMenu")

# --- Variables de control ---
var player_in_range = false         # Marca si el jugador está dentro del área de interacción
var player_rank = "E"               # Rango del jugador (usado para filtrar misiones) 

# --- Ciclo de vida ---
func _ready():
	# Configuración inicial
	animation.play("front")                   # Animación base de la recepcionista
	interacUIAnimation.visible = false        # UI de interacción oculta al inicio
	
	# Conectar señales del diálogo y menú
	dialog_box.dialog_finished.connect(_on_dialog_finished)
	menu_ui.option_selected.connect(_on_menu_option_selected)

# --- Señales ---
func _on_dialog_finished():
	# Cuando el diálogo termina, abrir el menú de opciones si aún no está visible
	if not menu_ui.visible:
		menu_ui.open()

func _on_menu_option_selected(option: String):
	# Recibe la opción elegida en el menú de recepción
	match option:
		"seleccionar":
			# Obtener misiones disponibles según rango
			var missions = MissionDataBase.get_missions_for_rank(player_rank)
			
			# Filtrar las misiones activas para que no se repitan
			var active = MissionTracker.get_active_mission()
			var active_ids = active.map(func(s): return s.mission.id)
			var filtered = missions.filter(func(m): return not active_ids.has(m.id))
			
			# Abrir el menú de selección de misión con las misiones filtradas
			mission_menu.open(filtered)

		"entregar":
			# Abrir menú de entrega con misiones activas
			var active = MissionTracker.get_active_mission()
			mission_delivery_menu.open(active)

		"salir":
			# Cerrar todo y permitir ataque del jugador otra vez
			menu_ui.close()
			dialog_box.hide_dialog()
			
			var player = get_tree().get_first_node_in_group("player")
			if player:
				player.can_attack = true

# --- Áreas de interacción ---
func _on_interact_area_body_entered(body: Node2D) -> void:
	# Mostrar icono de interacción al entrar el jugador en el área
	if body.is_in_group("player"):
		interacUIAnimation.visible = true
		player_in_range = true

func _on_interact_area_body_exited(body: Node2D) -> void:
	# Ocultar icono y cerrar diálogo si el jugador sale del área
	if body.is_in_group("player"):
		interacUIAnimation.visible = false
		player_in_range = false
		if dialog_box.is_showing:
			dialog_box.hide_dialog()

# --- Entrada de jugador ---
func _process(delta: float) -> void:
	# Si el jugador está en rango y presiona "interact"
	if player_in_range and Input.is_action_just_pressed("interact"):
		# Abrir diálogo si no hay uno activo
		if not dialog_box.is_showing:
			# Desactivar el ataque del jugador mientras interactúa
			var player = get_tree().get_first_node_in_group("player")
			if player:
				player.can_attack = false
			
			dialog_box.show_dialog([
				"¡Bienvenido!",
				"¿Cómo podemos ayudarle hoy?",
				"Tenemos nuevas misiones disponibles."
			])

# --- Utilidad: Compatibilidad de rangos ---
func is_mission_compatible(player_rank: String, mission_rank: String) -> bool:
	# Diccionario que define qué rangos pueden acceder a qué misiones
	var rank_compatibility = {
		"E": ["E", "D"],
		"D": ["E", "D", "C"],
		"C": ["C", "B"],
		"B": ["B", "A"],
		"A": ["A", "A+"],
		"A+": ["A+"],
		"S": ["A", "A+", "S"],
		"SS": ["A+", "S", "SS"],
		"SSS": ["SSS"]
	}
	return mission_rank in rank_compatibility.get(player_rank, [])
