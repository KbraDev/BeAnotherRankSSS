extends Control ##Mission_card
signal mission_accepted(mission: Mission)

@onready var title_label = $Panel/Title
@onready var desc_label = $Panel/Description
@onready var reward_label = $Panel/Reward
@onready var rank_label = $Panel/Rank
@onready var accept_button = $Panel/Button

var mission: Mission

func _ready():
	if mission:
		_update_ui()
	accept_button.pressed.connect(_on_accept_pressed)

func set_mission(m: Mission):
	mission = m
	if is_inside_tree():
		_update_ui() # Si ya está listo, actualiza de inmediato

func _update_ui():
	title_label.text = mission.name
	desc_label.text = mission.description
	reward_label.text = "XP: %s | Monedas: %s" % [mission.rewards.xp, mission.rewards.coins]
	rank_label.text = "Rango: %s" % mission.rank

func _on_accept_pressed():
	emit_signal("mission_accepted", mission)
