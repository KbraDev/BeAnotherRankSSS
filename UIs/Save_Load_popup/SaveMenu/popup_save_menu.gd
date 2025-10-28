extends Panel

signal request_back

@onready var slot1 = $VBoxContainer/HBoxContainer/Slot
@onready var slot2 = $VBoxContainer/HBoxContainer/Slot2
@onready var slot3 = $VBoxContainer/HBoxContainer/Slot3
@onready var back_button = $VBoxContainer/back_button

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL

	# Conexiones
	slot1.pressed.connect(func(): _on_slot_pressed(1))
	slot2.pressed.connect(func(): _on_slot_pressed(2))
	slot3.pressed.connect(func(): _on_slot_pressed(3))
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

	print("💾 Popup de guardado listo")

func _on_back_pressed():
	print("↩️ Botón 'Regresar' PRESSED en Guardar")
	emit_signal("request_back")

func _on_slot_pressed(slot_index: int) -> void:
	print("💾 Guardar en slot:", slot_index)
	var player = get_tree().get_current_scene().get_node_or_null("player")
	if not player:
		push_error("❌ No se encontró el nodo 'player' en la escena actual.")
		return

	SaveManager.save_game(player, slot_index)
	print("✅ Partida guardada correctamente en slot", slot_index)
	emit_signal("request_back")

func refresh_slots() -> void:
	# Aquí luego agregarás thumbnails e info del slot
	pass
