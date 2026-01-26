extends Panel

signal request_back(resume_game: bool)

@onready var back_button = $VBoxContainer/back_button
var mode: String = "load"  # "new_game" o "load"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	refresh_slots()

	if back_button:
		back_button.pressed.connect(_on_back_pressed)


# --- Actualiza visualmente los slots ---
func refresh_slots() -> void:
	var hbox := get_node_or_null("VBoxContainer/HBoxContainer")
	if not hbox:
		return

	var index := 1
	for child in hbox.get_children():
		if child.has_signal("slot_pressed"):
			child.slot_index = index
			child.slot_pressed.connect(_on_slot_pressed)
			index += 1

		if child.has_method("refresh_info"):
			child.refresh_info()


# --- Botón atrás ---
func _on_back_pressed() -> void:
	print("↩️ Regresando al MainMenu...")
	emit_signal("request_back", false)


# --- Slot presionado ---
func _on_slot_pressed(slot_index: int) -> void:
	var path := "user://saves/slot%d.json" % slot_index
	
	if mode == "load":
		if FileAccess.file_exists(path):
			print("📂 Cargando partida desde slot %d" % slot_index)

			if Engine.has_singleton("TransitionOverlay"):
				await TransitionOverlay.fade_out()

			get_tree().paused = false
			await SaveManager.load_existing_game(slot_index)

			if Engine.has_singleton("TransitionOverlay"):
				await TransitionOverlay.fade_in()

			emit_signal("request_back", true)
			queue_free() # ✅ aquí sí
		else:
			print("⚠️ No existe guardado en slot %d" % slot_index)

	elif mode == "new_game":
		if FileAccess.file_exists(path):
			var confirm := ConfirmationDialog.new()
			confirm.dialog_text = "This is already a saved game.\nDo you want to overwrite it?\nPrevious data will be lost."
			add_child(confirm)

			# 🔹 Mostrar el popup centrado antes de conectar las señales
			confirm.popup_centered()

			confirm.confirmed.connect(func():
				print("✅ Confirmado: sobrescribiendo slot %d" % slot_index)
				_create_new_game(slot_index)
			)

			confirm.canceled.connect(func():
				print("❌ Cancelado: no se sobrescribirá el slot %d" % slot_index)
				emit_signal("request_back", false)
				queue_free() # ✅ solo si cancela
			)

		else:
			print("🆕 Creando nueva partida en slot %d" % slot_index)
			_create_new_game(slot_index)

# --- Crear nueva partida ---
func _create_new_game(slot_index: int) -> void:
	get_tree().paused = false

	if Engine.has_singleton("TransitionOverlay"):
		await TransitionOverlay.fade_out()

	await SaveManager.start_new_game(slot_index)

	if Engine.has_singleton("TransitionOverlay"):
		await TransitionOverlay.fade_in()

	emit_signal("request_back", true)
	queue_free()
