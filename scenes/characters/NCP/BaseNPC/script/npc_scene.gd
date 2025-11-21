extends CharacterBody2D
## ===============================================================
## NPC BASE UNIVERSAL — COMPATIBLE CON GODOT 4.3
## ---------------------------------------------------------------
## Funcionalidades:
##  - Movimiento automático usando PathFollow2D
##  - Animaciones generadas automáticamente desde un spritesheet
##  - Detección de jugador mediante un área
##  - Mostrar un icono de interacción (“Pulsa E”)
##  - Iniciar un diálogo usando un sistema universal (DialogBox)
## 
## Requisitos:
##  - El DialogBox debe estar en un nodo con el grupo "dialog_box"
##  - El NPC debe tener un área que llame a:
##       _on_break_area_body_entered()
##       _on_break_area_body_exited()
## ===============================================================



# ================================================================
# ----------------------- VARIABLES EXPORTADAS --------------------
# ================================================================

@export var new_spritesheet: Texture2D
## Hoja de sprites del NPC.
## Cada fila es una animación en el orden de ANIM_NAMES.

@export var path_follow: PathFollow2D
## Nodo PathFollow2D que controla la trayectoria del NPC.

@export var dialog_library: Array[String] = []
## Lista de diálogos que este NPC dirá, en orden.



# ================================================================
# ----------------------- REFERENCIAS A NODOS ---------------------
# ================================================================

@onready var anim := $AnimatedSprite2D
## Sprite animado del NPC.

@onready var interactUI := $InteractUI
## Icono visual para “Pulsa E para interactuar”.

@onready var dialog_box := get_tree().get_first_node_in_group("dialog_box")
## Sistema universal de diálogos.



# ================================================================
# -------------------------- ESTADO INTERNO -----------------------
# ================================================================

var previous_position: Vector2
## Guarda la posición del frame anterior para calcular dirección.

var speed: float = 25.0
## Velocidad de movimiento por el path.

var player_in_area: bool = false
## TRUE cuando el jugador está en el área de interacción.

var last_direction: String = "front"
## Última dirección animada.

var can_move: bool = true
## Si FALSE, el NPC no avanza por la ruta.



# ================================================================
# ---------------------------- CONSTANTES -------------------------
# ================================================================

const FRAME_SIZE := Vector2(48, 96)
## Tamaño de cada frame en la hoja del spritesheet.

## Orden exacto de animaciones esperadas por filas:
const ANIM_NAMES := [
	"idle_front",
	"idle_left_side",
	"idle_right_side",
	"idle_back",
	"walk_front",
	"walk_left_side",
	"walk_right_side",
	"walk_back",
]



# ================================================================
# ---------------------------- READY ------------------------------
# ================================================================

func _ready():
	await  get_tree().process_frame
	interactUI.visible = false
	previous_position = global_position
	_generate_animations()
	anim.play("idle_front")

	interactUI.visible = false

	# Para saber cuando un diálogo termina
	dialog_box.dialog_finished.connect(_on_dialog_finished)



# ================================================================
# ------------------------ MOVIMIENTO -----------------------------
# ================================================================

func _physics_process(delta: float) -> void:
	if not can_move or path_follow == null:
		return

	path_follow.progress += speed * delta

	var movement := global_position - previous_position
	_update_animation(movement.normalized())

	previous_position = global_position



# ================================================================
# ---------------------- ANIMACIONES ------------------------------
# ================================================================

func _update_animation(direction: Vector2):
	## Si no se mueve → idle
	if direction.length() < 0.01:
		anim.play("idle_" + last_direction)
		return

	# Elegir dirección dominante
	if abs(direction.x) > abs(direction.y):
		last_direction = "right_side" if direction.x > 0 else "left_side"
	else:
		last_direction = "front" if direction.y > 0 else "back"

	anim.play("walk_" + last_direction)



# ================================================================
# ------------ GENERACIÓN AUTOMÁTICA DE ANIMACIONES --------------
# ================================================================

func _generate_animations():
	var frames := SpriteFrames.new()

	for row in range(ANIM_NAMES.size()):
		var anim_name: String = ANIM_NAMES[row]
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, true)
		frames.set_animation_speed(anim_name, 7)

		for col in range(4):
			var atlas := AtlasTexture.new()
			atlas.atlas = new_spritesheet
			atlas.region = Rect2(Vector2(col, row) * FRAME_SIZE, FRAME_SIZE)
			frames.add_frame(anim_name, atlas)

	anim.sprite_frames = frames



# ================================================================
# --------------------- INTERACCIÓN CON EL NPC --------------------
# ================================================================

func _on_break_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = true
		speed = 0.0
		interactUI.visible = true
		interactUI.play("default")

func _on_break_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = false
		speed = 25.0
		interactUI.visible = false

		# Si había diálogo → cerrarlo
		if dialog_box.is_showing:
			dialog_box.hide_dialog()
			dialog_box.is_showing = false



# ================================================================
# ------------------ CUANDO EL DIALOGO TERMINA --------------------
# ================================================================

func _on_dialog_finished() -> void:
	## Cuando el dialogo universal dice “ya terminé”
	interactUI.visible = true
	dialog_box.is_showing = false
	## Esto permite volver a hablar con el NPC sin bugs.



# ================================================================
# ------------------- MANEJO DE INPUT DEL JUGADOR -----------------
# ================================================================

func _input(event: InputEvent) -> void:
	if not player_in_area:
		return

	## Si el jugador presionó "interact" dentro del área
	if event.is_action_pressed("interact"):

		## Caso 1: NO hay diálogo abierto → abrir diálogo
		if not dialog_box.is_showing:

			# Evitar que avance automáticamente la primera línea
			get_viewport().set_input_as_handled()

			dialog_box.show_dialog(dialog_library)
			return

		## Caso 2: diálogo YA está abierto → dejar que el DialogBox lo maneje
		## NO usamos set_input_as_handled aquí, para permitir avanzar/cerrar
