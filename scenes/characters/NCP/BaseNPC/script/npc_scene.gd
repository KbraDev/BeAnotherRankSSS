extends CharacterBody2D ## NPC BASE

# --- Variables exportadas ---
# --- Asignables en el editor ---
@export var new_spritesheet: Texture2D   # La hoja de sprites que este NPC usará.
@export var path_follow: PathFollow2D    # El nodo PathFollow2D que marca su ruta.

# --- Referencias a nodos ---
@onready var anim := $AnimatedSprite2D    # Referencia al sprite animado del NPC.

# --- Estado interno ---
var previous_position: Vector2            # Posición del NPC en el frame anterior.
var speed = 25.0                          # Velocidad con la que se mueve por el path

# --- Constantes ---
# --- Puede variar segun el tamano, forma o frames del spritesheet ---
const FRAME_SIZE = Vector2(48, 96)        # Tamaño de cada frame en la hoja de sprites.

# Lista de animaciones en el orden en que están en el spritesheet.
const ANIM_NAMES = [
	"idle_front",
	"idle_left_side",
	"idle_right_side",
	"idle_back",
	"walk_front",
	"walk_left_side",
	"walk_right_side",
	"walk_back",
]

var last_direction: String = "front"      # Última dirección del NPC para mantener idle correcto.
var can_move := true                      # Controla si el NPC se mueve o no.

# --- Función _ready() ---
func _ready():
	# Guardamos la posición inicial para poder medir movimiento en el primer frame.
	previous_position = global_position

	# Generamos las animaciones según el spritesheet asignado.
	_generate_animations()

	# Reproducimos la animación inicial (idle mirando al frente).
	anim.play("idle_" + last_direction)


# --- Función _physics_process(delta) ---
func _physics_process(delta: float) -> void:
	# Si el NPC no puede moverse o no hay path_follow asignado, salimos.
	if not can_move or path_follow == null: 
		return
	
	# Avanza sobre el path aumentando su 'progress'.
	# Esto mueve al PathFollow2D y, como el NPC está dentro de él, también se mueve.
	path_follow.progress += speed * delta
	
	# Calculamos el desplazamiento REAL del NPC comparando posiciones:
	var movement = global_position - previous_position

	# Actualizamos la animación en base a la dirección real del movimiento.
	_update_animation(movement.normalized())
	
	# Guardamos la posición actual para el siguiente frame.
	previous_position = global_position


# --- Función _update_animation(direction) ---
func _update_animation(direction: Vector2):
	# Si casi no hay movimiento, reproducimos idle en la última dirección registrada.
	if direction.length() < 0.01:
		var idle_anim = "idle_" + last_direction
		if anim.animation != idle_anim:
			anim.play(idle_anim)
		return

	# Determinar la dirección en la que se mueve para elegir animación de caminar.
	if abs(direction.x) > abs(direction.y):
		last_direction = "right_side" if direction.x > 0 else "left_side"
	else:
		last_direction = "front" if direction.y > 0 else "back"

	# Reproducir la animación de caminar correspondiente.
	var walk_anim = "walk_" + last_direction
	if anim.animation != walk_anim:
		anim.play(walk_anim)

# --- Función _generate_animations() ---
func _generate_animations():
	# Creamos un nuevo contenedor de frames para AnimatedSprite2D.
	var frames = SpriteFrames.new()

	# Recorremos cada animación (fila del spritesheet).
	for row in range(ANIM_NAMES.size()):
		var anim_name = ANIM_NAMES[row]
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, true)
		frames.set_animation_speed(anim_name, 7)

		# Cada animación tiene 4 frames en horizontal.
		for i in range(4):
			var atlas := AtlasTexture.new()
			atlas.atlas = new_spritesheet
			# Calculamos la región correspondiente a este frame.
			atlas.region = Rect2(Vector2(i, row) * FRAME_SIZE, FRAME_SIZE)
			frames.add_frame(anim_name, atlas)

	# Asignamos este conjunto de frames al AnimatedSprite2D.
	anim.sprite_frames = frames


# --- SECCION PARA DETECTAR CUANDO DEBE FRENAR EL NCP ---
# --- Aplica cuando el Jugador entre en el area del NPC ---
# --- Su variable "speed" debera ser igual a 0, cuando el jugador salga debera resutaurarse. ---

# --- Fun para detener al NPC ---
func _on_break_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		speed = 0.0

# --- func para reanudar recorrido ---
func _on_break_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		speed = 25.0
