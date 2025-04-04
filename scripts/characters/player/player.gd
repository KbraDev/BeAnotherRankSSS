extends CharacterBody2D   ## Player

const SPEED = 150.0
const ATTACK_COOLDOWN = 0.8 # Tiempo entre cada ataque

@onready var animation = $AnimatedSprite2D
@onready var attack_timer = Timer.new()

var last_direction := "front"
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
	# Si está atacando, no moverse
	if is_attacking: 
		velocity = Vector2.ZERO 
		move_and_slide()
		return
		
	if Input.is_action_just_pressed("attack") and can_attack:
		perform_attack()
	else: 
		directional_Movement()
		move_and_slide()

func directional_Movement():
	if is_attacking:
		return  # No moverse mientras ataca
	
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
		return  # No cambiar animación si está atacando
	
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
	
	if last_direction == "right_side":
		animation.flip_h = true 
		animation.play("attack_right_side")
	else: 
		animation.flip_h = false
		animation.play("attack_" + last_direction)
	
	attack_timer.start()
	print("ataque " + last_direction)

func _on_attack_cooldown_timeout():
	can_attack = true

func _on_animation_finished():
	if is_attacking:
		is_attacking = false
		animation.flip_h = false
		animation.play("idle_" + last_direction)
