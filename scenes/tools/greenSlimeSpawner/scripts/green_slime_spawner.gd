extends Area2D

@export var slime_scene: PackedScene
@export var max_slimes := 7
@export var spawn_interval := 10.0

var current_slimes: Array = []
var timer: float = 0.0

func _ready() -> void:
	# Generar slimes iniciales hasta completar el máximo
	while current_slimes.size() < max_slimes:
		spawn_slime()

func _process(delta: float) -> void:
	timer += delta
	if timer >= spawn_interval:
		timer = 0.0
		# Solo generar uno si falta alguno
		current_slimes = current_slimes.filter(func(s): return is_instance_valid(s))
		if current_slimes.size() < max_slimes and not is_visible_to_camera():
			spawn_slime()

func spawn_slime():
	var shape = $CollisionShape2D.shape
	if shape == null:
		return
	
	var local_offset := Vector2.ZERO

	if shape is CircleShape2D:
		# Usamos sqrt(randf()) para una distribución uniforme en el círculo
		var angle = randf_range(0, TAU)
		var radius = sqrt(randf()) * shape.radius
		local_offset = Vector2(cos(angle), sin(angle)) * radius

	elif shape is RectangleShape2D:
		local_offset = Vector2(
			randf_range(-shape.size.x / 2, shape.size.x / 2),
			randf_range(-shape.size.y / 2, shape.size.y / 2)
		)

	var slime = slime_scene.instantiate()
	slime.global_position = global_position + local_offset
	get_tree().current_scene.add_child(slime)
	current_slimes.append(slime)

func is_visible_to_camera() -> bool:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return false

	var screen_size := get_viewport_rect().size
	var visible_rect := Rect2(cam.global_position - screen_size * 0.5, screen_size)
	return visible_rect.has_point(global_position)
