extends Control ##Mission_card
signal mission_accepted(mission: MissionResource)

@onready var title_label = $Panel/Title
@onready var desc_label = $Panel/Description
@onready var reward_label = $Panel/Reward
@onready var rank_label = $Panel/Rank
@onready var accept_button = $Panel/Button

var mission: MissionResource

func _ready():
	if mission:
		_update_ui()
	accept_button.pressed.connect(_on_accept_pressed)

func set_mission(m: Resource):
	mission = m
	if is_inside_tree():
		_update_ui() # Si ya está listo, actualiza de inmediato

func _update_ui():
	title_label.text = mission.name
	desc_label.text = mission.description
	rank_label.text = "Rango: %s" % mission.rank

	# 🧾 Texto de recompensas
	var rewards_text = "Recompensas:\n"
	rewards_text += "XP: %s\n" % mission.rewards_xp

	# 🪙 Mostrar objetos si hay
	if mission.rewards_items.size() > 0:
		for reward in mission.rewards_items:
			if typeof(reward) == TYPE_DICTIONARY and reward.has("id") and reward.has("amount"):
				var item_id = reward["id"]
				var amount = reward["amount"]

				# Intentamos obtener el nombre legible desde el ItemDatabase
				var display_name = item_id
				if Engine.has_singleton("ItemDatabase"):
					var item_res = ItemDataBase.get_item_by_name(item_id)
					if item_res and item_res.has_meta("display_name"):
						display_name = item_res.get_meta("display_name")
					elif item_res and item_res.has("item_name"):
						display_name = item_res.item_name

				rewards_text += "- %s (%s)\n" % [display_name, amount]
			elif typeof(reward) == TYPE_STRING:
				rewards_text += "- %s\n" % reward

	reward_label.text = rewards_text

func _on_accept_pressed():
	emit_signal("mission_accepted", mission)
