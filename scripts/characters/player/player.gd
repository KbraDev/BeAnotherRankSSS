extends CharacterBody2D   # Player


const SPEED = 150.0

@onready var animation = $AnimatedSprite2D

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
		animation.play("idle_front") # Animacion en idle cuando no hay movimiento
	elif abs(direction.x) > abs(direction.y): # Movimiento horizontal
		if direction.x > 0: 
			animation.play("walk_rigth_side")
		else: 
			animation.play("walk_left_side")
	else: # Movimiento vertical
		if direction.y > 0:
			animation.play("walk_front")
		else:
			animation.play("walk_back")
