extends CharacterBody2D

const SPEED = 160.0
const DAMAGE = 3.0

enum PlayerState { unarmed, armed, bow }
var current_state: PlayerState = PlayerState.unarmed

@onready var attack_area = $attack_area
@onready var animation = $AnimatedSprite2D
@onready var attack_timer = Timer.new()
@onready var combo_timer = Timer.new()

var last_direction := "front"
var can_attack := true
var is_attacking := false
var attack_click_count := 0
var current_attack := 1


func _ready():
	animation.play("idle_" + last_direction)

	# Timers
	add_child(combo_timer)
	combo_timer.one_shot = true
	combo_timer.wait_time = 1.2
	combo_timer.connect("timeout", _on_combo_timer_timeout)

	add_child(attack_timer)
	attack_timer.one_shot = true
	attack_timer.wait_time = 0.4
	attack_timer.connect("timeout", _on_attack_cooldown_timeout)

	# Señal de animación
	animation.connect("animation_finished", _on_animation_finished)
	print("🎮 Ready. Animación actual:", animation.animation)


func _physics_process(delta: float) -> void:
	handle_state_input()

	# Movimiento
	directional_movement()
	move_and_slide()

	# Ataque solo si está armado
	if Input.is_action_just_pressed("attack") and can_attack and current_state == PlayerState.armed:
		print("🖱️ Ataque clic detectado")
		attack_click_count += 1

		if not is_attacking:
			print("🟢 Iniciando ataque")
			perform_attack()
		else:
			print("🟡 Clic adicional mientras ataca. Clics:", attack_click_count)


func handle_state_input():
	if Input.is_action_just_pressed("1"):
		current_state = PlayerState.unarmed
		print("🔄 Estado cambiado a: Desarmado")
	elif Input.is_action_just_pressed("2"):
		current_state = PlayerState.armed
		print("🔄 Estado cambiado a: Armado")
	elif Input.is_action_just_pressed("3"):
		current_state = PlayerState.bow
		print("🔄 Estado cambiado a: Arco (WIP)")


func directional_movement():
	var direction := Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	)

	if direction.length() > 0:
		direction = direction.normalized()
		velocity = direction * SPEED
	else:
		velocity = Vector2.ZERO

	handle_Animations(direction)


func handle_Animations(direction: Vector2):
	# Evitar sobrescribir animaciones de ataque
	if is_attacking:
		return

	var state_prefix := ""
	match current_state:
		PlayerState.unarmed:
			state_prefix = ""
		PlayerState.armed:
			state_prefix = "Sword_"
		PlayerState.bow:
			state_prefix = "Bow_"  # aún no implementado

	if direction == Vector2.ZERO:
		animation.play("idle_" + state_prefix + last_direction)
	else:
		if abs(direction.x) > abs(direction.y):
			last_direction = "right_side" if direction.x > 0 else "left_side"
		else:
			last_direction = "front" if direction.y > 0 else "back"

		animation.play("run_" + state_prefix + last_direction)


func perform_attack():
	if current_state != PlayerState.armed:
		print("❌ No se puede atacar: no estás armado.")
		return

	is_attacking = true
	can_attack = false

	var animation_name := ""
	var damage := 0

	if current_attack == 1:
		animation_name = "attack1_" + last_direction
		damage = 6
	elif current_attack == 2:
		animation_name = "attack2_" + last_direction
		damage = 8

	print("⚔️ Ejecutando ataque", current_attack, "- Animación:", animation_name)
	animation.play(animation_name)
	print("▶️ Animación activa:", animation.animation, "| Reproduciendo:", animation.is_playing())

	# Posicionar el área de ataque
	match last_direction:
		"front": attack_area.position = Vector2(0, 16)
		"back": attack_area.position = Vector2(-16, -32)
		"left_side": attack_area.position = Vector2(-32, -16)
		"right_side": attack_area.position = Vector2(32, -16)

	attack_area.monitoring = true
	attack_area.set_deferred("collision_layer", 1)

	await get_tree().create_timer(0.05).timeout

	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			body.take_damage(damage)
			print("💥 Golpe a:", body.name, "| Daño:", damage)

	attack_timer.start()
	combo_timer.start()


func _on_attack_cooldown_timeout():
	can_attack = true
	print("🕒 Cooldown terminado. Puedes atacar de nuevo.")


func _on_combo_timer_timeout():
	print("⏱️ Combo expirado. Reiniciando combo.")
	attack_click_count = 0
	current_attack = 1


func _on_animation_finished():
	print("🎞️ Animación finalizada:", animation.animation)

	if is_attacking:
		print("✅ Fin del ataque", current_attack)
		is_attacking = false
		attack_area.monitoring = false
		attack_area.set_deferred("collision_layer", 0)
		animation.flip_h = false

		if attack_click_count > 1 and current_attack == 1:
			current_attack = 2
			attack_click_count = 1
			print("🔁 Combo detectado. Iniciando ataque 2.")
			perform_attack()
			return

		current_attack = 1
		attack_click_count = 0
		handle_Animations(Vector2.ZERO)


func take_damage(amount: float):
	print("🩸 El jugador recibió", amount, "de daño.")
