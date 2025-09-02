extends CharacterBody2D

# ───── CONST Y ENUMS ─────
const SPEED = 160.0
const DAMAGE = 3.0
const INVENTORY_ROWS := 3
const INVENTORY_COLS := 5
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

var walk_speed = 80.0
var run_speed = 160.0
var is_running = false

var can_move = true

var mana = 10
var level = 1

var current_health = 50
var max_health = 50

var inventory: Array = []

var last_direction := "front"
var can_attack := true
var is_attacking := false
var attack_click_count := 0
var current_attack := 1

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


# ───── NODOS Y TIMERS ─────
@onready var attack_area = $attack_area
@onready var animation = $AnimatedSprite2D
@onready var camera = $Camera2D
@onready var footstep_player : AudioStreamPlayer = $FootstepPlayer
@onready var tilemap: TileMapLayer = get_tree().get_first_node_in_group("ground")

@onready var attack_timer = Timer.new()
@onready var combo_timer = Timer.new()
@onready var dash_timer := Timer.new()
@onready var dash_cooldown_timer := Timer.new()

# ───── SEÑALES ─────
signal inventory_updated(inventory: Array)
signal health_changed(current_health, max_health)

# ───── READY ─────
func _ready():
	print("Puntos del jugador: ", stat_points)
	print("MissionTracker cargado?", MissionTracker)
	animation.play("idle_" + last_direction)

	add_child(combo_timer)
	combo_timer.one_shot = true
	combo_timer.wait_time = 1.2
	combo_timer.connect("timeout", _on_combo_timer_timeout)

	add_child(attack_timer)
	attack_timer.one_shot = true
	attack_timer.wait_time = 0.4
	attack_timer.connect("timeout", _on_attack_cooldown_timeout)

	add_child(dash_timer)
	dash_timer.one_shot = true
	dash_timer.wait_time = dash_duration
	dash_timer.connect("timeout", _on_dash_finished)

	add_child(dash_cooldown_timer)
	dash_cooldown_timer.one_shot = true
	dash_cooldown_timer.wait_time = dash_cooldown
	dash_cooldown_timer.connect("timeout", _on_dash_cooldown_finished)

	animation.connect("animation_finished", _on_animation_finished)

	inventory.resize(INVENTORY_SIZE)
	for i in range(INVENTORY_SIZE):
		inventory[i] = null

	stat_points = 0
	emit_signal("health_changed", current_health, max_health)



# ───── PROCESO Y ENTRADA ─────
func _physics_process(delta: float) -> void:
	directional_movement()
	move_and_slide()
	
	if Input.is_action_just_pressed("attack") and can_attack:
		attack_click_count += 1

	if attack_click_count > 0 and not is_attacking and can_attack:
		velocity = Vector2.ZERO
		perform_attack()

	# Detectar superficie bajo el jugador
	if tilemap:
		var cell: Vector2i = tilemap.local_to_map(global_position)
		var tile_data = tilemap.get_cell_tile_data(cell) # ✅ Ahora funciona en Godot 4
		if tile_data:
			var surface_type = tile_data.get_custom_data("surface_type")
			if surface_type:
				current_surface = surface_type

	if Input.is_action_just_pressed("shiftIZQ") and can_dash and not is_dashing:
		start_dash()

func directional_movement():
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
func handle_Animations(direction: Vector2):
	if is_attacking:
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

func perform_attack():
	is_attacking = true
	can_attack = false

	var animation_name = "attack%d_%s" % [current_attack, last_direction]
	var fuerza = base_stats.get("fuerza", 5)
	var base_damage = DAMAGE if current_attack == 1 else DAMAGE + 1.5
	var damage = base_damage + (fuerza * 0.25)

	animation.play(animation_name)

	attack_area.monitoring = true
	attack_area.set_deferred("collision_layer", 1)

	await get_tree().create_timer(0.05).timeout

	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			body.take_damage(damage)
			print("dano echo por jugador: ", damage)

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

	if not is_attacking and not is_dashing:
		var prefix := ""  # ya no depende de estado
		var anim_name = "take_damage_" + last_direction
		if animation.sprite_frames.has_animation(anim_name):
			animation.play(anim_name)

