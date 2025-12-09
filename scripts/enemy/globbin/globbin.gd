extends Enemy
class_name Globbin

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_check = $CollisionCheck
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea
@onready var brake_area = $BrakeArea  # 🚦 área de frenado

@export var damage: float = 4.0  # 💥 daño base del Globbin
@export var rush_damage: float = 0.0

# SFX
@onready var start_chase_sfx = $StartChase
@onready var attack_sfx = $Attack
@onready var hurt_sfx = $Hurt
@onready var rush_sfx = $Rush

var can_move: bool = true
var direction: Vector2 = Vector2.ZERO
var last_direction: String = "front"

var player_detected = false
var player_target: Node2D = null
var is_attacking: bool = false
var player_in_attack_range: bool = false
var player_in_brake_range: bool = false

enum State {IDLE, CHASE, ATTACK, HURT, RUSH}
var current_state: State = State.IDLE

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
		
	# Si no configuraste rush_damage en el inspector, le damos un valor por defecto:
	if rush_damage <= 0.0:
		rush_damage = damage * 1.75  # ejemplo: 175% del daño normal
	
	rush_check_timer = Timer.new()
	rush_check_timer.wait_time = 2.5
	rush_check_timer.autostart = true
	rush_check_timer.one_shot = false
	rush_check_timer.timeout.connect(_on_rush_check_timeout)
	add_child(rush_check_timer)

func _physics_process(delta):
	if has_died:
		return

	# --- PRIORIDAD: si está siendo empujado, procesar knockback primero ---
	if is_being_pushed:
		# mover usando la velocity que puso apply_knockback()
		move_and_slide()
		return

	# Si está en hurt → detener IA (pero ya NO bloquea el knockback, porque lo procesamos arriba)
	if is_hurt:
		return

	# Si está en rush
	if is_rushing:
		_process_rush(delta)
		return

	# IA normal
	if player_detected and player_target:
		_chase_player(delta)
	else:
		_patrol(delta)


# ===========================
# == Patrullaje ==
# ===========================

# ---------------------------------------------------------
# _choose_new_direction()
# Selecciona aleatoriamente una dirección de movimiento 
# (arriba, abajo, izquierda, derecha) para el patrullaje.
# Actualiza también el "last_direction" para animaciones.
# ---------------------------------------------------------
func _choose_new_direction() -> void:
	var dirs = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	direction = dirs.pick_random()

	match direction:
		Vector2.LEFT: last_direction = "left_side"
		Vector2.RIGHT: last_direction = "right_side"
		Vector2.UP: last_direction = "back"
		Vector2.DOWN: last_direction = "front"

# ---------------------------------------------------------
# _patrol(delta)
# Movimiento base del Globbin cuando no detecta al jugador.
# Se mueve en línea recta y ocasionalmente cambia dirección.
# Usa move_and_slide() y reproduce animación de caminar.
# ---------------------------------------------------------
func _patrol(delta: float) -> void:
	#print("👣 [Globbin] PATROL - Sobrescribiendo velocity:", velocity)
	velocity = direction * move_speed
	move_and_slide()
	_play_walk_animation()

	if randi() % 100 == 0:
		_choose_new_direction()

# ===========================
# == Detección del jugador ==
# ===========================
# ---------------------------------------------------------
# _on_detection_area_body_entered(body)
# Activa el estado de persecución cuando el jugador entra 
# en el área de detección. Guarda la referencia al jugador.
# ---------------------------------------------------------
func _on_detection_area_body_entered(body: Node) -> void:
	if not body or not body.is_in_group("player"):
		return
	player_detected = true
	player_target = body
	print("Jugador detectado")
	start_chase_sfx.play()

# ---------------------------------------------------------
# _on_detection_area_body_exited(body)
# El jugador salió del área de detección, así que el Globbin
# vuelve a patrullar y limpia la referencia al objetivo.
# ---------------------------------------------------------
func _on_detection_area_body_exited(body: Node) -> void:
	if not body or not body.is_in_group("player"):
		return
	player_detected = false
	player_target = null
	print("Jugador fuera de rango")

