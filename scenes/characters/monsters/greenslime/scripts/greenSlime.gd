extends CharacterBody2D ## GREEN SLIME


# Stats
@export var speed: float = 50 # Velocidad normal
@export var panic_speed = 80 # velocidad en estado de panico
@export var idle_time: float = 4.0 # Tiempo en reposo
@export var move_time: float = 5.0 # Tiempo moviendose
@export var xp_reward_range := Vector2(6, 12)

@onready var animation = $AnimatedSprite2D
@onready var vision_area = $VisionArea
@onready var health_bar = $HealthBar

signal slime_died
var has_died := false

@export var health: float = 10.0

var player: Node2D = null

# Variables de movimiento
var direction: Vector2 = Vector2.ZERO
var timer: float = 0.0
var state: String = "idle"
var last_direction: String = "front" # Guarda la ultima direccion

func _ready() -> void:
	animation.play("idle_front")
	add_to_group("slime")
	set_process(true)

func _process(delta: float) -> void:
	if has_died:
		return
	
	timer += delta
	
	match state:
		"idle":
			velocity = Vector2.ZERO
			if timer >= idle_time:
				start_moving()
		"move":
			velocity = direction * speed
			if timer >= move_time:
				start_idle()
		"panic":
			if player:
				var flee_direction = (global_position - player.global_position).normalized()
				velocity = flee_direction * panic_speed
				update_last_direction(flee_direction)
			else: 
				start_idle()
	
	move_and_slide()
	
func start_idle():
	state = "idle"
	timer = 0
	animation.play("idle_" + last_direction)

func start_moving():
	state = "move"
	timer = 0
	set_random_direction()
	animation.play("walk_" + last_direction)
	
func start_panic():
	state = "panic"
	timer = 0
	animation.play("run_" + last_direction)

func set_random_direction():
	var angle = randf() * TAU
	direction = Vector2(cos(angle), sin(angle)).normalized()
	
	# Determina hacia donde mira segun el vector de direccion
	if abs(direction.x) > abs(direction.y):
		last_direction = "right_side" if direction.x > 0 else "left_side"
	else: 
		last_direction = "front" if direction.y > 0 else "back"
	

func  update_last_direction(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		last_direction = "right_side" if dir.x > 0 else "left_side"
	else: 
		last_direction = "front" if dir.y > 0 else "back"

func _on_vision_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		start_panic()


func _on_vision_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = null
		start_idle()
		

func take_damage(amount: float) -> void:
	if has_died:
		return
	
	# No permitir que se ejecute varias veces en un solo frame
	health -= amount
	health = max(health, 0)  # Nunca menos de 0

	animation.play("hurt_" + last_direction)
	health_bar.value = health
	health_bar.show_for_a_while()

	if health <= 0:
		die()


func die():
	if has_died:
		return

	has_died = true
	state = "dead"
	velocity = Vector2.ZERO

	# Bloquea todo movimiento desde ya
	set_physics_process(false)
	vision_area.monitoring = false

	animation.play("die_" + last_direction)



func _on_animated_sprite_2d_animation_finished():
	if has_died and animation.animation == "die_" + last_direction:
		# Drop de ítem
		var pickup_scene = preload("res://scenes/World_pick-ups/pick_ups_items.tscn")
		var pickup = pickup_scene.instantiate()
		pickup.item_data = preload("res://items/resources/slime_teardrop.tres")
		pickup.amount = 1
		pickup.global_position = global_position
		get_tree().current_scene.add_child(pickup)

		# Otorgar experiencia
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var xp = randi_range(xp_reward_range.x, xp_reward_range.y)
			player.gain_experience(xp)

		emit_signal("slime_died")
		queue_free()
