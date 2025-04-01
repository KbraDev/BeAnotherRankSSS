extends CharacterBody2D   ## Player


const SPEED = 150.0

@onready var animation = $AnimatedSprite2D

var last_direction := "front"

func _ready() -> void:
	animation.play("idle_front")

func _physics_process(delta: float) -> void:
	directional_Movement()
	move_and_slide()
	

func directional_Movement():
	var direction := Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	)
	
	# Si hay movimiento, normalizar y asignar velocidad
	if direction.length() > 0:
		direction = direction.normalized()
		velocity = direction * SPEED
		handle_Animations(direction) # Llama a la funcion para cambiar de direccion
	else:
		velocity = Vector2.ZERO
		handle_Animations(Vector2.ZERO) # Cambia animation a idle

func handle_Animations(direction: Vector2):
	if direction == Vector2.ZERO:
		animation.play("idle_" + last_direction) # Animacion en idle + la ultima direccion
	else: 
		if abs(direction.x) > abs(direction.y): # Direccion horizontal
			if direction.x > 0:
				last_direction = "right_side"
			else: 
				last_direction = "left_side"
		else: # Direccion vertical
			if direction.y > 0:
				last_direction = "front"
			else: 
				last_direction = "back"
				
		animation.play("walk_" + last_direction) # Aplica la animacion de caminar segun la direccion
		
func attack(event):
	if event.is_action_just_pressed("attack"):
		animation.play("attack_" + last_direction)
