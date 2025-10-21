extends Node

class_name MissionDatabase

var all_missions: Array[MissionResource] = []

func _ready() -> void:
	load_all_missions("res://MissionResource/")

func load_all_missions(path: String):
	all_missions.clear()
	
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var full_path = path + "/" + file_name
				var mission = load(full_path)
				if mission is MissionResource:
					all_missions.append(mission)
			file_name = dir.get_next()
		dir.list_dir_end()
	else: 
		push_error("No se pudo abrir carpeta de misiones: " + path)
		
func get_missions_for_rank(player_rank: String, limit: int = 3) -> Array:
	var compatible = all_missions.filter(func(m):
		return is_mission_compatible(player_rank, m.rank)
	)
	compatible.shuffle()
	return compatible.slice(0, min(limit, compatible.size()))
	
	
func is_mission_compatible(player_rank: String, mission_rank: String) -> bool:
	var rank_compatibility = {
		"E": ["E", "D"],
		"D": ["E", "D", "C"],
		"C": ["C", "B"],
		"B": ["B", "A"],
		"A": ["A", "A+"],
		"A+": ["A+"],
		"S": ["A", "A+", "S"],
		"SS": ["A+", "S", "SS"],
		"SSS": ["SSS"]
	}
	return mission_rank in rank_compatibility.get(player_rank, [])
