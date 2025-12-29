extends CharacterBody2D
class_name Angeler

## ===============================================================
## ANGELER
## ---------------------------------------------------------------
## NPC con dos modos de movimiento:
## - Movimiento autónomo (wander / idle)
## - Movimiento scripted (eventos / cinemáticas)
##
## El modo scripted tiene prioridad absoluta sobre el autónomo.
## ===============================================================


# ===============================================================
# ---------------------- CONFIGURACIÓN ----------------------------
# ===============================================================

@export var autonomous_movement_enabled: bool = true
## Controla si Angeler usa movimiento autónomo por defecto


# ===============================================================
# --------------------- REFERENCIAS -------------------------------
# ===============================================================

@onready var autonomous_controller: AutonomousMovementController = $AutonomousMovementController
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hiya: AudioStreamPlayer = $HiyaVoice


# ===============================================================
# ------------------------ ESTADO --------------------------------
# ===============================================================

## Dirección usada para animaciones (idle / walk)
var last_direction: String = "front"


# ===============================================================
# ------------ MOVIMIENTO SCRIPTED (EVENTOS) ---------------------
# ===============================================================

var scripted_path: Path2D
var path_follow: PathFollow2D

var scripted_speed: float = 60.0
var scripted_direction: int = 1 # 1 = forward, -1 = reverse
var in_scripted_move: bool = false


# ===============================================================
# ------------------------- READY --------------------------------
# ===============================================================

func _ready() -> void:
	if autonomous_controller:
		autonomous_controller.set_autonomous_enabled(
			autonomous_movement_enabled
		)


# ===============================================================
# ------------------ AUDIO / ACCIONES ----------------------------
# ===============================================================

func play_hiya_voice() -> void:
	if hiya:
		hiya.play()


# ===============================================================
# -------------- CONTROL MOVIMIENTO SCRIPTED --------------------
# ===============================================================

func start_scripted_move(
	path: Path2D,
	speed: float = 50.0,
	reverse: bool = false
) -> void:
	## Detener cualquier movimiento previo
	stop_scripted_move()

	in_scripted_move = true

	## Apagar movimiento autónomo
	if autonomous_controller:
		autonomous_controller.set_autonomous_enabled(false)

	scripted_path = path
	scripted_speed = speed
	scripted_direction = -1 if reverse else 1

	## Crear PathFollow dinámico
	path_follow = PathFollow2D.new()
	path_follow.rotates = false
	path_follow.loop = false
	scripted_path.add_child(path_follow)

	path_follow.progress_ratio = 1.0 if reverse else 0.0


func scripted_move_finished() -> bool:
	if not path_follow:
		return true

	if scripted_direction == 1:
		return path_follow.progress_ratio >= 1.0
	else:
		return path_follow.progress_ratio <= 0.0


func stop_scripted_move() -> void:
	in_scripted_move = false

	if path_follow and path_follow.is_inside_tree():
		path_follow.queue_free()

	path_follow = null
	scripted_path = null

	_play_idle()


# ===============================================================
# ------------------ ACTUALIZACIÓN FÍSICA ------------------------
# ===============================================================

func _physics_process(delta: float) -> void:
	## PRIORIDAD: movimiento scripted
	if in_scripted_move and path_follow:
		_process_scripted_move(delta)
		return

	## Movimiento autónomo
	if autonomous_controller:
		autonomous_controller.physics_update(delta)


func _process_scripted_move(delta: float) -> void:
	path_follow.progress += scripted_speed * delta * scripted_direction

	## Clamp duro al final del path
	if scripted_direction == 1 and path_follow.progress_ratio >= 1.0:
		path_follow.progress_ratio = 1.0
		stop_scripted_move()
		return

	if scripted_direction == -1 and path_follow.progress_ratio <= 0.0:
		path_follow.progress_ratio = 0.0
		stop_scripted_move()
		return

	## Movimiento + animación
	var previous_pos := global_position
	var target_pos := path_follow.global_position
	global_position = target_pos

	var dir := target_pos - previous_pos
	_update_walk_animation(dir)


# ===============================================================
# ---------------------- ANIMACIONES -----------------------------
# ===============================================================

func _update_walk_animation(direction: Vector2) -> void:
	if direction.length() < 0.01:
		return

	if abs(direction.x) > abs(direction.y):
		last_direction = "right_side" if direction.x > 0 else "left_side"
	else:
		last_direction = "front" if direction.y > 0 else "back"

	var anim := "walk_" + last_direction
	if sprite.animation != anim:
		sprite.play(anim)


func _play_idle() -> void:
	var anim := "idle_" + last_direction
	if sprite.animation != anim:
		sprite.play(anim)
