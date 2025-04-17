extends Area2D

@export var slime_scene: PackedScene
@export var max_slimes := 7
var current_slimes := 0
var initial_spawn_count := 0 

@onready var initial_spawn_timer = $initialSpawnTimer   
@onready var respawn_timer = $respawnTimer
@onready var collision_shape = $CollisionShape2D


func _ready() -> void:
	randomize()
	print("🟢 Spawn Zone lista. Iniciando spawn inicial...")
	initial_spawn_timer.timeout.connect(_on_initial_spawn_timeout)
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	initial_spawn_timer.start()


func _on_initial_spawn_timeout():
	print("🕒 Spawn inicial: ", initial_spawn_count, "/", max_slimes)
	if initial_spawn_count < max_slimes:
		spawn_slime()
		initial_spawn_count += 1
		current_slimes += 1
	else: 
		print("✅ Spawn inicial completo. Iniciando respawn.")
		initial_spawn_timer.stop()
		respawn_timer.start()

func _on_respawn_timer_timeout():
	print("🕒 Respawn: Slimes actuales:", current_slimes)
	if current_slimes < max_slimes:
		print("➕ Espawneando slime adicional para rellenar hueco.")
		spawn_slime()
		current_slimes += 1
	else:
		print("⏸️ Slimes al máximo. Esperando que muera alguno.")

func spawn_slime():
	
	if slime_scene == null:
		print("❌ ERROR: slime_scene no está asignado.")
		return
	
	var slime = slime_scene.instantiate()
	slime.global_position = get_random_position_within_area()
	print("📦 Slime instanciado en: ", slime.position)

	if slime.has_signal("slime_died"):
		slime.connect("slime_died", _on_slime_died)
		print("🔗 Conectado a señal slime_died")
	else:
		print("⚠️ ADVERTENCIA: El slime no tiene la señal 'slime_died'.")

	get_tree().get_current_scene().add_child(slime)
	print("✅ Slime añadido a la escena.")

func _on_slime_died():
	current_slimes -= 1
	print("☠️ Slime muerto. Slimes vivos: ", current_slimes)

func get_random_position_within_area() -> Vector2:
	var rect = collision_shape.shape as RectangleShape2D
	if rect == null:
		print("❌ ERROR: CollisionShape2D no tiene una RectangleShape2D asignada.")
		return global_position

	var size = rect.size
	var pos = global_position
	var rand_x = randf_range(-size.x / 2, size.x / 2)
	var rand_y = randf_range(-size.y / 2, size.y / 2)
	var final_pos = pos + Vector2(rand_x, rand_y)
	print("📍 Posición generada dentro del área: ", final_pos)
	return final_pos

func _draw():
	if collision_shape.shape is RectangleShape2D:
		draw_rect(Rect2(-collision_shape.shape.size / 2, collision_shape.shape.size), Color(0, 1, 0, 0.2), true)
