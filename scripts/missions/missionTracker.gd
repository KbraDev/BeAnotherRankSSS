extends Node ## MissionTracker

var active_mission: Array[MissionState] = []

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if not player.inventory_updated.is_connected(_on_inventory_updated):
			player.inventory_updated.connect(_on_inventory_updated)
	else:
		print("⚠️ No se encontró el jugador al iniciar MissionTracker")


# --- SEÑAL: inventario actualizado ---
func _on_inventory_updated(inventory_data: Array) -> void:
	for state in active_mission:
		if state.mission and state.mission is CollectMission:
			_check_collect_progress(state, inventory_data)


# --- REVISAR PROGRESO DE MISIONES DE RECOLECCIÓN ---
func _check_collect_progress(state: MissionState, inventory_data: Array) -> void:
	var mission = state.mission
	if not mission or not (mission is CollectMission):
		return
	
	if not mission.track_progress:
		return

	var current_amount = 0
	var item_res = ItemDataBase.get_item_by_name(mission.item_required)

	for slot in inventory_data:
		if slot and slot.has("item_data") and slot["item_data"]:
			var item_data = slot["item_data"]
			if item_res and item_data.resource_path == item_res.resource_path:
				current_amount += slot["amount"]

	# 🔹 Mensaje de depuración: progreso en tiempo real
	print("📦 Progreso misión '%s': %d / %d" % [mission.name, current_amount, mission.amount_required])

	state.progress = current_amount

	if current_amount >= mission.amount_required and state.status == "active":
		state.status = "ready"
		print("✅ Misión lista para entregar:", mission.name)

# --- AGREGAR MISION ---
func add_mission(mission: Resource) -> bool:
	if active_mission.size() >= 3:
		print("⚠️ Límite de misiones activas alcanzado")
		return false

	var state = MissionState.new()
	state.mission = mission
	state.time_started = Time.get_unix_time_from_system()
	state.status = "active"
	state.progress = 0

	active_mission.append(state)

	print("📜 Misión agregada al tracker: ", mission.name)
	print("   → Tipo:", mission.mission_type, "| Requiere:", mission.amount_required, mission.item_required)

	var player = get_tree().get_first_node_in_group("player")
	if player:
		_on_inventory_updated(player.inventory)

	return true


func get_active_mission() -> Array:
	return active_mission


func fail_mission(state: MissionState) -> void:
	state.status = "failed"


func complete_mission(state: MissionState) -> void:
	state.status = "completed"


func remove_mission(state: MissionState) -> void:
	active_mission.erase(state)
