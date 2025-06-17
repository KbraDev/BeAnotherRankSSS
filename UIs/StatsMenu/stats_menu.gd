extends Control

@onready var stats_list := $RightPanel/MainBox/ScrollContainer/StatsList
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
	if player == null:
		print("⚠️ Player aún no está disponible.")
		return

	points_label.text = "Puntos disponibles: %d" % player.stat_points

	var max_values := {
		"hp": 300,
		"speed": 160,
		"fuerza": 70,
		"resistencia": 80,
		"mana": 100,
		"poder_magico": 100,
		"resistencia_hechizos": 100,
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

		print("🔍 Procesando stat UI:", ui_name, "→ clave real:", real_stat_name)

		if not player.base_stats.has(real_stat_name):
			print("❌ Stat no encontrada:", real_stat_name)
			continue

		var value = player.base_stats[real_stat_name]
		var max = max_values.get(real_stat_name, 100)

		print("✅ Stat válida:", real_stat_name, "| Valor:", value, "| Máx:", max)
		row.set_progress(value, max)

		var cost = player.get_upgrade_cost(real_stat_name)
		row.UpgradeButton.disabled = player.stat_points < cost
