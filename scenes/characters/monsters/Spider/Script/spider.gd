extends CharacterBody2D

# Stats base 
@export var max_health: float = 25.0
@export var armor: float = 2.0  # reducción plana de daño (ejemplo: cada golpe resta 2)
@export var xp_reward_range := Vector2i(12, 21) # XP que da al morir
@export var drop_item: Resource = preload("res://items/resources/ArmorSpider.tres") # cambia al item real

var current_health: float
var has_died: bool = false

@export var move_speed: float = 40.0
@export var change_dir_time: float = 7.0
@export var damage: float = 6.0
@export var enemy_scale: float = 1.0

var direction: Vector2 = Vector2.ZERO

@onready var anim = $AnimatedSprite2D
@onready var dir_timer: Timer = Timer.new()
@onready var detect_area = $Area2D_Detect
@onready var chase_area = $Area2D_Chase
@onready var attack_area = $Area2_Attack
@onready var attack_timer = $Timer_AttackCooldown
@onready var health_bar = $TextureProgressBar
@onready var sfx_hit = $AudioStreamPlayer2D

# Controles con el jugador
var is_player_near: bool = false
var is_chasing = false
var player_ref = null
var is_attacking = false

func _ready() -> void:
	scale = Vector2.ONE * enemy_scale
	current_health = max_health
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.visible = false
	
	#Timer para cambiar la direccion 
	dir_timer.wait_time = change_dir_time
	dir_timer.one_shot = false
	dir_timer.timeout.connect(_on_change_direction)
	add_child(dir_timer)
	dir_timer.start()
	
	#Conectar senales del area
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
	
	_on_change_direction() # Escoger la primera direccion del inicio

func _physics_process(delta: float) -> void:
	if has_died:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if is_attacking:
		velocity = Vector2.ZERO
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


func _on_change_direction() -> void:
	# Escoger nueva dirección aleatoria cardinal (arriba, abajo, izq, der)
	var dirs = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	direction = dirs.pick_random()
	_update_animation()

func _update_animation() -> void:
	if direction == Vector2.ZERO:
		return
	
	if abs(direction.x) > abs(direction.y):
		# Se mueve más horizontal que vertical
		if direction.x > 0:
			anim.play("walk_right_side")
		else:
			anim.play("walk_left_side")
	else:
		# Se mueve más vertical que horizontal
		if direction.y > 0:
			anim.play("walk_front")
		else:
			anim.play("walk_back")


# === Bloque para detectar al jugador ===

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
			
# === Bloque para detectar al jugador ===

# === Bloque para empezar persecucion ===

func _on_area_2d_chase_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_chasing = true
		player_ref = body
		dir_timer.stop()


func _on_area_2d_chase_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_chasing = false
		player_ref = null
		# Si el jugador aún está en el área de detección → quieto
		# Si no está → retomar movimiento normal
		if not is_player_near:
			dir_timer.start()
			_on_change_direction()

# === Bloque para empezar persecucion ===

# === Bloque para empezar ataques ===

func _on_area_2_attack_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_attacking:
		_start_attack()


func _on_area_2_attack_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		# No atacamos si ya salió del área
		pass

func _start_attack() -> void:
	is_attacking = true
	velocity = Vector2.ZERO

	# Animación de ataque según dirección actual
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			anim.play("attack_right_side")
		else:
			anim.play("attack_left_side")
	else:
		if direction.y > 0:
			anim.play("attack_front")
		else:
			anim.play("attack_back")

	attack_timer.start()

func _on_attack_cooldown_finished() -> void:
	is_attacking = false

	# Si el jugador sigue en área de ataque, volver a atacar
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			_start_attack()
			return

# === Bloque para empezar ataques ===

func _on_animated_sprite_2d_animation_changed() -> void:
	# Solo hacer chequeo si está atacando
	if is_attacking:
		# frame 3 del ataque
		if anim.frame == 3:
			_apply_attack_damage()

func _apply_attack_damage() -> void:
	var hit := false
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			hit = true
			if body.has_method("take_damage"):
				body.take_damage(damage, "fisico")
				print("🕷️ Araña hizo daño:", damage)
			break
	
	if not hit:
		print("❌ Golpe fallido")


# === Control de dano a la arana ===

func _take_damage(amount: float) -> void:
	sfx_hit.play()
	
	if has_died:
		return

	# Reducción por la coraza
	var final_damage = max(amount - armor, 0)
	current_health = max(current_health - final_damage, 0)

	print("🛡️ Araña recibió:", amount, " | Reducción:", armor, " | Final:", final_damage, " | HP restante:", current_health)

	# Actualizar barra de vida
	health_bar.value = current_health
	health_bar.show_for_a_while()

	# Animación de golpe
	if anim.sprite_frames.has_animation("hurt_front"):
		anim.play("hurt_front")

	if current_health <= 0:
		_die()


func _die() -> void:
	if has_died:
		return

	has_died = true
	is_attacking = false
	is_chasing = false
	is_player_near = false
	velocity = Vector2.ZERO

	# Bloquear sus áreas
	detect_area.monitoring = false
	chase_area.monitoring = false
	attack_area.monitoring = false

	# Reproducir animación de muerte (solo hay una)
	if anim.sprite_frames.has_animation("dying"):
		anim.play("dying")
	else:
		queue_free()  # fallback por si no existe

func _on_animated_sprite_2d_animation_finished() -> void:
	if has_died and anim.animation == "dying":
		# Drop de ítem
		if drop_item:
			var pickup_scene = preload("res://scenes/World_pick-Ups/pick_ups_items.tscn")
			var pickup = pickup_scene.instantiate()
			pickup.item_data = preload("res://items/resources/ArmorSpider.tres")
			pickup.amount = 1
			pickup.global_position = global_position
			get_tree().current_scene.add_child(pickup)

		# Dar experiencia al jugador
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("gain_experience"):
			var xp = randi_range(xp_reward_range.x, xp_reward_range.y)
			player.gain_experience(xp)
			print("🎁 Jugador ganó", xp, "XP por matar a la Araña Coraza")

		queue_free()