# ===========================
# == Persecución ==
# ===========================

# ---------------------------------------------------------
# _chase_player(delta)
# IA de persecución: el Globbin corre hacia el jugador.
# Si el jugador está en "brake range", el Globbin se detiene.
# Actualiza dirección, velocidad y reproduce animación.
# ---------------------------------------------------------
func _chase_player(delta: float) -> void:
	#print("🏃 [Globbin] CHASE - Sobrescribiendo velocity a:", direction * (move_speed * 1.5))
	if player_in_brake_range:
		velocity = Vector2.ZERO
		return  # 🚦 Detiene movimiento cuando está en rango de frenado

	var to_player = (player_target.global_position - global_position).normalized()
	direction = to_player
	last_direction = _get_cardinal_direction(direction)

	velocity = direction * (move_speed * 1.5)
	move_and_slide()
	_play_run_animation()

# ---------------------------------------------------------
# _get_cardinal_direction(vec)
# Convierte un vector de movimiento en una dirección 
# cardinal (front, back, left_side, right_side) para 
# elegir la animación correcta.
# ---------------------------------------------------------
func _get_cardinal_direction(vec: Vector2) -> String:
	if abs(vec.x) > abs(vec.y):
		return "right_side" if vec.x > 0 else "left_side"
	else:
		return "front" if vec.y > 0 else "back"

# ===========================
# == Áreas de ataque ==
# ===========================

# ---------------------------------------------------------
# _on_attack_area_body_entered(body)
# Detecta que el jugador está en rango de ataque.
# Se usa para iniciar ciclos de ataque continuo.
# ---------------------------------------------------------
func _on_attack_area_body_entered(body: Node) -> void:
	if not body or not body.is_in_group("player"):
		return
	player_in_attack_range = true
	print("🎯 Jugador en rango de ataque")

# ---------------------------------------------------------
# _on_attack_area_body_exited(body)
# El jugador sale del rango de ataque. 
# Detiene el ciclo de ataque continuo.
# ---------------------------------------------------------
func _on_attack_area_body_exited(body: Node) -> void:
	if not body or not body.is_in_group("player"):
		return
	player_in_attack_range = false
	print("💨 Jugador salió del rango de ataque")

# ===========================
# == Área de frenado ==
# ===========================

# ---------------------------------------------------------
# _on_brake_area_body_entered(body)
# Activa el freno del Globbin cuando está demasiado cerca 
# del jugador. Si también está en ataque range, inicia ataque.
# ---------------------------------------------------------
func _on_brake_area_body_entered(body: Node) -> void:
	if not body or not body.is_in_group("player"):
		return
	player_in_brake_range = true
	print("🚦 Jugador en rango de frenado")

	if player_in_attack_range and not is_attacking:
		_perform_attack(body)

# ---------------------------------------------------------
# _on_brake_area_body_exited(body)
# El jugador sale del rango de freno. 
# Globbin puede moverse nuevamente.
# ---------------------------------------------------------
func _on_brake_area_body_exited(body: Node) -> void:
	if not body or not body.is_in_group("player"):
		return
	player_in_brake_range = false
	print("🚶 Jugador salió del rango de frenado")

# ===========================
# == ATAQUE CONTINUO ==
# ===========================

# ---------------------------------------------------------
# _perform_attack(body)
# Ciclo de ataque automático mientras el jugador permanezca 
# en el área de ataque. Reproduce animaciones, inflige daño 
# cada cierto tiempo y se detiene si el jugador sale del rango 
# o si Globbin es herido.
# ---------------------------------------------------------
func _perform_attack(body: Node) -> void:
	if is_hurt or has_died:
		return

	is_attacking = true
	can_move = false
	velocity = Vector2.ZERO

	while player_in_attack_range and not has_died and is_attacking:

		_play_attack_animation()
		attack_sfx.play()

		await get_tree().create_timer(0.6).timeout
		if is_hurt or not is_attacking:
			break

		if attack_area.get_overlapping_bodies().has(body):
			_damage_player(body)
		
		await get_tree().create_timer(0.8).timeout
		if is_hurt or not is_attacking:
			break

	is_attacking = false
	can_move = true

