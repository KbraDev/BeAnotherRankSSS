extends Node

const SAVE_FOLDER := "user://saves/"
const SLOT_PATHS := {
	1: SAVE_FOLDER + "slot1.json",
	2: SAVE_FOLDER + "slot2.json",
	3: SAVE_FOLDER + "slot3.json"
}

func save_game(player: Node, slot: int = 1) -> void:
	var wm = get_tree().current_scene
	var scene_path = wm.current_world.scene_file_path

	var data = {
		"scene_path": scene_path,
		"player": collect_player_data(player)
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
		print("❌ No se pudo cargar el slot ", slot)
		return

	var scene_path = save_data.get("scene_path", "")
	if scene_path == "":
		print("❌ No se especificó ninguna escena.")
		return

	get_tree().paused = false

	var wm = get_tree().current_scene
	if wm:
		await wm.load_game_state(save_data)  # este se encargará de buscar al jugador y restaurar
	else:
		print("❌ WorldManager no está activo como escena actual.")


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

		# 🟢 Monedas y cofres globales
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

	# 🟢 Restaurar monedas y cofres
	if data.has("coins"):
		Playerwallet.coins = data["coins"]
		Playerwallet.emit_signal("coins_changed")

	if data.has("opened_chests"):
		ChestRegistry.opened_chests = data["opened_chests"].duplicate()
		for chest in get_tree().get_nodes_in_group("chests"):
			chest.refresh_state()

	# 🟢 Restaurar inventario
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
					player.inventory[i] = {
						"item_data": item_data,
						"amount": amount
					}
				else:
					print("⚠️ No se encontró el ítem:", item_id)
		else:
			player.inventory[i] = null

	player.emit_signal("inventory_updated", player.inventory)
	player.emit_signal("health_changed", player.current_health, player.max_health)
	print("✅ Datos del jugador restaurados desde SaveManager.")

func _capture_thumbnail(slot: int) -> void:
	# Captura una imagen del juego sin los CanvasLayers visibles
	var viewport := get_viewport()
	if not viewport:
		return

	# Ocultar temporalmente los CanvasLayers
	var hidden_layers: Array = []
	for node in get_tree().get_nodes_in_group("ui"):
		if node.visible:
			node.visible = false
			hidden_layers.append(node)

	# Capturar el contenido actual del viewport
	await get_tree().process_frame  # Esperar un frame para actualizar
	var image: Image = viewport.get_texture().get_image()
	image.resize(320, 180)  # Reducir tamaño (thumbnail estándar)
	var path := "user://saves/slot%d_thumbnail.png" % slot
	image.save_png(path)

	# Restaurar visibilidad de los CanvasLayers
	for node in hidden_layers:
		node.visible = true
