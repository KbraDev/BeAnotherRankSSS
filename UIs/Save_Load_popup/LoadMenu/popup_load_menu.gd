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

	print("📂 Popup de carga listo")

func _on_back_pressed():
	print("↩️ Botón 'Regresar' PRESSED en Cargar")
	emit_signal("request_back")

func _on_slot_pressed(slot_index: int) -> void:
	print("📂 Intentando cargar slot:", slot_index)
	if not FileAccess.file_exists("user://saves/slot%d.json" % slot_index):
		print("⚠️ No hay partida guardada en el slot", slot_index)
		return

	print("✅ Cargando partida desde slot", slot_index)
	emit_signal("request_back")
	get_tree().paused = false
	SaveManager.load_slot_and_restore(slot_index)

func refresh_slots() -> void:
	pass