# =============================
# == Aplicar daño al jugador ==
# =============================

# ---------------------------------------------------------
# _damage_player(body, use_rush_damage)
# Llama al método del jugador take_damage() y determina 
# si inflige daño normal o daño aumentado por Rush.
# También imprime logs útiles.
# ---------------------------------------------------------
func _damage_player(body: Node, use_rush_damage: bool = false) -> void:
	if not body or not body.is_in_group("player"):
		return

	if not body.has_method("take_damage"):
		print("⚠️ El jugador no tiene método take_damage()")
		return

	var applied_damage: float = damage
	if use_rush_damage:
		if rush_damage <= 0.0:
			applied_damage = damage * 1.5  # fallback: 150% si no se definió rush_damage
		else:
			applied_damage = rush_damage

	body.take_damage(applied_damage)

	# Log claro sin operador ternario
	if use_rush_damage:
		print("🩸 Daño infligido al jugador:", applied_damage, "(RUSH)")
	else:
		print("🩸 Daño infligido al jugador:", applied_damage, "(normal)")

# ================
# == Colisiones ==
# ================

# ---------------------------------------------------------
# _on_collision_check_body_entered(body)
# Detecta colisiones del Globbin con muros, objetos y 
# cuerpos válidos. Si el objeto es sólido, cambia 
# automáticamente de dirección para evitar quedar atorado.
# ---------------------------------------------------------
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

# ---------------------------------------------------------
# _play_walk_animation()
# Reproduce la animación de caminar según la última 
# dirección registrada. Verifica que exista la animación.
# ---------------------------------------------------------
func _play_walk_animation() -> void:
	if not sprite: return
	var anim_name = "walk_" + last_direction
	if sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name: sprite.play(anim_name)

# ---------------------------------------------------------
# _play_run_animation()
# Reproduce la animación de correr durante la persecución.
# Usa la dirección cardinal para elegir la animación.
# ---------------------------------------------------------
func _play_run_animation() -> void:
	if not sprite: return
	var anim_name = "run_" + last_direction
	if sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name: sprite.play(anim_name)

# ---------------------------------------------------------
# _play_attack_animation()
# Reproduce la animación de ataque correspondiente a la 
# última dirección. Incluye debug visual en consola.
# ---------------------------------------------------------
func _play_attack_animation() -> void:
	if not sprite: return
	var anim_name = "attack_" + last_direction
	if sprite.sprite_frames.has_animation(anim_name):
		print("🎬 Reproduciendo animación:", anim_name)
		sprite.play(anim_name)

# ---------------------------------------------------------
# _play_rush_animation()
# Reproduce la animación especial del ataque Rush.
# ---------------------------------------------------------
func _play_rush_animation() -> void:
	if not sprite:
		return
	var anim_name = "rush_" + last_direction
	if sprite.sprite_frames.has_animation(anim_name):
		print("🏃‍♂️ Reproduciendo animación:", anim_name)
		sprite.play(anim_name)


# ==================
# == Recibir daño ==
# ==================

# ---------------------------------------------------------
# _take_damage(amount, dir)
# Maneja la recepción de daño y delega al método padre.  
# El Globbin no añade lógica adicional aquí, solo hereda.
# ---------------------------------------------------------
func _take_damage(amount: float, dir: String = "front") -> void:
	super._take_damage(amount, last_direction)
	hurt_sfx.play()
	# Globbin no hace nada extra aquí


# =====================
# == Muerte direccional ==
# =====================
# ---------------------------------------------------------
# die(dir)
# Llama al método de muerte del padre con la animación 
# direccional correcta. Asegura que se use last_direction.
# ---------------------------------------------------------
func die(dir: String = "") -> void:
	if dir == "":
		dir = last_direction
	super.die(dir)


