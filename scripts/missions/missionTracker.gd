extends Node ##missionTracker

var active_mission: Array[MissionState] = []


func add_mission(mission: Mission) -> bool:
	# Verificar que no exceda el limite de misiones segun el tipo
	var active_side = active_mission.filter(func(m): return m.mission.type == "side")
	var active_main = active_mission.filter(func(m): return m.mission.type == "main")

	# Límite por tipo
	if mission.type == "side" and active_side.size() >= 2:
		print("Límite de misiones secundarias activas alcanzado")
		return false
	elif mission.type == "main" and active_main.size() >= 1:
		print("Misión principal en curso")
		return false

	# Crear MissionState y agregarlo
	var state = MissionState.new()
	state.mission = mission
	state.time_started = Time.get_unix_time_from_system()
	state.status = "active"

	active_mission.append(state)

	return true 


func get_active_mission() -> Array[MissionState]:
	return active_mission

func fail_mission(state: MissionState):
	state.status = "failed"
	
func complete_mission(state: MissionState):
	state.status = "completed"

func remove_mission(state: MissionState):
	active_mission.erase(state)
