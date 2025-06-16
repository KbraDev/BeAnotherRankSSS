extends Control

@onready var stats_list := $RightPanel/MainBox/StatsList
var player = null
@onready var playerAnim = $RightPanel/MainBox/PlayerPreview
@onready var points_label := $RightPanel/MainBox/PointsLabel
@onready var level_label = $RightPanel/MainBox/LevelBarContainer/Level
@onready var next_level_label = $RightPanel/MainBox/LevelBarContainer/NextLevel
@onready var experience_bar = $RightPanel/MainBox/LevelBarContainer/XpBar


func _ready():
	await get_tree().process_frame  # Espera un frame para asegurar que el jugador cargue
	player = get_tree().get_first_node_in_group("player")
	playerAnim.play("default")

	if player == null:
		print("⚠️ No se encontró el jugador. Cancelando setup.")
		return

	playerAnim.play("default")

	for row in stats_list.get_children():
		if row.has_signal("stat_upgrade_requested"):
			row.connect("stat_upgrade_requested", _on_stat_upgrade_requested)

	_update_all_stats()


func _on_stat_upgrade_requested(stat_name: String):
	if player and player.upgrade_stat(stat_name.to_snake_case()):
		_update_all_stats()

func _update_all_stats():
	if player != null:
		level_label.text = "Nivel: %d" % player.level
		next_level_label.text = "%d" % (player.level + 1)
		experience_bar.value = player.experience
		experience_bar.max_value = player.experience_to_next_level



	print("Actualizando stats UI")
	points_label.text = "Puntos disponibles: %d" % player.stat_points

	for row in stats_list.get_children():
		var name = row.stat_name.to_snake_case()
		if player.base_stats.has(name):
			var value = player.base_stats[name]
			var max = 300
			row.set_progress(value, max)

			var cost = player.get_upgrade_cost(name)
			row.UpgradeButton.disabled = player.stat_points < cost
