extends CharacterBody2D   # Player


const SPEED = 150.0

@onready var animation = $AnimatedSprite2D

func _ready() -> void:
	handle_Animations()

func _physics_process(delta: float) -> void:
	directional_Movement()
	move_and_slide()


func handle_Animations():
	animation.play("idle")
	


func directional_Movement():
	var direction := Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	)
	
	if direction.length() > 0: 
		direction = direction.normalized()
	
	velocity = direction * SPEED
	
