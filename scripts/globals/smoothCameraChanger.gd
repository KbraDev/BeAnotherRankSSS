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

var _blend_camera: Camera2D
var _player_camera: Camera2D
var _target_camera: Camera2D

# ===================== TIMING ======================

var _blend_time: float
var _hold_time: float

# ===================== CALLBACKS ===================

var _on_focus_started: Callable = Callable()
var _on_finished: Callable = Callable()
var _follow_player := false
var _return_tween: Tween

# ===================== SHAKE =======================

var _shake_tween: Tween
var _shake_origin: Vector2
var _enable_shake = true


func _process(_delta):
	if _follow_player and is_instance_valid(_player_camera):
		_blend_camera.global_position = _player_camera.global_position

# --------------------------------------------------------------------
# play_cutscene()
# --------------------------------------------------------------------
func play_cutscene(
	player_cam: Camera2D,
	target_cam: Camera2D,
	blend_cam: Camera2D,
	blend_time := 1.0,
	hold_time := 2.0,
	on_focus_started := Callable(),
	on_finished := Callable(),
	enable_shake := true
):
	_player_camera = player_cam
	_target_camera = target_cam
	_blend_camera = blend_cam
	_blend_time = blend_time
	_hold_time = hold_time
	_on_focus_started = on_focus_started
	_on_finished = on_finished
	_enable_shake = enable_shake

	_start_blend_to_target()


# --------------------------------------------------------------------
# FASE 1 – Blend hacia el target
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
# FASE 2 – Focus / Hold
# --------------------------------------------------------------------
func _on_arrive_target():
	_target_camera.make_current()

	_shake_origin = _target_camera.position

	if _on_focus_started.is_valid():
		_on_focus_started.call()

	if _enable_shake:
		_start_camera_shake(
			_target_camera,
			8.0,
			0.35,
			0.05
		)

	var tween = create_tween()
	tween.tween_interval(_hold_time)
	tween.tween_callback(_start_blend_back)


# --------------------------------------------------------------------
# FASE 3 – Blend de regreso
# --------------------------------------------------------------------
func _start_blend_back():
	_blend_camera.global_position = _target_camera.global_position
	_blend_camera.zoom = _target_camera.zoom
	_blend_camera.enabled = true
	_blend_camera.make_current()

	_follow_player = false

	if _return_tween:
		_return_tween.kill()

	_return_tween = create_tween()

	# Regreso visible hacia la posición ACTUAL del jugador
	_return_tween.tween_property(
		_blend_camera,
		"global_position",
		_player_camera.global_position,
		_blend_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_return_tween.parallel().tween_property(
		_blend_camera,
		"zoom",
		_player_camera.zoom,
		_blend_time
	)

	# Al terminar, activar seguimiento dinámico
	_return_tween.tween_callback(_enable_follow_and_finish)

func _enable_follow_and_finish():
	_follow_player = true
	_finish()


# --------------------------------------------------------------------
# FASE FINAL
# --------------------------------------------------------------------
func _finish():
	_follow_player = false
	_player_camera.make_current()
	_blend_camera.enabled = false

	if _on_finished.is_valid():
		_on_finished.call()

# --------------------------------------------------------------------
# CAMERA SHAKE
#
# Aplica un temblor leve a una Camera2D usando offsets rápidos.
# Diseñado para impactos, gritos y eventos cinematográficos.
# --------------------------------------------------------------------
func _start_camera_shake(
	camera: Camera2D,
	intensity := 6.0,
	duration := 0.3,
	frequency := 0.04
):
	if not is_instance_valid(camera):
		return

	if _shake_tween and _shake_tween.is_running():
		_shake_tween.kill()

	_shake_origin = camera.position
	_shake_tween = create_tween()

	var elapsed := 0.0

	while elapsed < duration:
		var offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)

		_shake_tween.tween_property(
			camera,
			"position",
			_shake_origin + offset,
			frequency
		)

		elapsed += frequency

	# Volver suavemente a la posición original
	_shake_tween.tween_property(
		camera,
		"position",
		_shake_origin,
		0.1
	)
