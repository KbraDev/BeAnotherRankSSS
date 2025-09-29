extends CharacterBody2D

@export var walk_speed: float = 20.0
@export var display_speed: float = 5.0
@export var min_dir_time: int = 4
@export var max_dir_time: int = 9
@export var display_duration: float = 3.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $Area2D

enum State { WALK, DISPLAY }
var state: State = State.WALK

var direction := Vector2.ZERO
var direction_timer := 0.0
var direction_duration := 0.0
var display_timer := 0.0
var last_dir := Vector2.DOWN  # dirección inicial por defecto (hacia abajo)

func _ready():
	_set_new_direction()

func _physics_process(delta: float):
	match state:
		State.WALK:
			_process_walk_state(delta)
		State.DISPLAY:
			_process_display_state(delta)

func _process_walk_state(delta: float):
	direction_timer += delta
	if direction_timer >= direction_duration:
		_set_new_direction()

	velocity = direction * walk_speed
	move_and_slide()
	_update_animation(direction, false)

func _process_display_state(delta: float):
	display_timer += delta
	if display_timer >= display_duration:
		state = State.WALK
		_set_new_direction()
		return

	velocity = direction * display_speed
	move_and_slide()
	_update_animation(direction, true)

func _set_new_direction():
	direction_timer = 0.0
	direction_duration = randi_range(min_dir_time, max_dir_time)
	direction = Vector2(randf() - 0.5, randf() - 0.5).normalized()

func _update_animation(dir: Vector2, feathers_up: bool):
	# Si no hay dirección, usamos la última conocida
	if dir == Vector2.ZERO:    
		dir = last_dir
	else:
		last_dir = dir  # Guardamos la dirección actual como última conocida
	var anim_prefix = "walk_tail" if feathers_up else "walk"
	if abs(dir.x) > abs(dir.y):
		anim.play(anim_prefix + ("_right_side" if dir.x > 0 else "_left_side"))
	else:
		anim.play(anim_prefix + ("_front" if dir.y > 0 else "_back"))

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("peacock") or body.is_in_group("player"):
		state = State.DISPLAY
		display_timer = 0.0
		direction = Vector2.ZERO

func _on_area_2d_body_exited(body: Node2D) -> void:
	pass
