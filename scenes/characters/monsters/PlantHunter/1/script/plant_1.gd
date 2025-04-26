extends CharacterBody2D ## Plant Hunter 1

#=====================
#=== Configuracion ===
#=====================

@export var walk_speed: float = 25.0
@export var run_speed: float = 60.0
@export var idle_time: float = 5.0
@export var walk_time:float = 4.0
@export var attack_cooldown: float = 1.3
@export var health: float = 22.0

@onready var animation = $AnimatedSprite2D
@onready var vision_area = $Vision_area
@onready var attack_vision_area = $attack_vision_area
@onready var attack_area = $attack_area
@onready var health_bar = $healthbar

signal plant_died
signal player_hit(damage: float)

var player: Node2D = null
var direction: Vector2 = Vector2.ZERO
var state: String = "idle"
var timer: float = 0.0
var last_direction: String = "front"
var is_attacking: bool = false

# Metodos base

func _ready() -> void:
	animation.play("idle_front")

func _process(delta: float) -> void:
	timer += delta
	
	match state: 
		"idle":
			velocity = Vector2.ZERO
			if timer >= idle_time:
				start_walk()
		"walk":
			velocity = direction * walk_speed
			if timer >= walk_time:
				start_idle()
		"chase":
			if player:
				direction = (player.global_position - global_position).normalized()
				update_last_direction(direction)
				velocity = direction * run_speed
				
				#actualizar animacion segun el movimiento
				var new_animation = "run_" + last_direction
				if animation.animation != new_animation:
					animation.play("run_" + last_direction)
			else:
				start_walk()
		"attack":
			velocity = Vector2.ZERO
			# No se mueve mientras ataca
		"dead":
			velocity = Vector2.ZERO
	
	move_and_slide()

# Estados

func start_idle():
	state = "idle"
	timer = 0
	animation.play("idle_" + last_direction)
	

func start_walk():
	state = "walk"
	timer = 0 
	set_random_direction()
	animation.play("walk_" + last_direction)

func start_chase():
	state = "chase"
	timer = 0
	
	if player:
		direction = (player.global_position - global_position).normalized()
		update_last_direction(direction)
		animation.play("run_" + last_direction)
		

func start_attack():
	if is_attacking:
		return
	is_attacking = true
	state = "attack"
	timer = 0
	animation.play("attack_" + last_direction)
	
	await get_tree().create_timer(1.0).timeout
	
	# si el jugador esta detnro del area de ataque 
	is_attacking = false
	if player:
		start_chase()
	else:
		start_walk()
	

func die():
	state = "dead"
	velocity = Vector2.ZERO
	animation.play("death_" + last_direction)
	await get_tree().create_timer(1.5).timeout
	emit_signal("plant_died")
	queue_free()
	

# Logica auxiliar

func set_random_direction():
	var angle = randf() * TAU
	direction = Vector2(cos(angle), sin(angle)).normalized()
	update_last_direction(direction)

func update_last_direction(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		last_direction = "right_side" if dir.x > 0 else "left_side"
	else:
		last_direction = "front" if dir.y > 0 else "back"
	
func take_damage(amount: float):
	if state == "dead":
		return
	
	animation.play("hurt_" + last_direction)
	health -= amount
	health_bar.value = health
	health_bar.show_for_a_while()
	
	if health <= 0:
		die()


# senales de area 

func _on_vision_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		start_chase()

func _on_vision_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = null
		start_walk()


func _on_attack_vision_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		start_attack()

# Fisicas
func _physics_process(delta: float) -> void:
	#cambiar direccion al chocar
	if state == "walk" and is_on_wall():
		set_random_direction()
