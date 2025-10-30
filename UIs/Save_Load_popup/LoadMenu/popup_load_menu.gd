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


# --- Cargar partida seleccionada ---
func _on_slot_pressed(slot_index: int) -> void:
	var path := "user://saves/slot%d.json" % slot_index
	if not FileAccess.file_exists(path):
		return

	# Avisar al PauseMenu que debe cerrar y reanudar el juego
	emit_signal("request_back", true)

	# Reanudar el juego antes de cargar
	get_tree().paused = false

	# Cargar los datos del slot seleccionado
	SaveManager.load_slot_and_restore(slot_index)
