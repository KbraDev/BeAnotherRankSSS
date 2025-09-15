extends CharacterBody2D

@export var move_speed: float = 40.0
@export var change_dir_time: float = 7.0

var direction: Vector2 = Vector2.ZERO

@onready var anim = $AnimatedSprite2D
@onready var dir_timer: Timer = Timer.new()
@onready var detect_area = $Area2D_Detect

# Controles con el jugador
var is_player_near: bool = false

func _ready() -> void:
	#Timer para cambiar la direccion 
	dir_timer.wait_time = change_dir_time
	dir_timer.one_shot = false
	dir_timer.timeout.connect(_on_change_direction)
	add_child(dir_timer)
	dir_timer.start()
	
	#Conectar senales del area
	detect_area.body_entered.connect(_on_area_2d_detect_body_entered)
	detect_area.body_exited.connect(_on_area_2d_detect_body_exited)
	
	_on_change_direction() # Escoger la primera direccion del inicio

func _physics_process(delta: float) -> void:
	if not is_player_near:
		velocity = direction * move_speed
		move_and_slide()
		
		if get_slide_collision_count() > 0:
			direction = -direction
			_update_animation()
	else:
		velocity = Vector2.ZERO
		move_and_slide()

func _on_change_direction() -> void:
	# Escoger nueva dirección aleatoria cardinal (arriba, abajo, izq, der)
	var dirs = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	direction = dirs.pick_random()
	_update_animation()

func _update_animation() -> void:    
	# Escoge animación según la dirección
	if direction == Vector2.UP:
		anim.play("walk_back")
	elif direction == Vector2.DOWN:
		anim.play("walk_front")
	elif direction == Vector2.LEFT:
		anim.play("walk_left_side")
	elif direction == Vector2.RIGHT:
		anim.play("walk_right_side")


func _on_area_2d_detect_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"): 
		is_player_near = true
		dir_timer.stop()
		anim.stop()

func _on_area_2d_detect_body_exited(body: Node2D) -> void:
		if body.is_in_group("player"): 
			is_player_near = false
			dir_timer.start()
			_update_animation()
