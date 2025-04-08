extends CharacterBody2D ## GREEN SLIME


# Stats
@export var speed: float = 50 # Velocidad normal
@export var panic_speed = 100 # velocidad en estado de panico
@export var idle_time: float = 4.0 # Tiempo en reposo
@export var move_time: float = 5.0 # Tiempo moviendose

@onready var animation = $AnimatedSprite2D
@onready var vision_area = $VisionArea
@onready var health_bar = $HealthBar


@export var health: float = 10.0

var player: Node2D = null

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
	if state == "dead":
		return # no recibe mas danio si esta muerto
	
	animation.play("hurt_" + last_direction)
	health -= amount
	print("Slime recibio dano. Vida restante: ", health)
	
	health_bar.value = health
	health_bar.show_for_a_while()
	
	if health <= 0:
		die()
	
func die():
	state = "dead"
	velocity = Vector2.ZERO
	animation.play("die_" + last_direction)
	
	await get_tree().create_timer(1.5).timeout
	
	queue_free()
