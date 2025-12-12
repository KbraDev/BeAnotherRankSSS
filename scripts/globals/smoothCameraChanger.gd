extends Node

var _blend_camera: Camera2D
var _player_camera: Camera2D
var _target_camera: Camera2D

var _blend_time: float
var _hold_time: float
var _on_finished: Callable = Callable()

func play_cutscene(player_cam: Camera2D, target_cam: Camera2D, blend_cam: Camera2D,
	blend_time := 1.0, hold_time := 2.0, on_finished := Callable()):
	
	_player_camera = player_cam
	_target_camera = target_cam
	_blend_camera = blend_cam
	_blend_time = blend_time
	_hold_time = hold_time
	_on_finished = on_finished

	_start_blend_to_target()


func _start_blend_to_target():
	# Inicia blend desde player hasta target
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

	tween.tween_callback(Callable(self, "_on_arrive_target"))


func _on_arrive_target():
	_target_camera.make_current()

	var tween = create_tween()
	tween.tween_interval(_hold_time)
	tween.tween_callback(Callable(self, "_start_blend_back"))


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

	tween.tween_callback(Callable(self, "_finish"))


func _finish():
	_player_camera.make_current()
	_blend_camera.enabled = false

	if _on_finished.is_valid():
		_on_finished.call()
