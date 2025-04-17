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
	initial_spawn_timer.timeout.connect(_on_initial_spawn_timeout)
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	initial_spawn_timer.start()


func _on_initial_spawn_timeout():
	if initial_spawn_count < max_slimes:
		spawn_slime()
		initial_spawn_count += 1
		current_slimes += 1
	else: 
		initial_spawn_timer.stop()
		respawn_timer.start()

func _on_respawn_timer_timeout():
	if current_slimes < max_slimes:
		spawn_slime()
		current_slimes += 1

func spawn_slime():
	
	if slime_scene == null:
		return
	
	var slime = slime_scene.instantiate()
	slime.global_position = get_random_position_within_area()

	if slime.has_signal("slime_died"):
		slime.connect("slime_died", _on_slime_died)
	
	get_tree().get_current_scene().add_child(slime)

func _on_slime_died():
	current_slimes -= 1

func get_random_position_within_area() -> Vector2:
	var rect = collision_shape.shape as RectangleShape2D
	if rect == null:
		return global_position

	var size = rect.size
	var pos = global_position
	var rand_x = randf_range(-size.x / 2, size.x / 2)
	var rand_y = randf_range(-size.y / 2, size.y / 2)
	var final_pos = pos + Vector2(rand_x, rand_y)
	return final_pos
