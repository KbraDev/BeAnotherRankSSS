extends Node

const SAVE_FOLDER := "user://saves/"
const SLOT_PATHS := {
	1: SAVE_FOLDER + "slot1.json",
	2: SAVE_FOLDER + "slot2.json",
	3: SAVE_FOLDER + "slot3.json"
}

func save_game(player: Node, slot: int = 1 ) -> void: 
	var data = {
	"scene_path": get_tree().current_scene.scene_file_path,
	"player": player.get_save_data()  # ✅ usamos tu método
	}
	# crear carpeta si no existe
	DirAccess.make_dir_recursive_absolute(SAVE_FOLDER)
	
	var file = FileAccess.open(SLOT_PATHS[slot], FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))  # con identación para debug
	file.close()
	print("✅ Partida guardada en slot ", slot)
	
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