# ===========================
# == RUSH DESESPERADO ==
# ===========================
# ---------------------------------------------------------
# _on_rush_check_timeout()
# Cada cierto tiempo revisa si el Globbin debe activar Rush 
# según su vida actual. Probabilidad aumenta cada intento.
# ---------------------------------------------------------
var rush_attempts: int = 0
var is_rushing: bool = false
var rush_check_timer: Timer
var rush_target: Vector2 = Vector2.ZERO
var rush_speed: float = 0.0
var rush_cooldown_active: bool = false

func _on_rush_check_timeout() -> void:
	if has_died or is_attacking or is_rushing or rush_attempts >= 3:
		return
	if current_health > max_health * 0.4:
		return

	rush_attempts += 1
	var chance = 0.0

	match rush_attempts:
		1:
			chance = 0.33
		2:
			chance = 0.66
		3:
			chance = 0.999
		_:
			chance = 0.0

	if randf() < chance:
		print("💨 Rush activado! Intento:", rush_attempts, "Probabilidad:", chance)
		_start_rush()
	else:
		print("😤 Rush fallido. Intento:", rush_attempts, "Probabilidad:", chance)

# ---------------------------------------------------------
# _start_rush()
# Inicializa el ataque Rush: fija objetivo, velocidad 
# aumentada, dirección, animación y desactiva movilidad normal.
# ---------------------------------------------------------
func _start_rush() -> void:
	if not player_target or has_died:
		return

	is_rushing = true
	is_attacking = false
	can_move = false
	velocity = Vector2.ZERO

	var to_player = (player_target.global_position - global_position).normalized()
	last_direction = _get_cardinal_direction(to_player)

	rush_target = player_target.global_position + (to_player * 50.0)
	rush_speed = move_speed * 4.0

	_play_rush_animation()
	rush_sfx.play()
	print("💢 Globbin inicia RUSH hacia", rush_target)

# =========================
# == Procesamiento RUSH ==
# =========================
# ---------------------------------------------------------
# _process_rush(delta)
# Movimiento del Rush: avanza rápidamente hasta el objetivo 
# o impacta al jugador. Al llegar o golpear, termina el rush.
# ---------------------------------------------------------
func _process_rush(delta: float) -> void:
	var to_target: Vector2 = rush_target - global_position

	# llegó al objetivo sin impacto
	if to_target.length() < 10.0:
		print("🛑 Rush terminado sin impacto.")
		_end_rush()
		return

	# moverse hacia el objetivo
	direction = to_target.normalized()
	velocity = direction * rush_speed
	move_and_slide()

	# Colisión real con jugador (distancia de impacto)
	if player_target and global_position.distance_to(player_target.global_position) < 24.0:
		print("💥 Rush impacta al jugador!")
		_damage_player(player_target, true)  # usa daño de rush
		_end_rush()

# ---------------------------------------------------------
# _end_rush()
# Finaliza el estado Rush, activa una recuperación breve y 
# luego inicia un cooldown antes de permitir nuevos intentos.
# ---------------------------------------------------------
func _end_rush() -> void:
	is_rushing = false
	velocity = Vector2.ZERO

	await get_tree().create_timer(0.8).timeout
	can_move = true
	print("😮‍💨 Globbin se recupera del rush.")

	# 🔁 Reinicia el ciclo del rush después de 6s
	rush_attempts = 0
	rush_cooldown_active = true
	print("⏳ Iniciando cooldown de rush (6s)")
	await get_tree().create_timer(6.0).timeout
	rush_cooldown_active = false
	print("🎯 Rush listo para intentar de nuevo")

# ---------------------------------------------------------
# _on_enemy_hurt_end()
# Evento final de la animación de daño. Si el Globbin estaba
# atacando, detiene el ataque y le permite moverse de nuevo.
# ---------------------------------------------------------
func _on_enemy_hurt_end():
	# Si estaba atacando → cancelar
	if is_attacking:
		is_attacking = false
		can_move = true
