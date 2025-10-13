extends Enemy
class_name Globbin

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_check = $CollisionCheck
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea
@onready var brake_area = $BrakeArea  # 🚦 área de frenado

@export var damage: float = 4.0  # 💥 daño base del Globbin

var can_move: bool = true
var direction: Vector2 = Vector2.ZERO
var last_direction: String = "front"

var player_detected = false
var player_target: Node2D = null
var is_attacking: bool = false
var player_in_attack_range: bool = false
var player_in_brake_range: bool = false


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


func _physics_process(delta: float) -> void:
	if has_died:
		return

	if not can_move:
		return  # ⛔ Detenido por animación de ataque o daño

	if player_detected and player_target:
		_chase_player(delta)
	else:
		_patrol(delta)

# ===========================
# == Patrullaje ==
# ===========================

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

# ===========================
# == Detección del jugador ==
# ===========================

func _on_detection_area_body_entered(body: Node) -> void:
	if not body or not body.is_in_group("player"):
		return
	player_detected = true
	player_target = body
	print("Jugador detectado")

func _on_detection_area_body_exited(body: Node) -> void:
	if not body or not body.is_in_group("player"):
		return
	player_detected = false
	player_target = null
	print("Jugador fuera de rango")

# ===========================
# == Persecución ==
# ===========================

func _chase_player(delta: float) -> void:
	if player_in_brake_range:
		velocity = Vector2.ZERO
		return  # 🚦 Detiene movimiento cuando está en rango de frenado

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

# ===========================
# == Áreas de ataque ==
# ===========================

func _on_attack_area_body_entered(body: Node) -> void:
	if not body or not body.is_in_group("player"):
		return
	player_in_attack_range = true
	print("🎯 Jugador en rango de ataque")

func _on_attack_area_body_exited(body: Node) -> void:
	if not body or not body.is_in_group("player"):
		return
	player_in_attack_range = false
	print("💨 Jugador salió del rango de ataque")

# ===========================
# == Área de frenado ==
# ===========================

func _on_brake_area_body_entered(body: Node) -> void:
	if not body or not body.is_in_group("player"):
		return
	player_in_brake_range = true
	print("🚦 Jugador en rango de frenado")

	if player_in_attack_range and not is_attacking:
		_perform_attack(body)

func _on_brake_area_body_exited(body: Node) -> void:
	if not body or not body.is_in_group("player"):
		return
	player_in_brake_range = false
	print("🚶 Jugador salió del rango de frenado")

# ===========================
# == ATAQUE CONTINUO ==
# ===========================

func _perform_attack(body: Node) -> void:
	is_attacking = true
	can_move = false
	velocity = Vector2.ZERO

	print("⚔️ Globbin inicia bucle de ataque contra", body.name)

	while player_in_attack_range and not has_died:
		_play_attack_animation()
		print("🎬 Ataque ejecutado:", last_direction)

		await get_tree().create_timer(0.6).timeout

		if attack_area.get_overlapping_bodies().has(body):
			print("💥 Golpe exitoso sobre", body.name)
			_damage_player(body)
		else:
			print("❌ El jugador esquivó el ataque")

		await get_tree().create_timer(0.8).timeout

	print("🛑 Fin del bucle de ataque contra", body.name)
	can_move = true
	is_attacking = false

# =============================
# == Aplicar daño al jugador ==
# =============================

func _damage_player(body: Node) -> void:
	if not body or not body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
		print("🩸 Daño infligido al jugador:", damage)
	else:
		print("⚠️ El jugador no tiene método _take_damage()")

# ================
# == Colisiones ==
# ================

func _on_collision_check_body_entered(body: Node) -> void:
	if not body:
		return
	if body.is_in_group("enemies") or body.is_in_group("player"):
		return
	if body is TileMap or body.get_class() == "TileMapLayer":
		_choose_new_direction()
		return
	if body is PhysicsBody2D:
		var c_layer = body.get_collision_layer()
		var c_mask = body.get_collision_mask()
		var forbidden_layers = (1 << 2) | (1 << 3)
		var forbidden_masks = (1 << 0) | (1 << 1)
		if (c_layer & forbidden_layers) != 0 or (c_mask & forbidden_masks) != 0:
			return
		_choose_new_direction()
		return
	_choose_new_direction()

# =================
# == Animaciones ==
# =================

func _play_walk_animation() -> void:
	if not sprite: return
	var anim_name = "walk_" + last_direction
	if sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name: sprite.play(anim_name)

func _play_run_animation() -> void:
	if not sprite: return
	var anim_name = "run_" + last_direction
	if sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name: sprite.play(anim_name)

func _play_attack_animation() -> void:
	if not sprite: return
	var anim_name = "attack_" + last_direction
	if sprite.sprite_frames.has_animation(anim_name):
		print("🎬 Reproduciendo animación:", anim_name)
		sprite.play(anim_name)


# ==================
# == Recibir daño ==
# ==================

func _take_damage(amount: float, last_direciton: String = "front") -> void:
	# Llama al método del padre pero pasando la última dirección real
	super._take_damage(amount, last_direction)

# =====================
# == Muerte direccional ==
# =====================

func die(dir: String = "") -> void:
	if dir == "":
		dir = last_direction
	super.die(dir)
