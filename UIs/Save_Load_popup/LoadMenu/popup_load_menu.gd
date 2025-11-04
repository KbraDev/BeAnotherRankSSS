extends Panel
signal request_back(resume_game)  # Envía true si se carga partida, false si solo se regresa

@onready var back_button = $VBoxContainer/back_button
var mode: String = "load"  # Puede ser "load" o "new_game"

# --- Inicialización ---
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Buscar contenedor de slots
	var hbox := get_node_or_null("VBoxContainer/HBoxContainer")
	if not hbox:
		return

	# Conectar dinámicamente cada slot
	var index := 1
	for child in hbox.get_children():
		if child.has_signal("slot_pressed"):
			child.slot_index = index
			child.slot_pressed.connect(_on_slot_pressed)
			index += 1

	# Conectar botón de regreso
	if back_button:
		back_button.pressed.connect(_on_back_pressed)


# --- Refrescar visualmente los slots ---
func refresh_slots() -> void:
	var hbox := get_node("VBoxContainer/HBoxContainer")
	for child in hbox.get_children():
		if child.has_method("refresh_info"):
			child.refresh_info()


# --- Volver al menú de pausa ---
func _on_back_pressed() -> void:
	emit_signal("request_back", false)


# --- Cargar partida seleccionada ---
func _on_slot_pressed(slot_index: int) -> void:
	var path := "user://saves/slot%d.json" % slot_index
		
	if mode == "load":
		if FileAccess.file_exists(path):
			get_tree().paused = false
			await SaveManager.load_existing_game(slot_index)


	elif mode == "new_game":
		# --- Crear nueva partida ---
		if FileAccess.file_exists(path):
			# ⚠️ Confirmación antes de sobrescribir
			var confirm := ConfirmationDialog.new()
			confirm.dialog_text = "¿Deseas sobrescribir la partida del Slot %d?" % slot_index
			add_child(confirm)
			confirm.confirmed.connect(func():
				_create_new_game(slot_index))
			confirm.popup_centered()
		else:
			_create_new_game(slot_index)


func _create_new_game(slot_index: int) -> void:
	get_tree().paused = false
	await SaveManager.start_new_game(slot_index)
