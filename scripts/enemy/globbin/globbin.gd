extends Enemy
class_name Globbin

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_check = $CollisionCheck
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea
@onready var brake_area = $BrakeArea

@export var damage: float = 4.0

# SFX
@onready var start_chase_sfx = $StartChase
@onready var attack_sfx = $Attack
@onready var hurt_sfx = $Hurt

var direction: Vector2 = Vector2.ZERO
var last_direction: String = "front"

var player_detected: bool = false
var player_target: Node2D = null
var is_attacking: bool = false
var player_in_attack_range: bool = false
var player_in_brake_range: bool = false

enum State { IDLE, CHASE, ATTACK, HURT }
var current_state: State = State.IDLE

# =====================
# == Inicialización ==
# =====================

func _ready() -> void:
	super()
	randomize()
	_choose_new_direction()

	if collision_check:
		collision_check.body_entered.connect(_on_collision_check_body_entered)

	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)

	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_body_entered)
		attack_area.body_exited.connect(_on_attack_area_body_exited)

	if brake_area:
		brake_area.body_entered.connect(_on_brake_area_body_entered)
		brake_area.body_exited.connect(_on_brake_area_body_exited)

# =========================
# == Loop principal IA ==
# =========================

func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if has_died:
		return

	# Knockback tiene prioridad
	if is_being_pushed:
		move_and_slide()
		return

	if is_hurt:
		return

	if player_detected and player_target:
		_chase_player(delta)
	else:
		_patrol(delta)

# ===================
# == Patrullaje ==
# ===================

func _choose_new_direction() -> void:
	var dirs = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	direction = dirs.pick_random()

	match direction:
		Vector2.LEFT: last_direction = "left_side"
		Vector2.RIGHT: last_direction = "right_side"
		Vector2.UP: last_direction = "back"
		Vector2.DOWN: last_direction = "front"

func _patrol(delta: float) -> void:
	velocity = direction * move_speed
	move_and_slide()
	_play_walk_animation()

	if randi() % 100 == 0:
		_choose_new_direction()

# ======================
# == Detección ==
# ======================

func _on_detection_area_body_entered(body: Node) -> void:
	if body and body.is_in_group("player"):
		player_detected = true
		player_target = body
		start_chase_sfx.play()

func _on_detection_area_body_exited(body: Node) -> void:
	if body and body.is_in_group("player"):
		player_detected = false
		player_target = null

# ======================
# == Persecución ==
# ======================

func _chase_player(delta: float) -> void:
	if player_in_brake_range:
		velocity = Vector2.ZERO
		return

	var to_player = (player_target.global_position - global_position).normalized()
	direction = to_player
	last_direction = _get_cardinal_direction(direction)

	velocity = direction * (move_speed * 1.5)
	move_and_slide()
	_play_run_animation()

func _get_cardinal_direction(vec: Vector2) -> String:
	if abs(vec.x) > abs(vec.y):
		return "right_side" if vec.x > 0 else "left_side"
	else:
		return "front" if vec.y > 0 else "back"

# ======================
# == Áreas de ataque ==
# ======================

func _on_attack_area_body_entered(body: Node) -> void:
	if body and body.is_in_group("player"):
		player_in_attack_range = true

func _on_attack_area_body_exited(body: Node) -> void:
	if body and body.is_in_group("player"):
		player_in_attack_range = false

func _on_brake_area_body_entered(body: Node) -> void:
	if body and body.is_in_group("player"):
		player_in_brake_range = true
		if player_in_attack_range and not is_attacking:
			_perform_attack(body)

func _on_brake_area_body_exited(body: Node) -> void:
	if body and body.is_in_group("player"):
		player_in_brake_range = false

# ======================
# == Ataque continuo ==
# ======================

func _perform_attack(body: Node) -> void:
	if is_hurt or has_died:
		return

	is_attacking = true
	can_move = false
	velocity = Vector2.ZERO

	while player_in_attack_range and is_attacking and not has_died:

		_play_attack_animation()
		attack_sfx.play()

		await get_tree().create_timer(0.6).timeout
		if is_hurt:
			break

		if attack_area.get_overlapping_bodies().has(body):
			_damage_player(body)

		await get_tree().create_timer(0.8).timeout
		if is_hurt:
			break

	is_attacking = false
	can_move = true

# ======================
# == Daño al jugador ==
# ======================

func _damage_player(body: Node) -> void:
	if body and body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)

# ======================
# == Colisiones ==
# ======================

func _on_collision_check_body_entered(body: Node) -> void:
	if not body:
		return
	if body.is_in_group("enemies") or body.is_in_group("player"):
		return
	_choose_new_direction()

# ======================
# == Animaciones ==
# ======================

func _play_walk_animation() -> void:
	var anim = "walk_" + last_direction
	if sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)

func _play_run_animation() -> void:
	var anim = "run_" + last_direction
	if sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)

func _play_attack_animation() -> void:
	var anim = "attack_" + last_direction
	if sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)

# ======================
# == Recibir daño ==
# ======================

func _take_damage(amount: float, dir: String = "front") -> void:
	super._take_damage(amount, last_direction)
	hurt_sfx.play()

# ======================
# == Muerte ==
# ======================

func die(dir: String = "") -> void:
	if dir == "":
		dir = last_direction
	super.die(dir)

func _on_enemy_hurt_end():
	if is_attacking:
		is_attacking = false
		can_move = true
