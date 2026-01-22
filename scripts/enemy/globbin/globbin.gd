extends CharacterBody2D
class_name Globbin

# =========================
# CORE
# =========================
var enemy := EnemyCore.new()

# =========================
# NODES
# =========================
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_check = $CollisionCheck
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea
@onready var brake_area = $BrakeArea
@onready var health_bar: TextureProgressBar = $HealthBar


# =========================
# STATS
# =========================
@export var damage: float = 10.0
@export var move_speed: float = 45.0

# Drops
@export_group("Drops")
@export var pickup_scene: PackedScene
@export var drop_item: Resource
@export var drop_amount: int = 1

# SFX
@onready var start_chase_sfx = $StartChase
@onready var attack_sfx = $Attack
@onready var hurt_sfx = $Hurt

@export_group("Experience")
@export var exp_min: int = 20
@export var exp_max: int = 30

@export_group("Stats")
@export var max_health: float = 12.0
@export var enemy_armour = 0.0

# =========================
# STUN
# =========================
@export var stun_time := 0.5
var is_stunned := false

# =========================
# STATE
# =========================
var direction := Vector2.ZERO
var last_direction := "front"

var player_detected := false
var player_target: Node2D = null
var is_attacking := false
var player_in_attack_range := false
var player_in_brake_range := false

enum State { IDLE, CHASE, ATTACK, HURT }
var current_state := State.IDLE

var locked_by_event := true

var is_dead := false

# =====================
# READY
# =====================
func _ready() -> void:
	randomize()
	
	# 🔥 XP ALEATORIA (FALTABA ESTO)
	enemy.exp_reward = randi_range(exp_min, exp_max)

	enemy.setup(self, max_health, enemy_armour)
	sprite.frame_changed.connect(_on_attack_frame)
	enemy.damaged.connect(_on_enemy_damaged)
	enemy.died.connect(_on_enemy_died)
	sprite.animation_finished.connect(_on_attack_animation_finished)

	add_to_group("enemies")

	# 🔴 IMPORTANTE: desbloquear IA
	locked_by_event = false
	enemy.can_move = true
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

	if health_bar:
		health_bar.max_value = enemy.max_health
		health_bar.value = enemy.current_health
		health_bar.visible = false

# =========================
# PHYSICS
# =========================
func _physics_process(delta: float) -> void:
	if locked_by_event:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if enemy.has_died:
		return

	if enemy.update_knockback(delta):
		move_and_slide()
		return

	if enemy.is_hurt or not enemy.can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if is_stunned:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_enemy_ai(delta)
	move_and_slide()


# =========================
# AI
# =========================
func _enemy_ai(_delta: float) -> void:
	match current_state:
		State.HURT:
			velocity = Vector2.ZERO
			return

		State.ATTACK:
			velocity = Vector2.ZERO
			return

		State.CHASE:
			_chase_player()

		State.IDLE:
			if player_detected and player_target:
				current_state = State.CHASE
			else:
				_patrol()


# =========================
# PATROL
# =========================
func _choose_new_direction() -> void:
	var dirs = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	direction = dirs.pick_random()
	last_direction = _get_cardinal_direction(direction)

func _patrol() -> void:
	velocity = direction * move_speed
	_play_walk_animation()

	if randi() % 120 == 0:
		_choose_new_direction()

# =========================
# CHASE
# =========================
func _chase_player() -> void:
	if player_in_brake_range:
		velocity = Vector2.ZERO
		return

	if not player_target:
		return

	var to_player := (player_target.global_position - global_position).normalized()
	direction = to_player
	last_direction = _get_cardinal_direction(direction)

	velocity = direction * (move_speed * 1.5)
	_play_run_animation()


# =========================
# DETECTION
# =========================
func _on_detection_area_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_detected = true
		player_target = body
		start_chase_sfx.play()

func _on_detection_area_body_exited(body: Node) -> void:
	if body == player_target:
		player_detected = false
		player_target = null

# =========================
# ATTACK LOGIC
# =========================
func _on_attack_area_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_attack_range = true

func _on_attack_area_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_attack_range = false

func _on_brake_area_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_brake_range = true
		if not is_attacking:
			_perform_attack(body)

func _on_brake_area_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_brake_range = false

