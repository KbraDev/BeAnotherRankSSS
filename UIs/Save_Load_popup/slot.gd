extends Button

signal slot_pressed(slot_index: int)

@export var slot_index: int = 1
@onready var label_title: Label = $VBoxContainer/LabelTitle
@onready var label_info: Label = $VBoxContainer/LabelInfo
@onready var thumbnail_rect: TextureRect = $VBoxContainer/Thumbnail


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL

	pressed.connect(_on_pressed)
	refresh_info()


func _on_pressed() -> void:
	emit_signal("slot_pressed", slot_index)


func refresh_info() -> void:
	var save_path: String = "user://saves/slot%d.json" % slot_index
	var thumbnail_path: String = "user://saves/slot%d_thumbnail.png" % slot_index

	# Si no existe guardado, limpiar todo
	if not FileAccess.file_exists(save_path):
		_set_label_text_safe("Slot %d - Vacío" % slot_index, "Sin datos guardados")
		thumbnail_rect.texture = null
		return

	# Cargar datos del JSON
	var file := FileAccess.open(save_path, FileAccess.READ)
	if not file:
		_set_label_text_safe("Slot %d - Corrupto" % slot_index, "Error al abrir archivo")
		return

	var json_text: String = file.get_as_text()
	file.close()

	# Parse JSON de forma segura y tipada
	var parsed = JSON.parse_string(json_text)
	var data: Dictionary = {}
	if typeof(parsed) == TYPE_DICTIONARY:
		data = parsed as Dictionary
	else:
		# JSON.parse_string puede devolver un objeto con .result en algunos contextos
		if parsed and typeof(parsed) == TYPE_OBJECT and parsed.has("result") and typeof(parsed.result) == TYPE_DICTIONARY:
			data = parsed.result as Dictionary
		else:
			_set_label_text_safe("Slot %d - Corrupto" % slot_index, "Error al leer archivo")
			return

	# Extraer información del guardado con tipos explícitos
	var scene_path: String = str(data.get("scene_path", "???"))
	var player_data: Dictionary = data.get("player", {}) as Dictionary

	# Nivel: convertir seguro a int
	var level_value = player_data.get("level", 1)
	var level: int = 1
	if typeof(level_value) == TYPE_FLOAT or typeof(level_value) == TYPE_INT:
		level = int(level_value)
	else:
		level = int(str(level_value))

	# Obtener nombre legible de la escena usando SceneNames (autoload) o fallback
	var scene_display_name: String = ""
	if Engine.has_singleton("SceneNames"):
		scene_display_name = SceneNames.get_display_name(scene_path)
	else:
		scene_display_name = scene_path.get_file().get_basename().capitalize()

	# Asignar textos
	_set_label_text_safe("Slot %d - Nivel %d" % [slot_index, level], scene_display_name)

	# Cargar thumbnail si existe (tipado correcto)
	if FileAccess.file_exists(thumbnail_path):
		var img: Image = Image.new()
		var err: int = img.load(thumbnail_path)
		if err == OK:
			var tex: ImageTexture = ImageTexture.create_from_image(img)
			thumbnail_rect.texture = tex
		else:
			thumbnail_rect.texture = null
	else:
		thumbnail_rect.texture = null


# Helper para asignar texto solo si los labels existen
func _set_label_text_safe(title_text: String, info_text: String) -> void:
	if label_title:
		label_title.text = title_text
	if label_info:
		label_info.text = info_text
