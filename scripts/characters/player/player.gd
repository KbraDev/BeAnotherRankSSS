extends CharacterBody2D

const SPEED = 160.0
const DAMAGE = 3.0
var can_move = true

enum PlayerState { unarmed, armed, bow }
var current_state: PlayerState = PlayerState.unarmed

@onready var attack_area = $attack_area
@onready var animation = $AnimatedSprite2D
@onready var attack_timer = Timer.new()
@onready var combo_timer = Timer.new()
@onready var camera = $Camera2D

var mana = 10
var level = 1

var last_direction := "front"
var can_attack := true
var is_attacking := false
var attack_click_count := 0
var current_attack := 1

#Variables para el dash
var is_dashing: bool = false
var dash_speed := 400.0
var dash_duration := 0.3
var dash_cooldown := 2.0
var can_dash := true

@onready var dash_timer := Timer.new()
@onready var dash_cooldown_timer := Timer.new()

#capas originales
var original_layer := 2 | 3  # ambiente (2) + enemigos (3)
var original_mask := 1 | 2   # recibe de ambiente (1) + enemigos (2)

# Inventario
const INVENTORY_ROWS := 3
const INVENTORY_COLS := 5
const INVENTORY_SIZE := INVENTORY_COLS * INVENTORY_ROWS

var inventory: Array = []

# Health vars
var current_health = 50
var max_health = 50

# checkPoint vars
var last_checkpoint_id: String = ""
var last_checkpoint_scene: String = ""
var respawn_pending_checkpoint_id: String = ""



## Signals
signal inventory_updated(inventory: Array)
signal health_changed(current_health, max_health)

## FUNCIONES

func _ready():
	print("MissionTracker cargado?", MissionTracker)
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
	
	# timers de dash
	add_child(dash_timer)
	dash_timer.one_shot = true
	dash_timer.wait_time = dash_duration
	dash_timer.connect("timeout", _on_dash_finished)

	add_child(dash_cooldown_timer)
	dash_cooldown_timer.one_shot = true
	dash_cooldown_timer.wait_time = dash_cooldown
	dash_cooldown_timer.connect("timeout", _on_dash_cooldown_finished)

	# Señal de animación
	animation.connect("animation_finished", _on_animation_finished)
	
	inventory.resize(INVENTORY_SIZE)
	for i in range(INVENTORY_SIZE):
		inventory[i] = null
	
	print(inventory)
	emit_signal("health_changed", current_health, max_health)

func _physics_process(delta: float) -> void:
	handle_state_input()

	# Movimiento
	directional_movement()
	move_and_slide()

	# Ataque solo si está armado
	if Input.is_action_just_pressed("attack") and can_attack and current_state == PlayerState.armed:
		attack_click_count += 1

	# Solo atacar si hay clics acumulados y no estás atacando ahora
	if attack_click_count > 0 and not is_attacking and can_attack and current_state == PlayerState.armed:
		velocity = Vector2.ZERO
		perform_attack()
		
	if Input.is_action_just_pressed("dash_action") and can_dash and not is_dashing:
		start_dash()


func handle_state_input():
	if Input.is_action_just_pressed("1"):
		current_state = PlayerState.unarmed
	elif Input.is_action_just_pressed("2"):
		current_state = PlayerState.armed
	elif Input.is_action_just_pressed("3"):
		current_state = PlayerState.bow
		print("🔄 Estado cambiado a: Arco (WIP)")

func directional_movement():
	# Solo bloquea el movimiento normal del jugador, no afecta el dash
	if not can_move or is_attacking or is_dashing:
		if not is_dashing:
			velocity = Vector2.ZERO
		return

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
		
	animation.play(animation_name)

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

	attack_timer.start()
	combo_timer.start()


func _on_attack_cooldown_timeout():
	can_attack = true


func _on_combo_timer_timeout():
	attack_click_count = 0
	current_attack = 1


func _on_animation_finished():

	if is_attacking:
		is_attacking = false
		attack_area.monitoring = false
		attack_area.set_deferred("collision_layer", 0)
		animation.flip_h = false

		if attack_click_count > 1 and current_attack == 1:
			current_attack = 2
			attack_click_count = 1
			perform_attack()
			return

		current_attack = 1
		attack_click_count = 0
		handle_Animations(Vector2.ZERO)

func start_dash():
	is_dashing = true
	can_dash = false
	
	# invulnerable
	# Quitar solo capa/máscara de enemigos
	set_collision_layer(2)  # solo ambiente
	set_collision_mask(1)   # solo recibe de ambiente
	
	# Direccion del dash basada en last direcion
	match last_direction:
		"front": velocity = Vector2(0, 1)
		"back": velocity = Vector2(0, -1)
		"left_side": velocity = Vector2(-1, 0)
		"right_side": velocity = Vector2(1, 0)

	velocity = velocity.normalized() * dash_speed
	
	# Animacion
	animation.play("dash_" + last_direction)
	
	dash_timer.start()
	dash_cooldown_timer.start()

func _on_dash_finished():
	is_dashing = false
	velocity = Vector2.ZERO
	
	#restaurar colisiones
	set_collision_layer(original_layer)
	set_collision_mask(original_mask)

func _on_dash_cooldown_finished():
	can_dash = true

