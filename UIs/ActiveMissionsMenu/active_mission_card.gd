extends Control
class_name ActiveMissionCard

@onready var title_label = $title
@onready var desc_label = $description
@onready var progress_bar = $ProgressBar
@onready var progress_label = $ProgressBar/progressLabel
@onready var reward_label = $reward
@onready var rank_label = $rank

var mission_state: MissionState

func set_mission_state(state: MissionState) -> void:
	mission_state = state
	await self.ready
	_update_ui()

func _update_ui():
	if not mission_state or not mission_state.mission:
		return

	var mission = mission_state.mission
	title_label.text = mission.name
	desc_label.text = mission.description
	rank_label.text = "Rango: %s" % mission.rank

	# 🧾 Mostrar recompensas
	var rewards_text = "Recompensas:\n"
	rewards_text += "XP: %s\n" % mission.rewards_xp

	if mission.rewards_items.size() > 0:
		for reward in mission.rewards_items:
			if typeof(reward) == TYPE_DICTIONARY and reward.has("id") and reward.has("amount"):
				var item_id = reward["id"]
				var amount = reward["amount"]

				var display_name = item_id
				var item_res = ItemDataBase.get_item_by_name(item_id)
				if item_res and "item_name" in item_res:
					display_name = item_res.item_name
				elif item_res and item_res.has_method("get_class"):
					if item_res.has_property("coin_name"):
						display_name = item_res.coin_name

				rewards_text += "- %s (%s)\n" % [display_name, amount]
			else:
				rewards_text += "- %s\n" % str(reward)

	reward_label.text = rewards_text

	# 📊 Progreso de misión (solo para misiones de recolección)
	if mission is CollectMission:
		progress_bar.max_value = mission.amount_required
		progress_bar.value = mission_state.progress
		progress_label.text = "%d / %d" % [mission_state.progress, mission.amount_required]

		if mission_state.status == "ready":
			progress_label.add_theme_color_override("font_color", Color.GREEN)
			progress_bar.add_theme_color_override("fill", Color.GREEN)
	else:
		progress_bar.visible = false
		progress_label.visible = false


# ✅ Refrescar progreso en tiempo real
func refresh_progress():
	if not mission_state or not mission_state.mission:
		return
	if mission_state.mission is CollectMission:
		progress_bar.value = mission_state.progress
		progress_label.text = "%d / %d" % [mission_state.progress, mission_state.mission.amount_required]

		if mission_state.status == "ready":
			progress_label.add_theme_color_override("font_color", Color.GREEN)
			progress_bar.add_theme_color_override("fill", Color.GREEN)
