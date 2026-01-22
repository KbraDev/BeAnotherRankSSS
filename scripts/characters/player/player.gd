extends CharacterBody2D

# ───── CONST Y ENUMS ─────
const SPEED = 160.0
const DAMAGE = 3.0
const INVENTORY_ROWS := 5
const INVENTORY_COLS := 6
const INVENTORY_SIZE := INVENTORY_COLS * INVENTORY_ROWS

# ----- XP vars -----
var experience := 0
var experience_to_next_level := 100
var stat_points := 0

# ───── STATS Y VARIABLES ─────
var base_stats := {
	"hp": 50,
	"speed": 130,
	"fuerza": 5,
	"mana": 10,
	"resistencia": 15,
	"resistencia_hechizos": 10,
	"poder_magico": 10,
	"lucky": 0
}

var stat_levels = {
	"hp": 1,
	"speed": 1,
	"fuerza": 1,
	"mana": 1,
	"resistencia": 1,
	"resistencia_hechizos": 1,
	"poder_magico": 1,
	"lucky": 1
}

var walk_speed = 50.0
var run_speed = 160.0
var is_running = false
var fuerza_jugador = base_stats ["fuerza"]

var can_move = true

var mana = 10
var level: int = 1

var current_health = 50
var max_health = 50

var inventory: Array = []

var last_direction := "front"

# Dash
var is_dashing: bool = false
var dash_speed := 400.0
var dash_duration := 0.3
var dash_cooldown := 2.0
var can_dash := true

# Colisiones originales
var original_layer := 2 | 3
var original_mask := 1 | 2

# Checkpoints
var last_checkpoint_id: String = ""
var last_checkpoint_scene: String = ""
var respawn_pending_checkpoint_id: String = ""

# SFX

# manejo de pisadas
var current_surface = "wood"
var step_timer := 0.0
var walk_interval := 0.7
var run_interval := 0.5

# Vars Slots Ability
@onready var basic_slot: AbilityCooldownSlot = $UIsContainer/BasicSlashSlot
@onready var double_slot: AbilityCooldownSlot = $UIsContainer/DoubleSlash


# ───── NODOS Y TIMERS ─────
@onready var attack_area = $attack_area
@onready var animation = $AnimatedSprite2D
@onready var camera = $Camera2D
@onready var footstep_player : AudioStreamPlayer = $FootstepPlayer
@onready var sword_hit = $SwordHit
@onready var attack0_voice = $Attack0
@onready var tilemap: TileMapLayer = get_tree().get_first_node_in_group("ground")

@onready var dash_timer := Timer.new()
@onready var dash_cooldown_timer := Timer.new()
@onready var attack_controller: PhisycAttackController = $PhysicAttackController


@onready var combo_timer := Timer.new()

var _hitbox_active := false
const BASIC_SLASH_ACTIVE_FRAMES := [0, 1, 2, 3]
const DOUBLE_SLASH_ACTIVE_FRAMES := [1, 2]

var _debug_hit_counter := {}

# ───── SEÑALES ─────
signal inventory_updated(inventory: Array)
signal health_changed(current_health, max_health)

# ───── READY ─────
func _ready():
	update_tilemap_reference()
	animation.play("idle_" + last_direction)


	add_child(dash_timer)
	dash_timer.one_shot = true
	dash_timer.wait_time = dash_duration
	dash_timer.connect("timeout", _on_dash_finished)

	add_child(dash_cooldown_timer)
	dash_cooldown_timer.one_shot = true
	dash_cooldown_timer.wait_time = dash_cooldown
	dash_cooldown_timer.connect("timeout", _on_dash_cooldown_finished)

	animation.frame_changed.connect(_on_animated_sprite_2d_frame_changed)
	
	attack_controller.attack_started.connect(_on_attack_started)
	attack_controller.attack_finished.connect(_on_attack_finished)
	attack_controller.attack_blocked.connect(_on_attack_blocked)
	attack_controller.enemy_hit.connect(_on_enemy_hit)

	basic_slot.cooldown_duration = attack_controller.basic_slash_cooldown
	double_slot.cooldown_duration = attack_controller.double_slash_cooldown

	inventory.resize(INVENTORY_SIZE)
	for i in range(INVENTORY_SIZE):
		inventory[i] = null

	stat_points = 0
	emit_signal("health_changed", current_health, max_health)
	
		# 🔹 Enlazar inventario automáticamente
	var inv = get_tree().get_first_node_in_group("inventory")
	if inv:
		inv.player = self
		#print("✅ Inventario vinculado al jugador correctamente.")
	else:
		pass
		#print("⚠️ No se encontró ningún inventario en el grupo 'inventory'.")



