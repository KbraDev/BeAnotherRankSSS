extends Node

const SAVE_FOLDER := "user://saves/"
const SLOT_PATHS := {
	1: SAVE_FOLDER + "slot1.json",
	2: SAVE_FOLDER + "slot2.json",
	3: SAVE_FOLDER + "slot3.json"
}


# ==========================================================
# 🟢 GUARDAR Y CARGAR JUEGO
# ==========================================================
func save_game(player: Node, slot: int = 1) -> void:
	var wm = get_tree().current_scene
	var scene_path = wm.current_world.scene_file_path

	var data = {
		"scene_path": scene_path,
		"player": collect_player_data(player),
		"missions": collect_mission_data()
	}

	DirAccess.make_dir_recursive_absolute(SAVE_FOLDER)

	var file = FileAccess.open(SLOT_PATHS[slot], FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	# 🟢 Capturar thumbnail después de guardar
	await _capture_thumbnail(slot)


func load_game(slot: int = 1) -> Dictionary:
	if not FileAccess.file_exists(SLOT_PATHS[slot]):
		push_error("❌ Archivo de guardado no encontrado para slot %d" % slot)
		return {}

	var file = FileAccess.open(SLOT_PATHS[slot], FileAccess.READ)
	var json = file.get_as_text()
	file.close()

	var result = JSON.parse_string(json)
	if typeof(result) != TYPE_DICTIONARY:
		push_error("❌ Error al leer el archivo de guardado.")
		return {}

	return result


func load_slot_and_restore(slot: int):
	var save_data = load_game(slot)
	if save_data.is_empty():
		#print("❌ No se pudo cargar el slot ", slot)
		return

	var scene_path = save_data.get("scene_path", "")
	if scene_path == "":
		#print("❌ No se especificó ninguna escena.")
		return

	get_tree().paused = false

	var wm = get_tree().current_scene
	if wm:
		await wm.load_game_state(save_data)
	else:
		pass
		#print("❌ WorldManager no está activo como escena actual.")


# ==========================================================
# 🟢 CREAR NUEVO SLOT
# ==========================================================
func create_new_slot(slot_index: int) -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_FOLDER)

	var save_path: String = SLOT_PATHS.get(slot_index, "")
	if save_path == "":
		push_error("❌ Slot inválido: %d" % slot_index)
		return

	# 🔄 Si ya existe un archivo viejo, eliminarlo
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)

	var new_data := {
		"scene_path": "res://scenes/world/world_manager.tscn",
		"player": {
			"position": [0, 0],
			"hp": 100,
			"max_hp": 100,
			"mana": 10,
			"level": 1,
			"experience": 0,
			"experience_to_next_level": 100,
			"stat_points": 0,
			"base_stats": {},
			"stat_levels": {},
			"inventory": [],
			"last_checkpoint_id": "",
			"last_checkpoint_scene": "",
			"coins": 0,
			"opened_chests": []
		}
	}

	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(new_data, "\t"))
		file.close()
		#print("🆕 Nueva partida creada en el slot %d" % slot_index)
	else:
		push_error("❌ No se pudo crear el archivo de guardado para el slot %d" % slot_index)


# ==========================================================
# 🟢 RECOLECTAR / RESTAURAR DATOS DE JUGADOR
# ==========================================================
func collect_player_data(player: Node) -> Dictionary:
	var inv := []
	for item in player.inventory:
		if item != null:
			inv.append({
				"item_id": item.item_data.item_id,
				"amount": item.amount
			})
		else:
			inv.append(null)

	return {
		"position": [player.global_position.x, player.global_position.y],
		"hp": player.current_health,
		"max_hp": player.max_health,
		"mana": player.mana,
		"level": player.level,
		"experience": player.experience,
		"experience_to_next_level": player.experience_to_next_level,
		"stat_points": player.stat_points,
		"base_stats": player.base_stats,
		"stat_levels": player.stat_levels,
		"inventory": inv,
		"last_checkpoint_id": player.last_checkpoint_id,
		"last_checkpoint_scene": player.last_checkpoint_scene,
		"coins": Playerwallet.coins,
		"opened_chests": ChestRegistry.opened_chests
	}


