# Mission.gd
extends Resource
class_name MissionResource

@export var id: String
@export var name: String
@export_multiline var description: String
@export var rank: String = "E"
@export var mission_type: String = "base"
@export var required_rank: String = "E"
@export var rewards_xp: int = 0
@export var rewards_items = [
	{"id": "BronzeCoin", "amount": 10},
]