# ───── PROCESO Y ENTRADA ─────
func _physics_process(_delta: float) -> void:
	directional_movement()
	move_and_slide()

	# --- Detección de superficie bajo el jugador ---
	if tilemap:
		var cell: Vector2i = tilemap.local_to_map(global_position)
		var tile_data = tilemap.get_cell_tile_data(cell)
		if tile_data:
			var surface_type = tile_data.get_custom_data("surface_type")
			if surface_type:
				current_surface = surface_type

	# --- Dash ---
	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing:
		start_dash()

	# --- Menú de estadísticas ---
	_open_statUI()

func _input(event: InputEvent) -> void:
	if not can_move:
		return

	# BASIC SLASH
	if event.is_action_pressed("LeftClick"):
		attack_controller.request_basic_attack()

	# DOUBLE SLASH
	if event.is_action_pressed("RightClick"):
		attack_controller.request_double_attack()

func directional_movement():
	if not can_move or attack_controller.is_attacking() or is_dashing:
		if not is_dashing:
			velocity = Vector2.ZERO
		return

	var direction := Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	)

	if direction.length() > 0:
		direction = direction.normalized()

		# Detectar si corre (Ctrl) o camina
		is_running = Input.is_action_pressed("ctrl") # run_action = ctrl izq
		velocity = direction * (run_speed if is_running else walk_speed)

		handle_Animations(direction)
	else:
		velocity = Vector2.ZERO
		handle_Animations(Vector2.ZERO)
		
	if  direction != Vector2.ZERO:
		step_timer -= get_physics_process_delta_time()
		if step_timer <= 0.0:
			play_footstep()
			step_timer = run_interval if is_running else walk_interval
	else:
		step_timer = 0.0
 

# ───── COMBATE Y ANIMACIÓN ─────
func _on_attack_started(attack_id: int, hit_index: int) -> void:
	can_move = false

	match attack_id:
		PhisycAttackController.AttackType.BASIC_SLASH:
			animation.play("attack1_" + last_direction)
			sword_hit.play()
			attack0_voice.play()

		PhisycAttackController.AttackType.DOUBLE_SLASH:
			if hit_index == 1:
				animation.play("attack1_" + last_direction)
				sword_hit.play()
			elif hit_index == 2:
				animation.play("attack2_" + last_direction)
				sword_hit.play()
				
			attack0_voice.play()

func _on_enemy_hit(enemy: Node) -> void:
	if not enemy.has_method("take_damage"):
		print("[HIT] Nodo sin take_damage:", enemy.name)
		return

	var base_damage: float = base_stats["fuerza"]
	var final_damage: float = base_damage
	var attack_name := "NORMAL"

	if attack_controller.is_attacking():
		if attack_controller._current_attack == PhisycAttackController.AttackType.DOUBLE_SLASH \
		and attack_controller._current_hit == 2:
			final_damage = base_damage * 1.35
			attack_name = "DOUBLE_SLASH (2nd hit)"

	# 🔹 Dirección del golpe (player → enemy)
	var hit_dir_vector: Vector2 = global_position - enemy.global_position
	var hit_direction: String = _vector_to_direction(hit_dir_vector)

	# 🧪 DEBUG PRINT
	#print(
		#"[DAMAGE] Enemy:", enemy.name,
		#"| Attack:", attack_name,
		#"| Base:", base_damage,
		#"| Final:", final_damage,
		#"| Dir:", hit_direction
	#)

	enemy.take_damage(final_damage, hit_direction)
	
	if not _debug_hit_counter.has(enemy):
		_debug_hit_counter[enemy] = 0
	
	_debug_hit_counter[enemy] += 1
	print(
	"[HIT CONFIRMADO]",
	enemy.name,
	"| hits:", _debug_hit_counter[enemy]
)

