# Mission.gd
extends Resource
class_name Mission

@export var id: int = 0
@export var name: String = ""
@export var description: String = ""
@export var rewards: MissionReward
@export var rank: String = ""
@export var type: String = ""  # "main" o "side"
