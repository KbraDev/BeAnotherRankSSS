extends Panel
signal request_back(resume_game)  # Envía true si se carga partida, false si solo se regresa

@onready var back_button = $VBoxContainer/back_button


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


# --- Guardar partida ---
func _on_slot_pressed(slot_index: int) -> void:
	var player := get_tree().get_current_scene().get_node_or_null("player")
	if not player:
		return

	# Guardar el estado actual del jugador en el slot seleccionado
	SaveManager.save_game(player, slot_index)
	refresh_slots()

	# Mantener el juego en pausa, solo regresamos al menú de pausa
	emit_signal("request_back", false)
