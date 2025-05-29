extends CharacterBody2D

@onready var animation = $AnimatedSprite2D
@onready var interacUIAnimation = $InteractUI
var player_in_range = false
var player_rank = "E"

@onready var dialog_box =  get_tree().get_root().get_node("WorldManager/HUD/DialogBox")
@onready var menu_ui = get_tree().get_root().get_node("WorldManager/HUD/ReceptionMenu")
@onready var mission_menu = get_tree().get_root().get_node("WorldManager/HUD/MissionSelectedMenu")
@onready var mission_delivery_menu = get_tree().get_root().get_node("WorldManager/HUD/MissionDeliveryMenu")



func _ready():
	animation.play("front")
	interacUIAnimation.visible = false
	dialog_box.dialog_finished.connect(_on_dialog_finished)
	menu_ui.option_selected.connect(_on_menu_option_selected)

func _on_dialog_finished():
	print("Dialogo terminado, abriendo menu de opciones")
	menu_ui.open()

func _on_menu_option_selected(option: String):
	print("🟡 Opción seleccionada:", option)

	match option:
		"seleccionar":
			print("🔵 Preparando menú de selección...")
			var mission_db = get_tree().get_root().get_node("WorldManager/MissionDatabase")
			var missions = mission_db.get_missions_for_rank(player_rank)
			print("📦 Misiones encontradas:", missions.size())
			mission_menu.open(missions)

		"entregar":
			print("🔴 Preparando menú de entrega...")
			var active = MissionTracker.get_active_mission()
			print("📬 Misiones activas:", active.size())
			mission_delivery_menu.open(active)

		"salir":
			print("⚪ Cerrando menú y diálogo.")
			menu_ui.close()
			dialog_box.hide_dialog()



func _on_interact_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		interacUIAnimation.visible = true
		player_in_range = true


func _on_interact_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		interacUIAnimation.visible = false
		player_in_range = false
		if dialog_box.is_showing:
			dialog_box.hide_dialog()

func _process(delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		if not dialog_box.is_showing:
			dialog_box.show_dialog([
				"¡Bienvenido!",
				"¿Cómo podemos ayudarle hoy?",
				"Tenemos nuevas misiones disponibles."
			])

	
func is_mission_compatible(player_rank: String, mission_rank: String) -> bool:
	var rank_compatibility = {
		"E": ["E", "D"],
		"D": ["E", "D", "C"],
		"C": ["C", "B"],
		"B": ["B", "A"],
		"A": ["A", "A+"],
		"A+": ["A+"],
		"S": ["A", "A+", "S"],
		"SS": ["A+", "S", "SS"],
		"SSS": ["SSS"]
	}
	return mission_rank in rank_compatibility.get(player_rank, [])
