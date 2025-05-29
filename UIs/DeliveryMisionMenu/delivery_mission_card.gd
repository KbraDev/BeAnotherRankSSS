extends Control
signal mission_delivered(mission_state: MissionState)

@onready var title_label = $Panel/Title
@onready var desc_label = $Panel/Description
@onready var reward_label = $Panel/Reward
@onready var rank_label = $Panel/Rank
@onready var deliver_button = $Panel/Button

var mission_state: MissionState

func _ready() -> void:
	deliver_button.pressed.connect(_on_DeliverButton_pressed)

func set_mission_state(state: MissionState):
	mission_state = state
	_update_ui()

func _update_ui():
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
	return true  # Aquí conectaremos el inventario real luego

func _remove_items_from_inventory():
	pass