func _vector_to_direction(dir: Vector2) -> String:
	if abs(dir.x) > abs(dir.y):
		return "right_side" if dir.x > 0 else "left_side"
	else:
		return "front" if dir.y > 0 else "back"

func handle_Animations(direction: Vector2):
	if attack_controller.is_attacking():
		return

	if direction == Vector2.ZERO:
		animation.play("idle_" + last_direction)
	else:
		last_direction = (
			"right_side" if direction.x > 0 else "left_side"
			if abs(direction.x) > abs(direction.y)
			else "front" if direction.y > 0 else "back"
		)

		if is_running:
			animation.play("run_" + last_direction)
		else:
			animation.play("walk_" + last_direction)

func _on_attack_finished(attack_id: int) -> void:
	match attack_id:
		PhisycAttackController.AttackType.BASIC_SLASH:
			basic_slot.start_cooldown()

		PhisycAttackController.AttackType.DOUBLE_SLASH:
			double_slot.start_cooldown()


func _on_attack_blocked() -> void:
	# UI / sonido opcional en el futuro
	pass

func _on_animation_finished(anim_name: String) -> void:
	if not anim_name.begins_with("attack"):
		return

	if attack_controller.is_attacking():
		attack_controller.notify_next_hit()

func apply_knockback(direction: Vector2, force: float):
	# DEBUG: información que recibe el jugador
	#print("🟠 Player.apply_knockback() llamado")
	#print("    direction:", direction, " force:", force)
	#print("    player velocity BEFORE:", velocity)

	# Aplicación real (usa masa del jugador si quieres dividir, ahora directo)
	velocity += direction.normalized() * force

	# DEBUG: resultado
	#print("    player velocity AFTER:", velocity)

# ───── DASH ─────
func start_dash():
	is_dashing = true
	can_dash = false

	set_collision_layer(2)
	set_collision_mask(1)

	match last_direction:
		"front": velocity = Vector2(0, 1)
		"back": velocity = Vector2(0, -1)
		"left_side": velocity = Vector2(-1, 0)
		"right_side": velocity = Vector2(1, 0)

	velocity = velocity.normalized() * dash_speed
	animation.play("dash_" + last_direction)

	dash_timer.start()
	dash_cooldown_timer.start()

func _on_dash_finished():
	is_dashing = false
	velocity = Vector2.ZERO
	set_collision_layer(original_layer)
	set_collision_mask(original_mask)

func _on_dash_cooldown_finished():
	can_dash = true

# ───── DAÑO Y MUERTE ─────
func take_damage(amount: float, tipo: String = "fisico"):
	var final_damage = amount

	if tipo == "fisico":
		var resistencia = base_stats.get("resistencia", 15)
		var reduccion = resistencia * 0.15
		final_damage = max(amount - reduccion, 0)
		print("🪓 Daño físico: %.2f | Reducción: %.2f | Final: %.2f" % [amount, reduccion, final_damage])
	elif tipo == "magico":
		var resist_magica = base_stats.get("resistencia_hechizos", 10)
		var reduccion = resist_magica * 0.15
		final_damage = max(amount - reduccion, 0)
		print("✨ Daño mágico: %.2f | Reducción mágica: %.2f | Final: %.2f" % [amount, reduccion, final_damage])
	else:
		print("❔ Tipo de daño desconocido:", tipo)

	current_health = max(current_health - final_damage, 0)
	emit_signal("health_changed", current_health, max_health)

	if current_health == 0:
		die()
		return

	if not attack_controller.is_attacking() and not is_dashing:
		var anim_name = "take_damage_" + last_direction
		if animation.sprite_frames.has_animation(anim_name):
			animation.play(anim_name)



