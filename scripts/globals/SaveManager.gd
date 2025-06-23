extends Node

const SAVE_FOLDER := "user://saves/"
const SLOT_PATHS := {
	1: SAVE_FOLDER + "slot1.json",
	2: SAVE_FOLDER + "slot2.json",
	3: SAVE_FOLDER + "slot3.json"
}

func save_game(player: Node, slot: int = 1 ) -> void:
	var wm = get_tree().current_scene  # WorldManager debería estar como escena raíz
	var scene_path = wm.current_world.scene_file_path  # usamos current_world directamente

	var data = {
		"scene_path": scene_path,
		"player": player.get_save_data()
	}

	# Crear carpeta si no existe
	DirAccess.make_dir_recursive_absolute(SAVE_FOLDER)

	var file = FileAccess.open(SLOT_PATHS[slot], FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))  # con identación para debug
	file.close()
	print("✅ Partida guardada en slot ", slot)
	print("💾 Escena guardada:", scene_path)

func load_game(slot: int = 1) -> Dictionary:
	if not FileAccess.file_exists(SLOT_PATHS[slot]):
		push_error("❌ Archivo de guardado no encontrado para slot %d" % slot)
		return {}

	var file = FileAccess.open(SLOT_PATHS[slot], FileAccess.READ)
	var json = file.get_as_text()
	file.close()

	var result = JSON.parse_string(json)
	if typeof(result) != TYPE_DICTIONARY:
		push_error("❌ Error al leer el archivo de guardado.")
		return {}

	return result

func load_slot_and_restore(slot: int):
	var save_data = load_game(slot)
	if save_data.is_empty():
		print("❌ No se pudo cargar el slot ", slot)
		return

	var scene_path = save_data.get("scene_path", "")
	if scene_path == "":
		print("❌ No se especificó ninguna escena.")
		return

	get_tree().paused = false

	var wm = get_tree().current_scene
	if wm:
		await wm.load_game_state(save_data)
	else:
		print("❌ WorldManager no está activo como escena actual.")
