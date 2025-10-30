extends Button

signal slot_pressed(slot_index: int)

@export var slot_index: int = 1
@onready var label_title: Label = $VBoxContainer/LabelTitle
@onready var label_info: Label = $VBoxContainer/LabelInfo

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL

	pressed.connect(_on_pressed)
	refresh_info()

func _on_pressed() -> void:
	print("🎯 Slot", slot_index, "presionado")
	emit_signal("slot_pressed", slot_index)

func refresh_info() -> void:
	var save_path: String = "user://saves/slot%d.json" % slot_index
	if not FileAccess.file_exists(save_path):
		_set_label_text_safe("Slot %d - Vacío" % slot_index, "Sin datos guardados")
		return

	var file := FileAccess.open(save_path, FileAccess.READ)
	if not file:
		_set_label_text_safe("Slot %d - Corrupto" % slot_index, "Error al abrir archivo")
		return

	var json_text: String = file.get_as_text()
	file.close()

	# Intentamos parsear JSON y asegurarnos de que sea Dictionary
	var parsed = JSON.parse_string(json_text)
	var data: Dictionary = {}
	if typeof(parsed) == TYPE_DICTIONARY:
		data = parsed
	else:
		# En algunos contextos JSON.parse_string devuelve un objeto con .result
		# Intentamos coger parsed.result si existe y es Dictionary
		if parsed and typeof(parsed) == TYPE_OBJECT and parsed.has("result") and typeof(parsed.result) == TYPE_DICTIONARY:
			data = parsed.result
		else:
			_set_label_text_safe("Slot %d - Corrupto" % slot_index, "Error al leer archivo")
			return

	# Ahora ya tenemos data como Dictionary (o un fallback vacío)
	# Declaramos tipos explícitos al extraer
	var scene_path: String = str(data.get("scene_path", "???"))
	var player_data: Dictionary = data.get("player", {}) as Dictionary

	# Aseguramos level como entero
	var level_value = player_data.get("level", 1)
	var level: int = 1
	# level_value podría venir como float, string, etc. Convertimos de forma segura:
	if typeof(level_value) == TYPE_FLOAT or typeof(level_value) == TYPE_INT:
		level = int(level_value)
	else:
		# intentar parsear si viene como string numérico
		level = int(str(level_value))

	# Obtener nombre legible para la escena usando SceneNames autoload (si existe)
	var scene_display_name: String = ""
	if Engine.has_singleton("SceneNames"):
		scene_display_name = SceneNames.get_display_name(scene_path)
	else:
		# fallback: sacar el nombre de archivo legible
		scene_display_name = scene_path.get_file().get_basename().capitalize()

	# Mostrar info en labels (usando helper seguro)
	_set_label_text_safe("Slot %d - Nivel %d" % [slot_index, level], scene_display_name)

	print("📁 Refrescado Slot", slot_index, "→", scene_display_name, "(Nivel:", level, ")")

# Helper para asignar texto solo si los labels existen
func _set_label_text_safe(title_text: String, info_text: String) -> void:
	if label_title:
		label_title.text = title_text
	else:
		print("⚠️ label_title ausente; titulo sería:", title_text)
	if label_info:
		label_info.text = info_text
	else:
		print("⚠️ label_info ausente; info sería:", info_text)
