extends Node
class_name AutonomousMovementController

@export var speed: float = 40.0
@export var move_time_range := Vector2(1.5, 3.5)
@export var idle_time_range := Vector2(1.0, 2.5)

@export var animated_sprite: AnimatedSprite2D
## Asignar directamente el AnimatedSprite2D desde el Inspector


var owner_body: CharacterBody2D
var anim: AnimatedSprite2D

var last_direction := "front"
var current_direction := Vector2.ZERO
var is_moving := false
var state_timer := 0.0


func _ready() -> void:
	owner_body = get_parent() as CharacterBody2D
	assert(owner_body != null, "AutonomousMovementController debe ser hijo de CharacterBody2D")

	anim = animated_sprite
	assert(anim != null, "AnimatedSprite2D no asignado al controlador")

	randomize()
	_pick_new_state()


func physics_update(delta: float) -> void:
	state_timer -= delta

	if state_timer <= 0:
		_pick_new_state()

	owner_body.velocity = current_direction * speed if is_moving else Vector2.ZERO
	owner_body.move_and_slide()
	_update_animation()


func _pick_new_state() -> void:
	is_moving = randf() > 0.35

	if is_moving:
		current_direction = _get_random_direction()
		state_timer = randf_range(move_time_range.x, move_time_range.y)
	else:
		current_direction = Vector2.ZERO
		state_timer = randf_range(idle_time_range.x, idle_time_range.y)


func _get_random_direction() -> Vector2:
	return [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT].pick_random()


func _update_animation() -> void:
	if owner_body.velocity.length() < 0.05:
		anim.play("idle_" + last_direction)
		return

	if abs(owner_body.velocity.x) > abs(owner_body.velocity.y):
		last_direction = "right_side" if owner_body.velocity.x > 0 else "left_side"
	else:
		last_direction = "front" if owner_body.velocity.y > 0 else "back"

	anim.play("walk_" + last_direction)
