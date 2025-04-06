extends CharacterBody2D ## GREEN SLIME


# Stats
@export var speed: float = 50 
@export var idle_time: float = 4.0 # Tiempo en reposo
@export var move_time: float = 5.0 # Tiempo moviendose

@onready var animation = $AnimatedSprite2D

# Variables de movimiento
var direction: Vector2 = Vector2.ZERO
var timer: float = 0.0
var state: String = "idle"
var last_direction: String = "front" # Guarda la ultima direccion

func _ready() -> void:
	animation.play("idle_front")
	set_process(true)

func _process(delta: float) -> void:
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
				
	var collision = move_and_slide()
	
func start_idle():
	state = "idle"
	timer = 0
	animation.play("idle_" + last_direction)

func start_moving():
	state = "move"
	timer = 0
	set_random_direction()
	animation.play("walk_" + last_direction)
	
func set_random_direction():
	var angle = randf() * TAU
	direction = Vector2(cos(angle), sin(angle)).normalized()
	
	# Determina hacia donde mira segun el vector de direccion
	if abs(direction.x) > abs(direction.y):
		last_direction = "right_side" if direction.x > 0 else "left_side"
	else: 
		last_direction = "front" if direction.y > 0 else "back"
	
