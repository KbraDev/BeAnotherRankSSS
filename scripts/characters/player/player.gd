extends CharacterBody2D ## Player

const SPEED = 150.0
const ATTACK_COOLDOWN = 0.4 # Tiempo entre cada ataque
const DAMAGE = 3.0 # Daño fijo del jugador

@onready var attack_area = $attack_area
@onready var animation = $AnimatedSprite2D
@onready var attack_timer = Timer.new()

var last_direction := "front"

# Variables de ataque 
var can_attack := true
var is_attacking := false

func _ready() -> void:
	animation.play("idle_front")
	add_child(attack_timer)
	attack_timer.one_shot = true
	attack_timer.wait_time = ATTACK_COOLDOWN
	attack_timer.connect("timeout", _on_attack_cooldown_timeout)
	animation.connect("animation_finished", _on_animation_finished)

func _physics_process(delta: float) -> void:
	if is_attacking: 
		move_and_slide()
		return
		
	if Input.is_action_just_pressed("attack") and can_attack:
		perform_attack()
	else: 
		directional_Movement()
		move_and_slide()

func directional_Movement():
	if is_attacking:
		return
	
	var direction := Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	)
	
	if direction.length() > 0:
		direction = direction.normalized()
		velocity = direction * SPEED
		handle_Animations(direction)
	else:
		velocity = Vector2.ZERO
		handle_Animations(Vector2.ZERO)

func handle_Animations(direction: Vector2):
	if is_attacking:
		return
	
	if direction == Vector2.ZERO:
		animation.play("idle_" + last_direction)
	else: 
		if abs(direction.x) > abs(direction.y):
			last_direction = "right_side" if direction.x > 0 else "left_side"
		else:
			last_direction = "front" if direction.y > 0 else "back"
				
		animation.play("walk_" + last_direction)

func perform_attack():
	can_attack = false
	is_attacking = true 
	
	# Mueve el Area2D según dirección
	match last_direction:
		"front":
			attack_area.position = Vector2(0, 16)
		"back": 
			attack_area.position = Vector2(-0, -32)
		"left_side":
			attack_area.position = Vector2(-16, -8)
		"right_side":
			attack_area.position = Vector2(16, -8)
	
	# Activa el área
	attack_area.monitoring = true
	attack_area.set_deferred("collision_layer", 1)

	animation.flip_h = (last_direction == "right_side")
	animation.play("attack_" + last_direction)

	await get_tree().create_timer(0.05).timeout
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			body.take_damage(DAMAGE)
			print("¡Golpe a: ", body.name, "!")

	attack_timer.start()

func _on_attack_cooldown_timeout():
	can_attack = true

func _on_animation_finished():
	if is_attacking:
		is_attacking = false
		attack_area.monitoring = false
		attack_area.set_deferred("collision_layer", 0)
		animation.flip_h = false
		animation.play("idle_" + last_direction)
		
func take_damage(amount: float):
	print("el jugador recibio dano, ", amount, " de dano")
	
