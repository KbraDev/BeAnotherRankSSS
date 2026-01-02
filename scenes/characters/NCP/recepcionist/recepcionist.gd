extends CharacterBody2D
## Script de la recepcionista del gremio.


@onready var animation = $AnimatedSprite2D
@onready var interacUIAnimation = $InteractUI

@onready var dialog_box: DialogBox = get_tree().get_root().get_node(
	"WorldManager/HUD/DialogBox"
)
@onready var menu_ui = get_tree().get_root().get_node(
	"WorldManager/HUD/ReceptionMenu"
)
@onready var mission_menu = get_tree().get_root().get_node(
	"WorldManager/HUD/MissionSelectedMenu"
)
@onready var mission_delivery_menu = get_tree().get_root().get_node(
	"WorldManager/HUD/MissionDeliveryMenu"
)

var player_in_range := false
var player_rank := "E"

var player: Node = null

## Control de flujo
var dialog_started_by_receptionist := false

# -------------------------------------------------

func _ready() -> void:
	animation.play("front")
	interacUIAnimation.visible = false
	menu_ui.visible = false

	dialog_box.dialog_finished.connect(_on_dialog_finished)
	menu_ui.option_selected.connect(_on_menu_option_selected)
	mission_delivery_menu.mission_delivered_event.connect(
		_on_mission_delivered_from_menu
	)

# -------------------------------------------------
# DIÁLOGO
# -------------------------------------------------

func _on_dialog_finished() -> void:
	if dialog_started_by_receptionist:
		dialog_started_by_receptionist = false
		menu_ui.open()

# -------------------------------------------------
# MENÚ
# -------------------------------------------------

func _on_menu_option_selected(option: String) -> void:
	menu_ui.close()

	match option:
		"seleccionar":
			var missions = MissionDataBase.get_missions_for_rank(player_rank)

			var active = MissionTracker.get_active_mission()
			var active_ids = active.map(func(m): return m.mission.id)

			var filtered = missions.filter(
				func(m): return not active_ids.has(m.id)
			)

			mission_menu.open(filtered)

		"entregar":
			var active = MissionTracker.get_active_mission()
			mission_delivery_menu.open(active)

		"salir":
			_restore_player()

# -------------------------------------------------

func _on_mission_delivered_from_menu(_state) -> void:
	mission_delivery_menu.close()

# -------------------------------------------------
# ÁREAS
# -------------------------------------------------

func _on_interact_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		player_in_range = true
		interacUIAnimation.visible = true

func _on_interact_area_body_exited(body: Node2D) -> void:
	if body == player:
		player_in_range = false
		interacUIAnimation.visible = false

		if dialog_box.is_showing:
			dialog_box._finish_dialog()

		_restore_player()
		player = null

# -------------------------------------------------
# INPUT
# -------------------------------------------------

func _process(_delta: float) -> void:
	if not player_in_range:
		return

	if Input.is_action_just_pressed("interact"):
		if dialog_box.is_showing or menu_ui.visible:
			return

		if player and player.attack_controller:
			player.attack_controller.lock_attacks()

		dialog_started_by_receptionist = true

		var dialog_lines: Array[String] = [
			"¡Bienvenido!, ¿Cómo podemos ayudarle hoy?",
			"Tenemos nuevas misiones disponibles."
		]

		dialog_box.show_dialog(dialog_lines)


# -------------------------------------------------
# UTILIDAD
# -------------------------------------------------

func _restore_player() -> void:
	if player and player.attack_controller:
		player.attack_controller.unlock_attacks()
