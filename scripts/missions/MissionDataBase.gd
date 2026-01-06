extends Node
class_name MissionDatabase

const MISSION_LIST_PATH := "res://MissionResource/mission_list/mission_list.tres"

var mission_list: MissionList
var all_missions: Array[MissionResource] = []

func _ready():
	print("🧭 MissionDatabase READY")

	mission_list = load(MISSION_LIST_PATH)

	if mission_list:
		all_missions = mission_list.missions.duplicate()
		print("✅ Misiones cargadas:", all_missions.size())
	else:
		push_error("❌ No se pudo cargar MissionList")

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
