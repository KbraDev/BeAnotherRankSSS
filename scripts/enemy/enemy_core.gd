extends RefCounted
class_name EnemyCore

signal died(exp_reward)
signal damaged

var owner: CharacterBody2D

# Stats (SIN valores por defecto)
var max_health: float
var current_health: float
var armor := 0.0
var has_died := false

# Estado
var can_move := true
var is_hurt := false

# Knockback
var knockback_velocity := Vector2.ZERO
var knockback_friction := 1800.0

# EXP
var exp_reward: int = 0

func setup(_owner: CharacterBody2D, _max_health: float) -> void:
	owner = _owner
	max_health = _max_health
	current_health = max_health

	#collision: layer 2 + 3, mask 1 + 2
	owner.collision_layer = (1 << 1) | (1 << 2) # 6
	owner.collision_mask  = (1 << 0) | (1 << 1) # 3

func take_damage(amount: float) -> bool:
	if has_died:
		return true

	var final_damage = max(amount - armor, 0.0)
	current_health -= final_damage
	emit_signal("damaged")

	if current_health <= 0:
		_die()
		return true

	return false

func apply_knockback(direction: Vector2, force: float) -> void:
	knockback_velocity = direction.normalized() * force
	can_move = false
	is_hurt = true


func update_knockback(delta: float) -> bool:
	if knockback_velocity.length() <= 1.0:
		knockback_velocity = Vector2.ZERO
		can_move = true
		is_hurt = false
		return false

	knockback_velocity = knockback_velocity.move_toward(
		Vector2.ZERO,
		knockback_friction * delta
	)

	owner.velocity = knockback_velocity
	return true


func _die() -> void:
	if has_died:
		return

	has_died = true
	can_move = false
	is_hurt = false
	
	# Disable all collisions
	owner.collision_layer = 0
	owner.collision_mask = 0

	emit_signal("died", exp_reward)
