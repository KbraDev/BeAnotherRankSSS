extends Control

var player = null

@onready var stats_list := $RightPanel/MainBox/ScrollContainer/StatsList
@onready var playerAnim = $RightPanel/MainBox/PlayerPreview
@onready var points_label := $RightPanel/MainBox/PointsLabel
@onready var level_label = $RightPanel/MainBox/LevelBarContainer/Level
@onready var next_level_label = $RightPanel/MainBox/LevelBarContainer/NextLevel
@onready var experience_bar = $RightPanel/MainBox/LevelBarContainer/XpBar

@onready var coins_container = $RightPanel/MainBox/CoinsContainer
@onready var bronze_icon = $RightPanel/MainBox/CoinsContainer/BronzeRow/BronzeIcon
@onready var bronze_label = $RightPanel/MainBox/CoinsContainer/BronzeRow/BronzeLabel
@onready var silver_icon = $RightPanel/MainBox/CoinsContainer/SilverRow/SilverIcon
@onready var silver_label = $RightPanel/MainBox/CoinsContainer/SilverRow/SilverLabel
@onready var gold_icon = $RightPanel/MainBox/CoinsContainer/GoldRow/GoldIcon
@onready var gold_label = $RightPanel/MainBox/CoinsContainer/GoldRow/GoldLabel

@onready var active_mission_container = $LeftPanel/ActiveMissionBox
var ActiveMissionCardScene = preload("res://UIs/ActiveMissionsMenu/active_mission_card.tscn")

# alias para mapear nombres UI -> campos reales del player
var stat_aliases := {
	"salud": "health",
	"velocidad": "speed",
	"fuerza": "strength",
	"resistencia": "resistence",
	"mana": "mana",
	"poder_magico": "magical_power",
	"r._magica": "magical_res",
	"suerte": "lucky"
}

func _ready():
	visible = false
	await get_tree().process_frame

	player = get_tree().get_first_node_in_group("player")
	if player == null:
		print("⚠️ No se encontró el jugador. Cancelando setup.")
		return

	playerAnim.play("default")

	# Conectar señal de cada fila para solicitar upgrade (asumimos que las filas emiten 'stat_upgrade_requested' con el nombre)
	for row in stats_list.get_children():
		if row.has_signal("stat_upgrade_requested"):
			row.connect("stat_upgrade_requested", Callable(self, "_on_stat_upgrade_requested"))

	# Conectar monedas
	Playerwallet.connect("coins_changed", Callable(self, "_update_coins"))
	_setup_coin_icons()
	_update_coins()
	_update_all_stats()

	# Conectar al MissionTracker
	var tracker = get_node_or_null("/root/MissionTracker")
	if tracker:
		if not tracker.mission_progress_updated.is_connected(_on_mission_progress_updated):
			tracker.mission_progress_updated.connect(_on_mission_progress_updated)
		if not tracker.mission_added.is_connected(_on_mission_added):
			tracker.mission_added.connect(_on_mission_added)
		if not tracker.mission_removed.is_connected(_on_mission_removed):
			tracker.mission_removed.connect(_on_mission_removed)
		_update_active_missions()

	# Asegurar refresh al abrir
	if not is_connected("visibility_changed", Callable(self, "_on_visibility_changed")):
		connect("visibility_changed", Callable(self, "_on_visibility_changed"))


# ---- manejo upgrades ----
func _on_stat_upgrade_requested(ui_stat_name: String) -> void:
	# ui_stat_name viene de la UI (ej: "salud", "velocidad")
	var key = ui_stat_name.to_snake_case()
	var real_stat = stat_aliases.get(key, key)
	if player:
		if player.upgrade_stat(real_stat):
			_update_all_stats()
	# si no pudo, no hacer nada (la UI de botones se actualiza en _update_all_stats)


func _update_all_stats():
	if player == null:
		print("⚠️ Player aún no está disponible.")
		return

	points_label.text = "Available Points: %d" % player.stat_points

	var max_values := {
		"healt": 300,
		"speed": 180,
		"strength": 40,
		"resistence": 60,
		"mana": 110,
		"magical_power": 80,
		"magical_res": 55,
		"lucky": 25
	}

	# Actualiza cada fila (suponiendo que cada row tiene: stat_name, set_progress(), UpgradeButton)
	for row in stats_list.get_children():
		var ui_name = row.stat_name.to_snake_case()
		var real_stat_name = stat_aliases.get(ui_name, ui_name)

		if not player.base_stats.has(real_stat_name):
			continue

		var value = player.base_stats[real_stat_name]
		var max = max_values.get(real_stat_name, 100)
		row.set_progress(value, max)

		var cost = player._get_stat_upgrade_cost(real_stat_name)
		# botón + habilitado si hay puntos y no llega al máximo
		if row.has_node("UpgradeButton"):
			row.UpgradeButton.disabled = player.stat_points < cost or player.stat_levels.get(real_stat_name, 1) >= 10

	# experiencia / etiquetas
	experience_bar.value = float(player.experience) / float(player.experience_to_next_level) * 100
	level_label.text = "Level: %d" % player.level
	next_level_label.text = "%d / %d" % [player.experience, player.experience_to_next_level]


func _setup_coin_icons():
	bronze_icon.texture = ItemDataBase.get_item_by_id("BronzeCoin").icon
	silver_icon.texture = ItemDataBase.get_item_by_id("SilverCoin").icon
	gold_icon.texture = ItemDataBase.get_item_by_id("GoldCoin").icon

func _update_coins():
	bronze_label.text = str(Playerwallet.get_coin_amount("BronzeCoin"))
	silver_label.text = str(Playerwallet.get_coin_amount("SilverCoin"))
	gold_label.text = str(Playerwallet.get_coin_amount("GoldCoin"))


# ====================
# == Active Missions ==
# ====================
func _on_mission_added(state: MissionState) -> void:
	print("Task added → updating stats panel")
	_update_active_missions()

func _on_mission_removed(state: MissionState) -> void:
	print("Task removed → updating stats panel")
	_update_active_missions()

func _on_mission_progress_updated(state: MissionState) -> void:
	for card in active_mission_container.get_children():
		if card.mission_state == state:
			card.refresh_progress()


func _update_active_missions():
	if not is_instance_valid(active_mission_container):
		return

	# limpiar previo
	for child in active_mission_container.get_children():
		child.queue_free()

	var tracker = get_node_or_null("/root/MissionTracker")
	if tracker == null:
		#print("⚠️ No se encontró el MissionTracker.")
		return

	var missions = tracker.get_active_mission()
	if missions.is_empty():
		# no mostrar nada; opcional: mostrar label "sin misiones"
		return

	for state in missions:
		var card = ActiveMissionCardScene.instantiate()
		card.set_mission_state(state)
		active_mission_container.add_child(card)
		#print("🟦 Card de misión añadida:", state.mission.name)

	# debug count
	await get_tree().process_frame
	#print("🧩 Total de cards en contenedor:", active_mission_container.get_child_count())


func _on_visibility_changed():
	if visible:
		_update_active_missions()