func restore_player_data(player: Node, data: Dictionary) -> void:
	var pos = data.get("position", [0, 0])
	player.global_position = Vector2(pos[0], pos[1])
	player.current_health = data.get("hp", 50)
	player.max_health = data.get("max_hp", 50)
	player.mana = data.get("mana", 10)
	player.level = int(data.get("level", 1))
	player.experience = data.get("experience", 0)
	player.experience_to_next_level = data.get("experience_to_next_level", 100)
	player.stat_points = data.get("stat_points", 0)
	player.base_stats = data.get("base_stats", player.base_stats)
	player.stat_levels = data.get("stat_levels", player.stat_levels)

	player.last_checkpoint_id = data.get("last_checkpoint_id", "")
	player.last_checkpoint_scene = data.get("last_checkpoint_scene", "")

	if data.has("coins"):
		var saved_coins = data["coins"]

		# 🧠 Compatibilidad: puede ser un número antiguo o un diccionario moderno
		if typeof(saved_coins) == TYPE_DICTIONARY:
			Playerwallet.coins = saved_coins.duplicate()
		elif typeof(saved_coins) in [TYPE_INT, TYPE_FLOAT]:
			# Convertir el valor viejo a nuevo formato
			Playerwallet.coins = {
				"BronzeCoin": int(saved_coins),
				"SilverCoin": 0,
				"GoldCoin": 0
			}
		else:
			push_warning("⚠️ Tipo inesperado de 'coins' en los datos de guardado: %s" % str(typeof(saved_coins)))

		Playerwallet.emit_signal("coins_changed")

	if data.has("opened_chests"):
		var saved_chests = data["opened_chests"]

		# 🧠 Compatibilidad: puede ser un Array viejo o un Dictionary nuevo
		if typeof(saved_chests) == TYPE_DICTIONARY:
			ChestRegistry.opened_chests = saved_chests.duplicate()
		elif typeof(saved_chests) == TYPE_ARRAY:
			# Convertimos el array en un diccionario simple de cofres abiertos
			var converted := {}
			for chest_id in saved_chests:
				converted[chest_id] = true
			ChestRegistry.opened_chests = converted
		else:
			push_warning("⚠️ Tipo inesperado de 'opened_chests': %s" % str(typeof(saved_chests)))

		# Refrescar cofres en la escena actual
		for chest in get_tree().get_nodes_in_group("chests"):
			chest.refresh_state()

	var inv_data = data.get("inventory", [])
	player.inventory.resize(player.INVENTORY_SIZE)
	for i in range(player.INVENTORY_SIZE):
		if i < inv_data.size():
			var item_info = inv_data[i]
			if item_info == null:
				player.inventory[i] = null
			else:
				var item_id = item_info.get("item_id", "")
				var amount = item_info.get("amount", 0)
				var item_data = ItemDataBase.get_item_by_id(item_id)
				if item_data:
					player.inventory[i] = {"item_data": item_data, "amount": amount}
				else:
					pass
					#print("⚠️ No se encontró el ítem:", item_id)
		else:
			player.inventory[i] = null

	player.emit_signal("inventory_updated", player.inventory)
	player.emit_signal("health_changed", player.current_health, player.max_health)
	#print("✅ Datos del jugador restaurados desde SaveManager.")


# ==========================================================
# 🟢 CAPTURA DE MINIATURA
# ==========================================================
func _capture_thumbnail(slot: int) -> void:
	var viewport := get_viewport()
	if not viewport:
		return

	var hidden_layers: Array = []
	for node in get_tree().get_nodes_in_group("ui"):
		if node.visible:
			node.visible = false
			hidden_layers.append(node)

	await get_tree().process_frame
	var image: Image = viewport.get_texture().get_image()
	image.resize(320, 180)
	var path := "user://saves/slot%d_thumbnail.png" % slot
	image.save_png(path)

	for node in hidden_layers:
		node.visible = true


