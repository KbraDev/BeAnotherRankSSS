extends Control
signal mission_delivered(mission_state: MissionState)

@onready var title_label = $Panel/title
@onready var desc_label = $Panel/description
@onready var reward_label = $Panel/reward
@onready var rank_label = $Panel/rank
@onready var deliver_button = $Panel/Button

var mission_state: MissionState
var show_deliver_button := true

# --- SETUP ---
func _ready():
	if deliver_button and not deliver_button.pressed.is_connected(_on_DeliverButton_pressed):
		deliver_button.pressed.connect(_on_DeliverButton_pressed)

func set_mission_state(state: MissionState, show_button := true) -> void:
	mission_state = state
	show_deliver_button = show_button
	await self.ready
	_update_ui()


# --- ACTUALIZAR UI ---
func _update_ui():
	if mission_state == null or mission_state.mission == null:
		return

	var mission = mission_state.mission

	title_label.text = mission.name
	desc_label.text = mission.description
	rank_label.text = "Rango: %s" % mission.rank

	# 🧾 Construir texto de recompensas
	var rewards_text = "Recompensas:\n"
	rewards_text += "XP: %s\n" % mission.rewards_xp

	if mission.rewards_items.size() > 0:
		for reward in mission.rewards_items:
			if typeof(reward) == TYPE_DICTIONARY and reward.has("id") and reward.has("amount"):
				var item_id = reward["id"]
				var amount = reward["amount"]

				var display_name = item_id
				var item_res = ItemDataBase.get_item_by_name(item_id)
				if item_res:
					if "item_name" in item_res:
						display_name = item_res.item_name
					elif item_res.has_meta("item_name"):
						display_name = item_res.get_meta("item_name")

				rewards_text += "- %s (%s)\n" % [display_name, amount]
			else:
				rewards_text += "- %s\n" % str(reward)

	reward_label.text = rewards_text
	deliver_button.visible = show_deliver_button and mission_state.status == "ready"


# --- BOTÓN ENTREGAR ---
func _on_DeliverButton_pressed():
	var floating = get_tree().get_root().get_node_or_null("WorldManager/HUD/FloatingNotificationManager")

	if _has_required_items():
		_remove_items_from_inventory()

		# 🔹 Dar recompensas
		var player = get_tree().get_first_node_in_group("player")
		var mission = mission_state.mission
		player.gain_experience(mission.rewards_xp)

		for reward_entry in mission.rewards_items:
			var item_id := ""
			var amount := 1

			if typeof(reward_entry) == TYPE_DICTIONARY:
				item_id = reward_entry.get("id", "")
				amount = reward_entry.get("amount", 1)
			elif typeof(reward_entry) == TYPE_STRING:
				item_id = reward_entry

			if item_id == "":
				continue

			var reward_item = ItemDataBase.get_item_by_name(item_id)
			if reward_item == null:
				print("⚠️ No se encontró el item de recompensa:", item_id)
				continue

			# 🔸 Si es una moneda (CoinData) → usar Playerwallet
			if reward_item is CoinData:
				await get_tree().process_frame  # Esperar un frame por seguridad

				var wallet = get_node_or_null("/root/Playerwallet")
				if wallet:
					wallet.add_coins(reward_item.coin_id, amount)
					print("💰 Moneda agregada al wallet:", reward_item.coin_name, "x", amount)
				else:
					print("⚠️ No se pudo acceder al Playerwallet desde el árbol (/root/Playerwallet)")


			# 🔸 Si es un ítem normal → usar el inventario
			elif reward_item.has_method("get_class"):
				if player.has_method("add_item_to_inventory"):
					player.add_item_to_inventory(reward_item, amount)
					print("🎒 Item agregado al inventario:", reward_item.resource_path, "x", amount)

		emit_signal("mission_delivered", mission_state)
		floating.show_message("🎉 Misión entregada: %s" % mission_state.mission.name, Color.GREEN)

	else:
		floating.show_message("⚠️ No cumples los requisitos de la misión", Color.ORANGE)

# --- Verificar si el jugador tiene los objetos requeridos ---
func _has_required_items() -> bool:
	if not mission_state or not mission_state.mission:
		return false
	var mission = mission_state.mission
	if not (mission is CollectMission):
		return false

	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return false

	var item_res = ItemDataBase.get_item_by_name(mission.item_required)
	var count = 0
	for slot in player.inventory:
		if slot and slot.has("item_data") and slot["item_data"]:
			var item_data = slot["item_data"]
			if item_data.resource_path == item_res.resource_path:
				count += slot["amount"]

	print("🧮 Verificando entrega: %s → %d / %d" % [mission.item_required, count, mission.amount_required])
	return count >= mission.amount_required


# --- Eliminar objetos del inventario ---
func _remove_items_from_inventory():
	var mission = mission_state.mission
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var item_res = ItemDataBase.get_item_by_name(mission.item_required)
	var to_remove = mission.amount_required

	for i in range(player.inventory.size()):
		var slot = player.inventory[i]
		if not slot:
			continue
		if slot["item_data"].resource_path == item_res.resource_path:
			var amount = slot["amount"]
			if amount > to_remove:
				slot["amount"] -= to_remove
				to_remove = 0
			else:
				to_remove -= amount
				player.inventory[i] = null
			if to_remove <= 0:
				break

	player.emit_signal("inventory_updated", player.inventory)
	print("🧾 Objetos de misión eliminados del inventario.")


func set_deliver_button_visible(value: bool) -> void:
	if is_instance_valid(deliver_button):
		deliver_button.visible = value