func heal(amount: int):
	if current_health <= 0:
		return # no curar si ya está muerto

	var old_health = current_health
	current_health = min(current_health + amount, max_health)

	print("❤️ Curado: +%d (de %d → %d)" % [amount, old_health, current_health])
	emit_signal("health_changed", current_health, max_health)

 
func die():
	if not can_move:
		return # evita doble muerte

	can_move = false
	attack_controller.lock_attacks()
	is_dashing = false
	velocity = Vector2.ZERO

	set_collision_layer(0)
	set_collision_mask(0)

	# Animación de muerte
	var anim_name := "death_" + last_direction
	if animation.sprite_frames.has_animation(anim_name):
		animation.play(anim_name)

	# Vaciar inventario
	_clear_inventory()

	# Efecto de cámara
	var tween := get_tree().create_tween()
	tween.tween_property(
		camera,
		"zoom",
		Vector2(2.7, 2.7),
		1.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await tween.finished

	# Esperar 2 segundos antes de reaparecer
	await get_tree().create_timer(2.0).timeout

	respawn()

func _clear_inventory():
	for i in range(inventory.size()):
		inventory[i] = null
	emit_signal("inventory_updated", inventory)

func respawn():
	var wm := get_tree().get_first_node_in_group("world_manager")

	if wm and last_checkpoint_scene != "":
		respawn_pending_checkpoint_id = last_checkpoint_id
		wm.change_world(last_checkpoint_scene, "")
		await get_tree().process_frame
		await _wait_for_checkpoint()
	else:
		global_position = Vector2.ZERO

	_restore_player_state()

	if wm:
		wm.transition_anim.play("fade_in")

func rebuild_stats_from_save() -> void:
	for stat in stat_levels.keys():
		base_stats[stat] = _get_stat_value(stat)

	# sincronizar HP
	max_health = base_stats["hp"]
	current_health = min(current_health, max_health)

	# sincronizar velocidad
	walk_speed = base_stats["speed"] * 0.4
	run_speed = base_stats["speed"]

	# cache si usas daño directo
	fuerza_jugador = base_stats["fuerza"]

	emit_signal("health_changed", current_health, max_health)

	# refrescar UI si existe
	var stats_menu = get_tree().get_first_node_in_group("stats_menu")
	if stats_menu:
		stats_menu._update_all_stats()


func _restore_player_state():
	current_health = max_health
	emit_signal("health_changed", current_health, max_health)

	can_move = true
	is_dashing = false

	set_collision_layer(original_layer)
	set_collision_mask(original_mask)

	camera.zoom = Vector2(1.5, 1.5)
	animation.play("idle_" + last_direction)

	attack_controller.unlock_attacks()

func _on_zoom_finished():
	#print("🔍 Buscando world_manager...")
	var wm := get_tree().get_first_node_in_group("world_manager")

	if wm and last_checkpoint_scene != "":
		#print("✅ WorldManager encontrado, haciendo fade")
		wm.change_world(last_checkpoint_scene, "")
		await get_tree().process_frame

		# Esperar a que se registre el checkpoint correspondiente
		respawn_pending_checkpoint_id = last_checkpoint_id
		await _wait_for_checkpoint()
	else:
		#print("⚠️ No se pudo cargar la escena del checkpoint")
		global_position = Vector2.ZERO

	# Restaurar estado del jugador
	current_health = max_health
	emit_signal("health_changed", current_health, max_health)
	can_move = true
	attack_controller.is_attacking()
	is_dashing = false
	set_collision_layer(original_layer)
	set_collision_mask(original_mask)

	camera.zoom = Vector2(1.5, 1.5)
	animation.play("idle_" + last_direction)

	if wm:
		wm.transition_anim.play("fade_in")


# ------ Inventory -------
func add_item_to_inventory(item_data: ItemData, amount: int = 1) -> bool:
	var remaining := amount

	# 1) Apilar en slots existentes
	for i in range(inventory.size()):
		var slot = inventory[i]
		if slot != null and slot["item_data"] == item_data:
			var space_left = item_data.max_stack - slot["amount"]
			var to_add = min(space_left, remaining)
			slot["amount"] += to_add
			remaining -= to_add
			if remaining <= 0:
				emit_signal("inventory_updated", inventory)
				return true

	# 2) Buscar slots vacíos
	if remaining > 0:
		for i in range(inventory.size()):
			if inventory[i] == null:
				var to_add = min(item_data.max_stack, remaining)
				inventory[i] = {"item_data": item_data, "amount": to_add}
				remaining -= to_add
				if remaining <= 0:
					emit_signal("inventory_updated", inventory)
					return true

	emit_signal("inventory_updated", inventory)
	return false

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
		#print("⚠️ Inventario lleno. No se pudo recoger: ", remaining, " x ", item_data.item_name)
		return false
	else:
		#print("✔️ Agregado: ", amount, " x ", item_data.item_name)
		print(inventory)
		return true

	emit_signal("inventory_updated", inventory)
	


func _remove_item_from_inventory(item_data: ItemData, amount: int = 1) -> void:
	for i in range(inventory.size()):
		var slot = inventory[i]
		if slot != null and slot["item_data"] == item_data:
			if slot["amount"] > amount:
				slot["amount"] -= amount
			else:
				inventory[i] = null # si queda en 0, limpiar slot
			break

	emit_signal("inventory_updated", inventory)



# ----- CheckPoints -----
func update_checkpoint(checkpoint_id: String):
	last_checkpoint_id = checkpoint_id

	var wm := get_tree().get_first_node_in_group("world_manager")
	if wm and wm.current_world:
		last_checkpoint_scene = wm.current_world.scene_file_path
	else:
		return
		#print("⚠️ No se pudo determinar la escena del checkpoint")

	#print("📍 Checkpoint actualizado:", checkpoint_id)
	#print("🎬 Escena del checkpoint:", last_checkpoint_scene)

func find_checkpoint_by_id(id: String) -> Node:
	var checkpoints = get_tree().get_nodes_in_group("checkpoint")
	for cp in checkpoints:
		if cp.checkpoint_id == id:
			return cp
	print("❌ No se encontró el checkpoint con ID:", id)
	return null

func _wait_for_checkpoint():
	var max_wait_time := 3.0
	var elapsed := 0.0
	while elapsed < max_wait_time:
		await get_tree().process_frame
		var checkpoint = CheckPointRegistry.get_checkpoint(respawn_pending_checkpoint_id)
		if checkpoint:
			global_position = checkpoint.global_position
			#print("✅ Respawneado en checkpoint:", respawn_pending_checkpoint_id)
			respawn_pending_checkpoint_id = ""
			return
		elapsed += get_process_delta_time()

# ----- XP & StatPoints Gains -----

func gain_experience(amount: int):
	experience += amount
	#print("Ganaste %d XP (Total): %d / %d" % [amount, experience, experience_to_next_level])
	while experience >= experience_to_next_level:
		experience -= experience_to_next_level
		level_up()
	var stats_menu = get_tree().get_first_node_in_group("stats_menu")
	if stats_menu:
		stats_menu._update_all_stats()


func level_up():
	level = int(level) + 1
	experience_to_next_level = int(experience_to_next_level * 1.2)
	
	# reparto de puntos segundo multiplo de 5
	if level % 5 == 0:
		stat_points += 5
	else:
		stat_points += 3
	
	#print(" Nivel %d alcalzado! Puntos para gastar: %d " % [level, stat_points])
	

# Retorna el valor base por stat (para calcular el costo)
func get_stat_base(stat_name: String) -> int:
	match stat_name:
		"hp": return 50
		"speed": return 160
		"fuerza": return 3
		"mana": return 10
		"resistencia", "resistencia_hechizos", "poder_magico": return 0
		_: return 0

# Calcula el costo de mejorar una stat según su valor actual
func get_upgrade_cost(stat_name: String) -> int:
	if not base_stats.has(stat_name):
		return 999  # Stat inválida
	var current_value = base_stats[stat_name]
	var base_value = get_stat_base(stat_name)
	var difference = current_value - base_value
	return int((difference / 10.0 + 1) * 4)

# Intenta mejorar la stat si hay puntos suficientes
func upgrade_stat(stat_name: String) -> bool:
	match stat_name:
		"hp":
			return _upgrade_hp()
		"speed":
			return _upgrade_speed()
		"fuerza":
			return _upgrade_fuerza()
		"resistencia": 
			return _upgrade_resistencia()
		"mana":
			return _upgrade_mana()
		"poder_magico": 
			return _upgrade_poder_magico()
		"resistencia_hechizos": 
			return _upgrade_resistencia_hechizos()
		"lucky":
			return _upgrade_lucky()
		_:
			print("⚠️ Stat aún no implementada:", stat_name)
			return false

func _open_statUI():
	if Input.is_action_just_pressed("StatsUI"):
		print("menu de stats")

		var stats_menu = get_tree().get_first_node_in_group("stats_menu")
		if stats_menu:
			stats_menu.visible = not stats_menu.visible

			# Bloquear/permitir ataque y movimiento
		if stats_menu.visible:
			can_move = false
			attack_controller.lock_attacks()
		else:
			can_move = true
			attack_controller.unlock_attacks()


# ------- FUNCIONES PARA MEJORAR DE STADISTICAS ------

func _get_stat_value(stat_name: String) -> int:
	if stat_name == "hp":
		var stat_level = stat_levels.get("hp", 1)
		return 50 + (level - 1) * 28 # 10 niveles -> 50 a 300
	elif stat_name == "speed":
		var stat_level = stat_levels.get("speed", 1)
		return 130 + (level - 1) * 7 # 130 -> 180
	elif stat_name == "fuerza":
		var stat_level = stat_levels.get("fuerza", 1)
		return int(5 + (level - 1) * 3.5)
	elif stat_name == "resistencia":
		var stat_level = stat_levels.get("resistencia", 1)
		return int(15 + (level - 1) * 4.5)
	elif stat_name == "mana":
		var stat_level = stat_levels.get("mana", 1)
		return 10 + (level - 1) * 10
	elif stat_name == "poder_magico":
		var stat_level = stat_levels.get("poder_magico", 1)
		return int(10 + (level - 1) * 7)
	elif stat_name == "resistencia_hechizos":
		var stat_level = stat_levels.get("resistencia_hechizos", 1)
		return int(10 + (level - 1) * 5)
	elif stat_name == "lucky":
		var stat_level = stat_levels.get("lucky", 1)
		return float((level - 1) * 2.5)  # 0.0 → 25.0


	return base_stats.get(stat_name, 0)
 
func _get_stat_upgrade_cost(stat_name: String) -> int:
	var level = stat_levels.get(stat_name, 1)
	return level # nivel 1 = cost 1, nivel 2 = cost 2, ...

func _upgrade_hp() -> bool:
	var level = stat_levels.get("hp", 1)
	if level >= 10:
		print("🛑 HP ya está al nivel máximo.")
		return false

	var cost = _get_stat_upgrade_cost("hp")
	if stat_points < cost:
		#print("❌ No tienes suficientes puntos (necesita %d)" % cost)
		return false

	stat_points -= cost
	stat_levels["hp"] += 1

	var new_hp = _get_stat_value("hp")
	base_stats["hp"] = new_hp
	max_health = new_hp
	current_health = min(current_health, max_health)
	emit_signal("health_changed", current_health, max_health)

	#print("✅ HP subió a nivel %d → %d HP" % [stat_levels["hp"], new_hp])
	return true

func _upgrade_speed() -> bool:
	var level = stat_levels.get("speed", 1)
	if level >= 10:
		#print("🛑 Velocidad ya está al nivel máximo.")
		return false

	var cost = _get_stat_upgrade_cost("speed")
	if stat_points < cost:
		#print("❌ No tienes suficientes puntos (necesita %d)" % cost)
		return false

	stat_points -= cost
	stat_levels["speed"] += 1
	

	var new_speed = _get_stat_value("speed")
	base_stats["speed"] = new_speed

	#print("✅ Velocidad subió a nivel %d → %d" % [stat_levels["speed"], new_speed])
	return true

func _upgrade_fuerza() -> bool:
	var level = stat_levels.get("fuerza", 1)
	if level >= 10:
		#print("🛑 Fuerza ya está al nivel máximo.")
		return false

	var cost = _get_stat_upgrade_cost("fuerza")
	if stat_points < cost:
		#print("❌ No tienes suficientes puntos (necesita %d)" % cost)
		return false

	stat_points -= cost
	stat_levels["fuerza"] += 1

	var new_fuerza = _get_stat_value("fuerza")
	base_stats["fuerza"] = new_fuerza

	#print("✅ Fuerza subió a nivel %d → %d" % [stat_levels["fuerza"], new_fuerza])
	return true

func _upgrade_resistencia() -> bool:
	var level = stat_levels.get("resistencia", 1)
	if level >= 10:
		#print("🛑 Resistencia ya está al nivel máximo.")
		return false

	var cost = _get_stat_upgrade_cost("resistencia")
	if stat_points < cost:
		#print("❌ No tienes suficientes puntos (necesita %d)" % cost)
		return false

	stat_points -= cost
	stat_levels["resistencia"] += 1

	var new_resistencia = _get_stat_value("resistencia")
	base_stats["resistencia"] = new_resistencia

	#print("🛡️ Resistencia subió a nivel %d → %.1f" % [stat_levels["resistencia"], new_resistencia])
	return true

func _upgrade_mana() -> bool:
	var level = stat_levels.get("mana", 1)
	if level >= 10:
		print("🛑 Mana ya está al nivel máximo.")
		return false

	var cost = _get_stat_upgrade_cost("mana")
	if stat_points < cost:
		print("❌ No tienes suficientes puntos (necesita %d)" % cost)
		return false

	stat_points -= cost
	stat_levels["mana"] += 1

	var new_mana = _get_stat_value("mana")
	base_stats["mana"] = new_mana
	mana = min(mana, new_mana)  # si usás mana, esto evita que lo suba mágicamente

	print("🔮 Mana subió a nivel %d → %d" % [stat_levels["mana"], new_mana])
	return true

func _upgrade_poder_magico() -> bool:
	var level = stat_levels.get("poder_magico", 1)
	if level >= 10:
		print("🛑 Poder mágico ya está al nivel máximo.")
		return false

	var cost = _get_stat_upgrade_cost("poder_magico")
	if stat_points < cost:
		print("❌ No tienes suficientes puntos (necesita %d)" % cost)
		return false

	stat_points -= cost
	stat_levels["poder_magico"] += 1

	var new_power = _get_stat_value("poder_magico")
	base_stats["poder_magico"] = new_power

	print("✨ Poder mágico subió a nivel %d → %d" % [stat_levels["poder_magico"], new_power])
	return true

func _upgrade_resistencia_hechizos() -> bool:
	var level = stat_levels.get("resistencia_hechizos", 1)
	if level >= 10:
		print("🛑 Resistencia mágica ya está al nivel máximo.")
		return false

	var cost = _get_stat_upgrade_cost("resistencia_hechizos")
	if stat_points < cost:
		print("❌ No tienes suficientes puntos (necesita %d)" % cost)
		return false

	stat_points -= cost
	stat_levels["resistencia_hechizos"] += 1

	var new_resist = _get_stat_value("resistencia_hechizos")
	base_stats["resistencia_hechizos"] = new_resist

	print("🧙‍♂️ Resistencia mágica subió a nivel %d → %d" % [stat_levels["resistencia_hechizos"], new_resist])
	return true

func _upgrade_lucky() -> bool:
	var level = stat_levels.get("lucky", 1)
	if level >= 10:
		print("🛑 Suerte ya está al nivel máximo.")
		return false

	var cost = _get_stat_upgrade_cost("lucky")
	if stat_points < cost:
		print("❌ No tienes suficientes puntos (necesita %d)" % cost)
		return false

	stat_points -= cost
	stat_levels["lucky"] += 1

	var new_lucky = _get_stat_value("lucky")
	base_stats["lucky"] = new_lucky

	print("🍀 Suerte subió a nivel %d → %.1f%%" % [stat_levels["lucky"], new_lucky])
	return true


# --- Funciones para manejo de sonidos ---

func update_tilemap_reference():
	tilemap = get_tree().get_first_node_in_group("ground")
	if tilemap:
		return
	else:
		#print("❌ No se encontró ningún TileMap en el grupo 'ground'")
		return



func play_footstep():
	var surface = get_surface_type_at(global_position)

	var sounds = {
		"wood": {
			"walk": preload("res://SFX/Effects/FootSteps/Wood/Footsteps_Wood_Walk_01.wav"),
			"run": preload("res://SFX/Effects/FootSteps/Wood/Footsteps_Wood_Run_01.wav")
		},
		"grass": {
			"walk": preload("res://SFX/Effects/FootSteps/grass/Footsteps_Walk_Grass_Mono_01.wav"),
			"run": preload("res://SFX/Effects/FootSteps/grass/Footsteps_Grass_Run_01.wav")
		}
	}

	var mode := "walk"
	if is_running:
		mode = "run"

	if surface in sounds:
		footstep_player.stream = sounds[surface][mode]
		footstep_player.play()
	else:
		#print("❌ No hay sonidos definidos para la superficie:", surface)
		return



func get_surface_type_at(pos: Vector2) -> String:
	if tilemap:
		var cell: Vector2i = tilemap.local_to_map(pos)
		var tile_data = tilemap.get_cell_tile_data(cell)
		if tile_data:
			var surface_type = tile_data.get_custom_data("surface_type")
			if surface_type:
				return surface_type
	return "grass" # fallback por defecto


# --- Sincronizacion de animacion y sonido ---

func _on_animated_sprite_2d_frame_changed() -> void:
	var anim = animation.animation
	var frame = animation.frame

	if not anim.begins_with("attack"):
		return

	var total_frames = animation.sprite_frames.get_frame_count(anim)
	var is_last_frame = frame == total_frames - 1

	# ─────────────────────────
	# HITBOX CONTROL
	# ─────────────────────────
	if attack_controller.is_attacking():

		match attack_controller._current_attack:

			PhisycAttackController.AttackType.BASIC_SLASH:
				var should_be_active = frame in BASIC_SLASH_ACTIVE_FRAMES

				if should_be_active and not _hitbox_active:
					_hitbox_active = true
					attack_controller.enable_hitbox()

				elif not should_be_active and _hitbox_active:
					_hitbox_active = false
					attack_controller.disable_hitbox()

			PhisycAttackController.AttackType.DOUBLE_SLASH:
				var should_be_active = frame in DOUBLE_SLASH_ACTIVE_FRAMES

				if should_be_active and not _hitbox_active:
					_hitbox_active = true
					attack_controller.enable_hitbox()

				elif not should_be_active and _hitbox_active:
					_hitbox_active = false
					attack_controller.disable_hitbox()

	# ─────────────────────────
	# FIN DE ANIMACIÓN
	# ─────────────────────────
	if not is_last_frame:
		return


	_force_disable_hitbox()
	attack_controller.disable_hitbox()

	# BASIC SLASH termina aquí
	if attack_controller._current_attack == PhisycAttackController.AttackType.BASIC_SLASH:
		attack_controller.notify_attack_finished()
		can_move = true
		animation.play("idle_" + last_direction)
		return

	# DOUBLE SLASH
	if attack_controller._current_attack == PhisycAttackController.AttackType.DOUBLE_SLASH:

		# Fin del primer golpe → iniciar segundo
		if attack_controller._current_hit == 1:
			attack_controller.notify_next_hit()
			animation.play("attack2_" + last_direction)
			return

		# Fin del segundo golpe → terminar ataque
		if attack_controller._current_hit == 2:
			attack_controller.notify_attack_finished()
			can_move = true
			animation.play("idle_" + last_direction)
			return

	# --- Pasos ---
	if anim.begins_with("walk") or anim.begins_with("run"):
		if frame == 3:
			play_footstep()

func _force_disable_hitbox():
	if _hitbox_active:
		_hitbox_active = false
		attack_controller.disable_hitbox()