# ==========================================================
# 🟡 INICIAR NUEVA PARTIDA
# ==========================================================
func start_new_game(slot_index: int) -> void:
	#print("🟢 [SaveManager] start_new_game() iniciado para slot:", slot_index)
	create_new_slot(slot_index)

	# 1️⃣ Obtener overlay (asegurarse que exista)
	var overlay: Node = null
	if Engine.has_singleton("TransitionOverlay"):
		overlay = Engine.get_singleton("TransitionOverlay")
	elif get_tree().root.has_node("TransitionOverlay"):
		overlay = get_tree().root.get_node("TransitionOverlay")

	# 2️⃣ Si hay overlay, hacer fade_out ANTES de cargar
	if overlay:
		#print("🎬 Ejecutando fade_out antes de cargar WorldManager...")
		await overlay.fade_out()
	else:
		pass
		#print("⚠️ TransitionOverlay no encontrado, salto de transición.")

	# 3️⃣ Ahora que la pantalla está en negro → cambiar escena
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/world/world_manager.tscn")

	# 4️⃣ Esperar a que la escena nueva esté completamente cargada
	await get_tree().process_frame
	await get_tree().process_frame

	var wm = get_tree().current_scene
	var retries := 0
	while (not wm or not wm.has_method("load_game_state")) and retries < 60:
		await get_tree().process_frame
		retries += 1
		wm = get_tree().current_scene

	# 5️⃣ Restaurar datos o iniciar nueva partida
	if wm and wm.has_method("load_game_state"):
		print("✅ WorldManager detectado — cargando partida inicial...")
		var save_data = load_game(slot_index)
		save_data["is_new_game"] = true
		await wm.load_game_state(save_data)
	else:
		push_error("❌ No se encontró load_game_state incluso tras esperar.")

	# 6️⃣ Cuando todo está listo → Fade in
	if overlay:
		#print("🎬 Ejecutando fade_in tras carga completa.")
		await overlay.fade_in()

	#print("🏁 Nueva partida iniciada correctamente en slot %d" % slot_index)



# ==========================================================
# 🟢 CARGAR PARTIDA EXISTENTE
# ==========================================================
func load_existing_game(slot_index: int) -> void:
	#print("📂 Cargando partida existente (slot %d)" % slot_index)
	var save_data = load_game(slot_index)
	if save_data.is_empty():
		push_error("❌ No hay datos en el slot %d" % slot_index)
		return

	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/world/world_manager.tscn")

	await get_tree().process_frame
	await get_tree().process_frame

	var wm = get_tree().current_scene
	if wm and wm.has_method("load_game_state"):
		await wm.load_game_state(save_data)
		#print("✅ Partida cargada desde slot %d" % slot_index)
	else:
		push_error("❌ No se pudo restaurar la partida correctamente.")


# Misiones activas
func collect_mission_data() -> Array:
	var tracker = MissionTracker
	if not tracker:
		print("⚠️ No se encontró el MissionTracker al guardar.")
		return []
		
	var data := []
	for state in tracker.active_mission:
		if state and state.mission:
			data.append({
				"mission_path": state.mission.resource_path,  # guarda la ruta al .tres
				"status": state.status,
				"progress": state.progress,
				"time_started": state.time_started
			})
	return data


func restore_mission_data(mission_data: Array) -> void:
	var tracker = MissionTracker
	if not tracker:
		print("⚠️ No se encontró MissionTracker al cargar.")
		return

	tracker.active_mission.clear()
	for entry in mission_data:
		var path = entry.get("mission_path", "")
		if path == "":
			continue

		var mission_res = load(path)
		if not mission_res:
			print("⚠️ No se pudo cargar misión:", path)
			continue

		var state = MissionState.new()
		state.mission = mission_res
		state.status = entry.get("status", "active")
		state.progress = entry.get("progress", 0)
		state.time_started = entry.get("time_started", 0)

		tracker.active_mission.append(state)
		tracker.emit_signal("mission_added", state)
