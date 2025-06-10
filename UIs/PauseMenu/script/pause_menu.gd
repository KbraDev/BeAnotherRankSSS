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


func _on_save_pressed() -> void:
	var player = get_tree().get_current_scene().get_node("player")  # O ajustá al path real
	if player:
		SaveManager.save_game(player, 1)
	else:
		print("❌ No se encontró el nodo del jugador.")


func _on_salir_pressed():
	print("Salir al título (no implementado)")

func _on_close_pressed():
	toggle_pause()