func die():
	can_move = false
	can_attack = false
	is_attacking = false
	is_dashing = false
	velocity = Vector2.ZERO
	set_collision_layer(0)
	set_collision_mask(0)

	var prefix := ""
	var anim_name = prefix + "death_" + last_direction
	if animation.sprite_frames.has_animation(anim_name):
		animation.play(anim_name)

	var tween := get_tree().create_tween()
	tween.tween_property(camera, "zoom", Vector2(2.7, 2.7), 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	_on_zoom_finished()

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
	can_attack = true
	is_attacking = false
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
		#print("⚠️ Inventario lleno. No se pudo recoger: ", remaining, " x ", item_data.item_name)
		return false
	else:
		#print("✔️ Agregado: ", amount, " x ", item_data.item_name)
		print(inventory)
		return true

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
	#print("❌ Timeout esperando al checkpoint:", respawn_pending_checkpoint_id)

# ----- Save & Load -----

func get_save_data() -> Dictionary:
	var inv := []
	for item in inventory:
		if item != null:
			inv.append({
				"item_id": item.item_data.item_id,
				"amount": item.amount
			})
		else:
			inv.append(null)

	return {
		"position": [global_position.x, global_position.y],
		"hp": current_health,
		"max_hp": max_health,
		"mana": mana,
		"level": level,
		"experience": experience,
		"experience_to_next_level": experience_to_next_level,
		"stat_points": stat_points,
		"base_stats": base_stats,
		"stat_levels": stat_levels,
		"inventory": inv,
		"last_checkpoint_id": last_checkpoint_id,
		"last_checkpoint_scene": last_checkpoint_scene
	}


func load_from_save(data: Dictionary) -> void:
	var pos = data.get("position", [0, 0])
	global_position = Vector2(pos[0], pos[1])
	current_health = data.get("hp", 50)
	max_health = data.get("max_hp", 50)
	mana = data.get("mana", 10)
	level = data.get("level", 1)
	experience = data.get("experience", 0)
	experience_to_next_level = data.get("experience_to_next_level", 100)
	stat_points = data.get("stat_points", 0)
	base_stats = data.get("base_stats", base_stats)
	stat_levels = data.get("stat_levels", stat_levels)

	last_checkpoint_id = data.get("last_checkpoint_id", "")
	last_checkpoint_scene = data.get("last_checkpoint_scene", "")

	var inv_data = data.get("inventory", [])
	inventory.resize(INVENTORY_SIZE)
	for i in range(INVENTORY_SIZE):
		if i < inv_data.size():
			var item_info = inv_data[i]
			if item_info == null:
				inventory[i] = null
			else:
				var item_id = item_info.get("item_id", "")
				var amount = item_info.get("amount", 0)
				var item_data = ItemDataBase.get_item_by_id(item_id)
				if item_data:
					inventory[i] = {
						"item_data": item_data,
						"amount": amount
					}
				else:
					print("⚠️ No se encontró el ítem:", item_id)
		else:
			inventory[i] = null
	
	emit_signal("inventory_updated", inventory)
	emit_signal("health_changed", current_health, max_health)
	print("✅ Jugador restaurado desde guardado.")


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
	level += 1
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
		$StatsMenu.visible = !$StatsMenu.visible

# ------- FUNCIONES PARA MEJORAR DE STADISTICAS ------

func _get_stat_value(stat_name: String) -> int:
	if stat_name == "hp":
		var level = stat_levels.get("hp", 1)
		return 50 + (level - 1) * 28 # 10 niveles -> 50 a 300
	elif stat_name == "speed":
		var level = stat_levels.get("speed", 1)
		return 130 + (level - 1) * 7 # 130 -> 180
	elif stat_name == "fuerza":
		var level = stat_levels.get("fuerza", 1)
		return int(5 + (level - 1) * 3.5)
	elif stat_name == "resistencia":
		var level = stat_levels.get("resistencia", 1)
		return int(15 + (level - 1) * 4.5)
	elif stat_name == "mana":
		var level = stat_levels.get("mana", 1)
		return 10 + (level - 1) * 10
	elif stat_name == "poder_magico":
		var level = stat_levels.get("poder_magico", 1)
		return int(10 + (level - 1) * 7)
	elif stat_name == "resistencia_hechizos":
		var level = stat_levels.get("resistencia_hechizos", 1)
		return int(10 + (level - 1) * 5)
	elif stat_name == "lucky":
		var level = stat_levels.get("lucky", 1)
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


func play_footstep():
	print("👣 Paso en superficie:", current_surface, " modo:" )
	var sounds = {
		"wood" : {
			"walk" : preload("res://SFX/Effects/FootSteps/Wood/Footsteps_Wood_Walk_01.wav"),
			"run" : preload("res://SFX/Effects/FootSteps/Wood/Footsteps_Wood_Run_01.wav")
		},
		"grass": {
			"walk" : preload("res://SFX/Effects/FootSteps/grass/Footsteps_Walk_Grass_Mono_01.wav"),
			"run" : preload("res://SFX/Effects/FootSteps/grass/Footsteps_Grass_Run_01.wav")
		}
	}
	
	var mode := "walk"
	if is_running:
		mode = "run"

	if current_surface in sounds:
		footstep_player.stream = sounds[current_surface][mode]
		footstep_player.play()

# --- Sincronizacion de animacion y sonido ---

func _on_animated_sprite_2d_frame_changed() -> void:
	var anim = animation.animation
	var f = animation.frame
	
	if anim.begins_with("walk") or anim.begins_with("run"):
		if f in [3]:
			play_footstep()
