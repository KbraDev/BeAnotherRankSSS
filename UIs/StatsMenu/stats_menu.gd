extends Control

var player = null

@onready var stats_list := $RightPanel/MainBox/ScrollContainer/StatsList
@onready var playerAnim = $RightPanel/MainBox/PlayerPreview
@onready var points_label := $RightPanel/MainBox/PointsLabel
@onready var level_label = $RightPanel/MainBox/LevelBarContainer/Level
@onready var next_level_label = $RightPanel/MainBox/LevelBarContainer/NextLevel
@onready var experience_bar = $RightPanel/MainBox/LevelBarContainer/XpBar

var stat_aliases := {
	"salud": "hp",
	"velocidad": "speed",
	"fuerza": "fuerza",
	"resistencia": "resistencia",
	"mana": "mana",
	"poder_magico": "poder_magico",
	"r._magica": "resistencia_hechizos",
	"suerte": "lucky"
}

func _ready():
	visible = false
	
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

func _process(_delta):
	if Input.is_action_just_pressed("StatsUI"):
		visible = !visible


func _on_stat_upgrade_requested(stat_name: String):
	var real_stat_name = stat_aliases.get(stat_name.to_snake_case(), stat_name.to_snake_case())
	if player and player.upgrade_stat(real_stat_name):
		_update_all_stats()




func _update_all_stats():
	if player == null:
		print("⚠️ Player aún no está disponible.")
		return

	points_label.text = "Puntos disponibles: %d" % player.stat_points

	var max_values := {
		"hp": 300,
		"speed": 180,
		"fuerza": 40,
		"resistencia": 60,
		"mana": 110,
		"poder_magico": 80,
		"resistencia_hechizos": 55,
		"lucky": 25
	}


	# ⚠️ Mapeo visible → real
	var stat_aliases := {
		"salud": "hp",
		"velocidad": "speed",
		"fuerza": "fuerza",
		"resistencia": "resistencia",
		"mana": "mana",
		"poder_magico": "poder_magico",
		"r._magica": "resistencia_hechizos",
		"suerte": "lucky"
	}

	for row in stats_list.get_children():
		var ui_name = row.stat_name.to_snake_case()
		var real_stat_name = stat_aliases.get(ui_name, ui_name)

		if not player.base_stats.has(real_stat_name):
			print("❌ Stat no encontrada:", real_stat_name)
			continue

		var value = player.base_stats[real_stat_name]
		var max = max_values.get(real_stat_name, 100)

		row.set_progress(value, max)

		var cost = player._get_stat_upgrade_cost(real_stat_name)
		row.UpgradeButton.disabled = player.stat_points < cost or player.stat_levels.get(real_stat_name, 1) >= 10

		
	# 🟦 Actualizar barra de experiencia y etiquetas
	experience_bar.value = float(player.experience) / float(player.experience_to_next_level) * 100
	level_label.text = "Nivel: %d" % player.level
	next_level_label.text = "%d / %d" % [player.experience, player.experience_to_next_level]
