extends CanvasLayer

@onready var color_rect := $ColorRect
@onready var anim := $AnimationPlayer

var is_transitioning := false

func _ready():
	print("[TransitionOverlay] 🚀 Ready ejecutado — Overlay completamente inicializado.")
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.modulate.a = 0.0
	print("[TransitionOverlay] ✅ Autoload inicializado correctamente en el árbol.")
	# Asegurar que haya una AnimationLibrary por defecto (clave "")
	if anim.get_animation_library("") == null:
		anim.add_animation_library("", AnimationLibrary.new())

	# Crear animaciones si faltan
	if not anim.has_animation("fade_out"):
		_create_fade_animation("fade_out", 0.0, 1.0)

	if not anim.has_animation("fade_in"):
		_create_fade_animation("fade_in", 1.0, 0.0)

	color_rect.modulate.a = 0.0  # empezar transparente


# 🔹 Crea una animación que cambia la opacidad entre dos valores
func _create_fade_animation(name: String, from_alpha: float, to_alpha: float, duration: float = 0.8) -> void:
	var anim_resource := Animation.new()
	anim_resource.length = duration

	# Crear track de tipo "valor"
	var track_index := anim_resource.add_track(Animation.TYPE_VALUE)
	# Path relativo: AnimationPlayer y ColorRect son hermanos, así que "ColorRect:modulate:a" funciona.
	anim_resource.track_set_path(track_index, "ColorRect:modulate:a")

	# Insertar los keyframes
	anim_resource.track_insert_key(track_index, 0.0, from_alpha)
	anim_resource.track_insert_key(track_index, duration, to_alpha)
	anim_resource.track_set_interpolation_type(track_index, Animation.INTERPOLATION_LINEAR)

	# Registrar animación en la librería por defecto
	var lib: AnimationLibrary = anim.get_animation_library("") as AnimationLibrary
	if lib == null:
		# Si por alguna razón no existe, crear y volver a obtenerla
		anim.add_animation_library("", AnimationLibrary.new())
		lib = anim.get_animation_library("") as AnimationLibrary

	lib.add_animation(name, anim_resource)


# 🟢 Fundido a negro
func fade_out(duration := 0.5) -> void:
	if is_transitioning:
		return
	is_transitioning = true

	if anim.has_animation("fade_out"):
		anim.play("fade_out")
		await anim.animation_finished

	is_transitioning = false


# 🟢 Fundido desde negro
func fade_in(duration := 0.5) -> void:
	if is_transitioning:
		return
	is_transitioning = true

	if anim.has_animation("fade_in"):
		anim.play("fade_in")
		await anim.animation_finished

	is_transitioning = false


# 🟡 Cambio de escena con transición integrada
func fade_to_scene(scene_path: String) -> void:
	await fade_out()
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await fade_in()