func _perform_attack(body: Node) -> void:
	if is_attacking or is_stunned or enemy.has_died:
		return

	current_state = State.ATTACK
	is_attacking = true
	enemy.can_move = false
	velocity = Vector2.ZERO

	_play_attack_animation()
	attack_sfx.play()


# =========================
# DAMAGE
# =========================
func take_damage(amount: float, dir: String = "front") -> void:

	last_direction = dir
	enemy.take_damage(amount)
	hurt_sfx.play()

	# 🔴 Liberar ataque SIEMPRE
	is_attacking = false
	enemy.can_move = true

	if player_target:
		var knockback_dir := (global_position - player_target.global_position).normalized()
		enemy.apply_knockback(knockback_dir, 200)

func _on_enemy_damaged() -> void:
	is_attacking = false
	enemy.can_move = false
	current_state = State.HURT

	if health_bar:
		health_bar.value = enemy.current_health
		health_bar.visible = true

	var anim := "hurt_" + last_direction
	if sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)

	_apply_stun()



# =========================
# DEATH
# =========================
func _on_enemy_died(exp_amount: int) -> void:
	is_dead = true

	if exp_amount > 0:
		var player := get_tree().get_first_node_in_group("player")
		if player and player.has_method("gain_experience"):
			player.gain_experience(exp_amount)

	velocity = Vector2.ZERO
	enemy.can_move = false
	is_attacking = false

	set_physics_process(false)
	set_process(false)

	if health_bar:
		health_bar.visible = false

	await _play_death_animation()
	_drop_item()
	await _fade_out()
	queue_free()


func _play_death_animation() -> void:
	var anim := "dying_" + last_direction
	if sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)
		await sprite.animation_finished

func _fade_out() -> void:
	var tween := get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.5)
	await tween.finished

# =========================
# DROP
# =========================
func _drop_item() -> void:
	if not pickup_scene or not drop_item:
		return

	var pickup := pickup_scene.instantiate()
	pickup.item_data = drop_item
	pickup.amount = drop_amount
	pickup.global_position = global_position

	get_tree().current_scene.add_child(pickup)

# =========================
# UTILS
# =========================
func _on_collision_check_body_entered(body: Node) -> void:
	if body.is_in_group("enemies") or body.is_in_group("player"):
		return
	_choose_new_direction()

func _get_cardinal_direction(vec: Vector2) -> String:
	if abs(vec.x) > abs(vec.y):
		return "right_side" if vec.x > 0 else "left_side"
	else:
		return "front" if vec.y > 0 else "back"

func _play_walk_animation():
	if is_dead:
		return
	sprite.play("walk_" + last_direction)

func _play_run_animation():
	if is_dead:
		return
	sprite.play("run_" + last_direction)

func _play_attack_animation():
	if is_dead:
		return
	sprite.play("attack_" + last_direction)


func _on_attack_frame():
	if not is_attacking:
		return

	if not sprite.animation.begins_with("attack_"):
		return

	var hit_frame := 3  # frame exacto del golpe

	if sprite.frame == hit_frame:
		_try_apply_damage()


func _try_apply_damage():
	if not player_target:
		return

	if attack_area.get_overlapping_bodies().has(player_target):
		if player_target.has_method("take_damage"):
			player_target.take_damage(damage)

func _on_attack_animation_finished() -> void:
	if is_dead:
		return

	# ===== FIN DE ATAQUE =====
	if sprite.animation.begins_with("attack_"):
		is_attacking = false
		enemy.can_move = true
		current_state = State.CHASE
		return

	# ===== FIN DE HURT =====
	if sprite.animation.begins_with("hurt_"):
		if enemy.has_died:
			return

		if player_detected and player_target:
			current_state = State.CHASE
			_play_run_animation()
		else:
			current_state = State.IDLE
			_play_walk_animation()


	if player_detected and player_target:
		_play_run_animation()
	else:
		_play_walk_animation()


func _apply_stun() -> void:
	if is_stunned or enemy.has_died:
		return

	is_stunned = true
	is_attacking = false
	enemy.can_move = false
	velocity = Vector2.ZERO

	await get_tree().create_timer(stun_time).timeout

	is_stunned = false
	enemy.can_move = true

	# 🔴 Forzar transición visual
	if enemy.has_died:
		return

	if player_detected and player_target:
		_play_run_animation()
	else:
		_play_walk_animation()
