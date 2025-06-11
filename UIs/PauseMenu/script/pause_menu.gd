extends CanvasLayer

@onready var panel = $Panel
@onready var close_menu = $Panel/VBoxContainer/Close

func _ready():
	set_process_input(true)
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	if visible:
		visible = false
		get_tree().paused = false
	else:
		visible = true
		get_tree().paused = true

func _on_salir_pressed():
	print("Salir al título (no implementado)")

func _on_close_pressed():
	toggle_pause()


func _on_save1_pressed() -> void:
	save_on_slot(1)

func _on_save_2_pressed() -> void:
	save_on_slot(2)


func _on_save_3_pressed() -> void:
	save_on_slot(3)

func save_on_slot(slot: int):
	var player = get_tree().get_current_scene().get_node("player")
	if player:
		SaveManager.save_game(player, slot)
	else:
		print("❌ No se encontró el nodo del jugador.")


## logica de carga

func _on_load_slot_1_pressed():
	load_from_slot(1)

func _on_load_slot_2_pressed():
	load_from_slot(2)

func _on_load_slot_3_pressed():
	load_from_slot(3)

func load_from_slot(slot: int):
	get_tree().paused = false
	visible = false
	SaveManager.load_slot_and_restore(slot)
