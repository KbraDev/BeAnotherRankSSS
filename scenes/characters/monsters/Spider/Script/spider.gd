extends Enemy
## Araña Coraza — Enemigo con IA de persecución y ataque cuerpo a cuerpo

@export var change_dir_time: float = 7.0
@export var damage: float = 6.0
@export var enemy_scale: float = 1.0

var direction: Vector2 = Vector2.ZERO
var is_player_near := false
var is_chasing := false
var player_ref: Node2D = null
var is_attacking := false

@onready var anim = $AnimatedSprite2D
@onready var dir_timer: Timer = Timer.new()
@onready var detect_area = $Area2D_Detect
@onready var chase_area = $Area2D_Chase
@onready var attack_area = $Area2_Attack
@onready var attack_timer = $Timer_AttackCooldown
@onready var sfx_hit = $AudioStreamPlayer2D

func _ready() -> void:
	super._ready()
	enemy_name = "Araña Coraza"
	max_health = 25.0
	armor = 2.0
	move_speed = 40.0
	xp_reward_range = Vector2i(12, 21)
	drop_item = preload("res://items/resources/ArmorSpider.tres")

	scale = Vector2.ONE * enemy_scale
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = max_health
		health_bar.visible = false

	dir_timer.wait_time = change_dir_time
	dir_timer.timeout.connect(_on_change_direction)
	add_child(dir_timer)
	dir_timer.start()

	# Conectar áreas
	detect_area.body_entered.connect(_on_area_2d_detect_body_entered)
	detect_area.body_exited.connect(_on_area_2d_detect_body_exited)
	chase_area.body_entered.connect(_on_area_2d_chase_body_entered)
	chase_area.body_exited.connect(_on_area_2d_chase_body_exited)
	attack_area.body_entered.connect(_on_area_2_attack_body_entered)
	attack_area.body_exited.connect(_on_area_2_attack_body_exited)
	attack_timer.wait_time = 3.0
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_cooldown_finished)
	anim.frame_changed.connect(_on_animated_sprite_2d_animation_changed)

	_on_change_direction()

func _physics_process(delta: float) -> void:
	if has_died:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Si hay knockback activo, dejar que Enemy lo maneje
	if velocity.length() > 0.1:
		super._physics_process(delta)
		return

	if is_attacking and velocity.length() < 10.0:
		move_and_slide()
		return

	if is_chasing and player_ref:
		direction = (player_ref.global_position - global_position).normalized()
		velocity = direction * move_speed
		move_and_slide()
		_update_animation()
	elif not is_player_near:
		velocity = direction * move_speed
		move_and_slide()
		if get_slide_collision_count() > 0:
			direction = -direction
			_update_animation()
	else:
		velocity = Vector2.ZERO
		move_and_slide()

# === Movimiento / IA ===
func _on_change_direction():
	var dirs = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	direction = dirs.pick_random()
	_update_animation()

func _update_animation():
	if abs(direction.x) > abs(direction.y):
		anim.play("walk_right_side" if direction.x > 0 else "walk_left_side")
	else:
		anim.play("walk_front" if direction.y > 0 else "walk_back")

# === Detección del jugador ===
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

func _on_area_2d_chase_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_chasing = true
		player_ref = body
		dir_timer.stop()

func _on_area_2d_chase_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_chasing = false
		player_ref = null
		if not is_player_near:
			dir_timer.start()
			_on_change_direction()

# === Ataque ===
func _on_area_2_attack_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_attacking:
		_start_attack()
		
func _on_area_2_attack_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Aquí podrías poner algo como "cancelar ataque si el jugador sale del rango"
		pass

func _start_attack():
	is_attacking = true
	velocity = Vector2.ZERO
	if abs(direction.x) > abs(direction.y):
		anim.play("attack_right_side" if direction.x > 0 else "attack_left_side")
	else:
		anim.play("attack_front" if direction.y > 0 else "attack_back")
	attack_timer.start()

func _on_attack_cooldown_finished():
	is_attacking = false
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			_start_attack()
			return

func _on_animated_sprite_2d_animation_changed():
	if is_attacking and anim.frame == 3:
		_apply_attack_damage()

func _apply_attack_damage():
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(damage, "fisico")
			print("🕷️ Araña hizo daño:", damage)
			return

# === Muerte ===
func _on_animated_sprite_2d_animation_finished():
	if has_died and anim.animation == "dying":
		super._on_enemy_died()