func take_damage(amount: float):
	current_health = max(current_health - amount, 0)
	emit_signal("health_changed", current_health, max_health)
	print("🩸 El jugador recibió", amount, "de daño.")

	if current_health == 0:
		die()
		return

	# Animación de recibir daño
	if not is_attacking and not is_dashing:
		var prefix := ""
		match current_state:
			PlayerState.armed:
				prefix = "sword_"
			PlayerState.bow:
				prefix = "bow_"
			PlayerState.unarmed:
				prefix = ""

		var anim_name = prefix + "take_damage_" + last_direction
		if animation.sprite_frames.has_animation(anim_name):
			animation.play(anim_name)




func add_item_to_inventory(item_data: ItemData, amount: int = 1) -> bool:
	var remaining := amount

	# 1. Apilar en slots existentes
	for slot in inventory:
		if slot != null and slot.item_data == item_data:
			var space_left = item_data.max_stack - slot.amount
			var to_add = min(space_left, remaining)
			slot.amount += to_add
			remaining -= to_add
			if remaining <= 0:
				break

	# 2. Usar slots vacíos
	if remaining > 0:
		for i in inventory.size():
			if inventory[i] == null:
				var to_add = min(item_data.max_stack, remaining)
				inventory[i] = {
					"item_data": item_data,
					"amount": to_add
				}
				remaining -= to_add
				if remaining <= 0:
					break

	# 3. Resultado
	if remaining > 0:
		print("⚠️ Inventario lleno. No se pudo recoger: ", remaining, " x ", item_data.item_name)
		return false
	else:
		print("✔️ Agregado: ", amount, " x ", item_data.item_name)
		print(inventory)
		return true
	
	emit_signal("inventory_updated", inventory)
	
func die():
	can_move = false
	can_attack = false
	is_attacking = false
	is_dashing = false
	velocity = Vector2.ZERO

	set_collision_layer(0)
	set_collision_mask(0)
	# Prefijo según estado
	var prefix := ""
	match current_state:
		PlayerState.armed:
			prefix = "sword_"
		PlayerState.bow:
			prefix = "bow_"
		PlayerState.unarmed:
			prefix = ""

	var anim_name = prefix + "death_" + last_direction

	if animation.sprite_frames.has_animation(anim_name):
		animation.play(anim_name)
	else:
		print("⚰️ Animación de muerte no encontrada:", anim_name)
		
	# set zoom
	var tween := get_tree().create_tween()
	tween.tween_property(camera, "zoom", Vector2(2.7, 2.7), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await tween.finished
	_on_zoom_finished()
	# Opcional: después de morir, eliminar al jugador o dejarlo quieto
	# queue_free()  # si querés eliminarlo

func _on_zoom_finished():
	print("🔍 Buscando world_manager...")
	var wm := get_tree().get_first_node_in_group("world_manager")

	if wm and last_checkpoint_scene != "":
		print("✅ WorldManager encontrado, haciendo fade")
		wm.change_world(last_checkpoint_scene, "")
		await get_tree().process_frame

		# Esperar a que se registre el checkpoint correspondiente
		respawn_pending_checkpoint_id = last_checkpoint_id
		await _wait_for_checkpoint()
	else:
		print("⚠️ No se pudo cargar la escena del checkpoint")
		global_position = Vector2.ZERO

	# Restaurar estado del jugador
	current_health = max_health
	emit_signal("health_changed", current_health, max_health)
	can_move = true
	can_attack = true
	is_attacking = false
	is_dashing = false
	set_collision_layer(original_layer)
	set_collision_mask(original_mask)

	camera.zoom = Vector2(1.5, 1.5)
	animation.play("idle_" + last_direction)

	if wm:
		wm.transition_anim.play("fade_in")



func update_checkpoint(checkpoint_id: String):
	last_checkpoint_id = checkpoint_id

	var wm := get_tree().get_first_node_in_group("world_manager")
	if wm and wm.current_world:
		last_checkpoint_scene = wm.current_world.scene_file_path
	else:
		print("⚠️ No se pudo determinar la escena del checkpoint")

	print("📍 Checkpoint actualizado:", checkpoint_id)
	print("🎬 Escena del checkpoint:", last_checkpoint_scene)

func find_checkpoint_by_id(id: String) -> Node:
	var checkpoints = get_tree().get_nodes_in_group("checkpoint")
	for cp in checkpoints:
		if cp.checkpoint_id == id:
			return cp
	print("❌ No se encontró el checkpoint con ID:", id)
	return null

func _wait_for_checkpoint():
	var max_wait_time := 3.0  # por si algo se rompe, no esperar eternamente
	var elapsed := 0.0
	while elapsed < max_wait_time:
		await get_tree().process_frame
		var checkpoint = CheckPointRegistry.get_checkpoint(respawn_pending_checkpoint_id)
		if checkpoint:
			global_position = checkpoint.global_position
			print("✅ Respawneado en checkpoint:", respawn_pending_checkpoint_id)
			respawn_pending_checkpoint_id = ""
			return
		elapsed += get_process_delta_time()
	print("❌ Timeout esperando al checkpoint:", respawn_pending_checkpoint_id)

## func para guardar estado
func get_save_data() -> Dictionary:
	var inv := []
	for item in inventory:
		if item != null:
			inv.append({
				"item_name": item.item_data.item_name,
				"amount": item.amount
			})
		else:
			inv.append(null)

	return {
		"position": global_position,
		"hp": current_health,
		"max_hp": max_health,
		"mana": mana,
		"level": level, 
		"inventory": inv,
		"player_state": current_state,
		"last_checkpoint_id": last_checkpoint_id,
		"last_checkpoint_scene": last_checkpoint_scene
	}
