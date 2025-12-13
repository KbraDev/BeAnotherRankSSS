extends Node

# --------------------------------------------------------------------
# SmoothCameraChanger (Autoload)
#
# Sistema encargado de manejar transiciones suaves entre cámaras.
#
# Flujo completo:
#   1. Blend desde la cámara del jugador hacia una cámara objetivo.
#   2. Mantener enfoque en la cámara objetivo (hold).
#   3. Blend de regreso hacia la cámara del jugador.
#
# El sistema utiliza una "blend camera" intermedia para interpolar
# posición y zoom mediante tweens, evitando cortes bruscos.
#
# IMPORTANTE:
# - Este sistema NO conoce gameplay, bosses, UI ni audio.
# - Solo orquesta cámaras y tiempos.
# - La lógica externa se inyecta mediante callbacks.
# --------------------------------------------------------------------

# ===================== CAMERAS =====================

var _blend_camera: Camera2D       # Cámara intermedia usada para interpolaciones
var _player_camera: Camera2D      # Cámara principal del jugador
var _target_camera: Camera2D      # Cámara objetivo (boss, NPC, punto de interés)

# ===================== TIMING ======================

var _blend_time: float            # Duración de cada transición (ida y vuelta)
var _hold_time: float             # Tiempo que la cámara permanece en el target

# ===================== CALLBACKS ===================

# Se ejecuta EXACTAMENTE cuando la cámara llega al target
# (inicio del hold_time)
var _on_focus_started: Callable = Callable()

# Se ejecuta al finalizar TODA la secuencia
# (cuando la cámara vuelve al jugador)
var _on_finished: Callable = Callable()


# --------------------------------------------------------------------
# play_cutscene()
#
# Inicia la secuencia completa de cámaras.
#
# Parámetros:
#   player_cam:
#       Cámara actual del jugador.
#
#   target_cam:
#       Cámara objetivo a la que se hará focus.
#
#   blend_cam:
#       Cámara intermedia usada para interpolar suavemente.
#
#   blend_time:
#       Tiempo que dura cada interpolación (player->target y target->player).
#
#   hold_time:
#       Tiempo que la cámara permanece enfocando al target.
#
#   on_focus_started:
#       Callback opcional que se ejecuta al llegar al target.
#       Ideal para:
#         - Gritos del boss
#         - Animaciones
#         - FX
#         - Diálogos
#
#   on_finished:
#       Callback opcional que se ejecuta al final de la secuencia.
#       Ideal para:
#         - Activar IA
#         - Mostrar UI
#         - Devolver control al jugador
# --------------------------------------------------------------------
func play_cutscene(
	player_cam: Camera2D,
	target_cam: Camera2D,
	blend_cam: Camera2D,
	blend_time := 1.0,
	hold_time := 2.0,
	on_focus_started := Callable(),
	on_finished := Callable()
):
	_player_camera = player_cam
	_target_camera = target_cam
	_blend_camera = blend_cam
	_blend_time = blend_time
	_hold_time = hold_time
	_on_focus_started = on_focus_started
	_on_finished = on_finished

	_start_blend_to_target()


# --------------------------------------------------------------------
# _start_blend_to_target()
#
# Fase 1:
#   - Activa la blend camera.
#   - Copia la posición y zoom actuales del jugador.
#   - Interpola suavemente hacia la posición y zoom del target.
# --------------------------------------------------------------------
func _start_blend_to_target():
	_blend_camera.global_position = _player_camera.global_position
	_blend_camera.zoom = _player_camera.zoom
	_blend_camera.enabled = true
	_blend_camera.make_current()

	var tween = create_tween()

	tween.tween_property(
		_blend_camera,
		"global_position",
		_target_camera.global_position,
		_blend_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.parallel().tween_property(
		_blend_camera,
		"zoom",
		_target_camera.zoom,
		_blend_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_callback(_on_arrive_target)


# --------------------------------------------------------------------
# _on_arrive_target()
#
# Fase 2 (FOCUS / HOLD):
#   - La cámara real del target se vuelve activa.
#   - Se dispara el callback on_focus_started.
#   - Se mantiene el enfoque durante _hold_time.
# --------------------------------------------------------------------
func _on_arrive_target():
	_target_camera.make_current()

	# Punto exacto donde el target entra en foco visual.
	# Aquí deben ocurrir eventos cinematográficos.
	if _on_focus_started.is_valid():
		_on_focus_started.call()

	var tween = create_tween()
	tween.tween_interval(_hold_time)
	tween.tween_callback(_start_blend_back)


# --------------------------------------------------------------------
# _start_blend_back()
#
# Fase 3:
#   - Desde la posición del target, la blend camera interpola
#     de regreso hacia la cámara del jugador.
# --------------------------------------------------------------------
func _start_blend_back():
	_blend_camera.global_position = _target_camera.global_position
	_blend_camera.zoom = _target_camera.zoom
	_blend_camera.enabled = true
	_blend_camera.make_current()

	var tween = create_tween()

	tween.tween_property(
		_blend_camera,
		"global_position",
		_player_camera.global_position,
		_blend_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.parallel().tween_property(
		_blend_camera,
		"zoom",
		_player_camera.zoom,
		_blend_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_callback(_finish)


# --------------------------------------------------------------------
# _finish()
#
# Fase final:
#   - La cámara del jugador vuelve a ser la activa.
#   - Se desactiva la blend camera.
#   - Se ejecuta el callback final.
# --------------------------------------------------------------------
func _finish():
	_player_camera.make_current()
	_blend_camera.enabled = false

	if _on_finished.is_valid():
		_on_finished.call()
