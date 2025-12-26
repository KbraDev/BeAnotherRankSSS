extends Node
class_name AutonomousMovementController
## ===============================================================
## CONTROLADOR DE MOVIMIENTO AUTÓNOMO
## ---------------------------------------------------------------
## Componente reutilizable que implementa un comportamiento de
## "wander / idle" para NPCs y mobs.
##
## Funcionalidades:
## - Decide aleatoriamente si el NPC se mueve o se detiene
## - Elige una dirección cardinal (up, down, left, right)
## - Mantiene la última dirección válida (last_direction)
## - Reproduce automáticamente:
##     - walk_<last_direction> cuando se mueve
##     - idle_<last_direction> cuando se detiene
##
## Este script NO hereda CharacterBody2D.
## Debe ser usado como NODO HIJO (composición).
##
## Ideal para:
## - NPCs ambientales
## - Animales
## - Mobs simples
## - Compañeros con comportamiento pasivo
## ===============================================================


# ===============================================================
# ---------------------- CONFIGURACIÓN ----------------------------
# ===============================================================

@export var autonomous_enabled: bool = true
## Switch principal:
## - true  -> el NPC usa movimiento autónomo
## - false -> el NPC queda estático (idle_front)

@export var speed: float = 40.0
## Velocidad de desplazamiento del NPC mientras se mueve.

@export var move_time_range := Vector2(1.5, 3.5)
## Rango de tiempo (en segundos) durante el cual el NPC
## permanecerá caminando antes de decidir un nuevo estado.

@export var idle_time_range := Vector2(1.0, 2.5)
## Rango de tiempo (en segundos) durante el cual el NPC
## permanecerá quieto antes de volver a decidir.


# ===============================================================
# --------------------- REFERENCIAS -------------------------------
# ===============================================================

@export var animated_sprite: AnimatedSprite2D
## Referencia directa al AnimatedSprite2D del NPC.
## Debe asignarse manualmente desde el Inspector.


# ===============================================================
# --------------------- REFERENCIAS INTERNAS ----------------------
# ===============================================================

var owner_body: CharacterBody2D
## Referencia al nodo padre (el NPC que se moverá).

var anim: AnimatedSprite2D
## Cache interno del sprite animado.


# ===============================================================
# ------------------------ ESTADO --------------------------------
# ===============================================================

var last_direction: String = "front"
## Última dirección válida utilizada para animaciones.
## Se mantiene incluso cuando el NPC está en idle.

var current_direction: Vector2 = Vector2.ZERO
## Dirección actual de movimiento (vector normalizado).

var is_moving: bool = false
## Indica si el NPC se encuentra caminando o en estado idle.

var state_timer: float = 0.0
## Temporizador interno que controla la duración del estado actual.


# ===============================================================
# ------------------------- READY --------------------------------
# ===============================================================

func _ready() -> void:
	## El controlador debe ser hijo directo de un CharacterBody2D.
	owner_body = get_parent() as CharacterBody2D
	assert(
		owner_body != null,
		"AutonomousMovementController debe ser hijo de CharacterBody2D"
	)

	## Validación de referencia al sprite animado.
	anim = animated_sprite
	assert(
		anim != null,
		"AnimatedSprite2D no asignado al AutonomousMovementController"
	)

	## Inicializa la semilla aleatoria para evitar
	## comportamientos repetitivos.
	randomize()
	
	if autonomous_enabled: 
		_pick_new_state()
	else: 
		_force_idle()



# ===============================================================
# ------------------------ ACTUALIZACIÓN --------------------------
# ===============================================================

func physics_update(delta: float) -> void:
	## Si el movimiento autónomo está desactivado,
	## no se procesa ninguna lógica automática.
	if not autonomous_enabled:
		return
	
	## Reduce el temporizador del estado actual.
	state_timer -= delta
	
	## Cuando el temporizador expira, se decide un nuevo estado.
	if state_timer <= 0:
		_pick_new_state()

	## Aplica la velocidad al cuerpo principal.
	if is_moving:
		owner_body.velocity = current_direction * speed
	else:
		owner_body.velocity = Vector2.ZERO

	## Ejecuta el movimiento físico.
	owner_body.move_and_slide()

	## Actualiza la animación correspondiente.
	_update_animation()


# ===============================================================
# --------------------- LÓGICA DE ESTADOS -------------------------
# ===============================================================

func _pick_new_state() -> void:
	## Decide aleatoriamente si el NPC se moverá.
	## Aproximadamente 65% de probabilidad de caminar.
	is_moving = randf() > 0.35

	if is_moving:
		current_direction = _get_random_direction()
		state_timer = randf_range(move_time_range.x, move_time_range.y)
	else:
		current_direction = Vector2.ZERO
		state_timer = randf_range(idle_time_range.x, idle_time_range.y)

func _force_idle() -> void:
	## Estado forzado cuando el movimiento está desactivado
	is_moving = false
	current_direction = Vector2.ZERO
	state_timer = 0.0

	owner_body.velocity = Vector2.ZERO
	owner_body.move_and_slide()

	last_direction = "front"
	anim.play("idle_front")

# ===============================================================
# ------------------ DIRECCIÓN ALEATORIA --------------------------
# ===============================================================

func _get_random_direction() -> Vector2:
	## Direcciones cardinales permitidas.
	return [
		Vector2.UP,
		Vector2.DOWN,
		Vector2.LEFT,
		Vector2.RIGHT
	].pick_random()


# ===============================================================
# ---------------------- ANIMACIONES ------------------------------
# ===============================================================

func _update_animation() -> void:
	## Si no hay movimiento, se reproduce la animación idle
	## usando la última dirección válida.
	if owner_body.velocity.length() < 0.05:
		anim.play("idle_" + last_direction)
		return

	## Determina la dirección dominante del movimiento
	## y actualiza last_direction.
	if abs(owner_body.velocity.x) > abs(owner_body.velocity.y):
		last_direction = "right_side" if owner_body.velocity.x > 0 else "left_side"
	else:
		last_direction = "front" if owner_body.velocity.y > 0 else "back"

	## Reproduce la animación de caminar correspondiente.
	anim.play("walk_" + last_direction)


# ===============================================================
# ------------------ CONTROL EXTERNO -----------------------------
# ===============================================================

func set_autonomous_enabled(value: bool) -> void:
	autonomous_enabled = value

	if autonomous_enabled:
		_pick_new_state()
	else:
		_force_idle()
