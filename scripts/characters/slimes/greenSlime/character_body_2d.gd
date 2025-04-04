extends CharacterBody2D ## GREEN SLIME


# Stats
@export var speed: float = 50 
@export var change_time: float = 3.0 # Tiempo para cambiar de direccion

@onready var animation = $AnimatedSprite2D

# Variables de movimiento
var direction: Vector2 = Vector2.ZERO

# Controladores
var timer: float = 0

func _ready() -> void:
	animation.play("idle_front")
	set_random_direction() # Al iniciar, establece una direccion aleatoria
	
func _process(delta: float) -> void:
	timer += delta
	if timer >= change_time:
		set_random_direction()
		timer = 0
	
	velocity = direction * speed
	move_and_slide()

func set_random_direction():
	var angle = randf() * TAU # TAU es 2 * pi, lo que da un angulo aleatorio
	direction = Vector2(cos(angle), sin(angle))
