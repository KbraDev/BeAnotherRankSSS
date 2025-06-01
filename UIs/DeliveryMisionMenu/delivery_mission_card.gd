extends Control
signal mission_delivered(mission_state: MissionState)

@onready var title_label = $Panel/title
@onready var desc_label = $Panel/description
@onready var reward_label = $Panel/reward
@onready var rank_label = $Panel/rank
@onready var deliver_button = $Panel/Button

var mission_state: MissionState

func _ready():
	# Conectamos el botón aquí para evitar errores de timing
	if deliver_button and not deliver_button.pressed.is_connected(_on_DeliverButton_pressed):
		deliver_button.pressed.connect(_on_DeliverButton_pressed)

func set_mission_state(state: MissionState) -> void:
	mission_state = state

	# Esperamos a que el nodo esté completamente listo
	await self.ready
	_update_ui()

func _update_ui():
	print("\n🧪 Ejecutando _update_ui")
	print("🧩 mission_state:", mission_state)
	print("🧩 mission_state.mission:", mission_state.mission)

	if mission_state == null or mission_state.mission == null:
		print("❌ mission_state o mission está vacío.")
		return

	title_label.text = mission_state.mission.name
	desc_label.text = mission_state.mission.description
	reward_label.text = "XP: %s | Monedas: %s" % [mission_state.mission.rewards.xp, mission_state.mission.rewards.coins]
	rank_label.text = "Rango: %s" % mission_state.mission.rank
	deliver_button.disabled = mission_state.status != "active"

func _on_DeliverButton_pressed():
	if _has_required_items():
		_remove_items_from_inventory()
		emit_signal("mission_delivered", mission_state)
	else:
		print("⚠️ No cumples los requisitos de la misión")

func _has_required_items() -> bool:
	return true

func _remove_items_from_inventory():
	pass
