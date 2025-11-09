extends Node
## MissionTracker — Autoload global

signal mission_progress_updated(mission_state: MissionState)
signal mission_added(mission_state)
signal mission_removed(mission_state)

var active_mission: Array[MissionState] = []

func _ready() -> void:
	print("🧭 MissionTracker listo, esperando jugador...")
	# Intentar conectar si el jugador ya existe
	_try_connect_player()
	# Escuchar cuando se agreguen nuevos nodos (por si el jugador entra más tarde)
	get_tree().connect("node_added", Callable(self, "_on_node_added"))

# 🔹 Detectar cuando el jugador aparece en el árbol
func _on_node_added(node: Node) -> void:
	if node.is_in_group("player"):
		await get_tree().process_frame
		_try_connect_player()

# 🔹 Intentar conectar al jugador (si existe)
func _try_connect_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("⚠️ MissionTracker aún no encuentra al jugador.")
		return

	if not player.inventory_updated.is_connected(_on_inventory_updated):
		player.inventory_updated.connect(_on_inventory_updated)
		print("🔗 MissionTracker conectado al jugador correctamente.")
	else:
		print("♻️ MissionTracker ya estaba conectado al jugador.")

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

	state.progress = current_amount
	emit_signal("mission_progress_updated", state)
	print("📦 Progreso misión '%s': %d / %d" % [mission.name, current_amount, mission.amount_required])

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
	print("📜 Misión agregada al tracker:", mission.name)
	print("   → Tipo:", mission.mission_type, "| Requiere:", mission.amount_required, mission.item_required)

	emit_signal("mission_added", state)

	var player = get_tree().get_first_node_in_group("player")
	if player:
		_on_inventory_updated(player.inventory)
	else:
		print("⚠️ No se encontró jugador al agregar misión.")

	return true

# --- OTROS ---
func get_active_mission() -> Array:
	return active_mission

func fail_mission(state: MissionState) -> void:
	state.status = "failed"

func complete_mission(state: MissionState) -> void:
	state.status = "completed"

func remove_mission(state: MissionState) -> void:
	if state in active_mission:
		emit_signal("mission_removed", state)
		active_mission.erase(state)
		print("🗑️ Misión removida del tracker:", state.mission.name)
