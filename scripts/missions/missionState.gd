# MissionState.gd
class_name MissionState
extends RefCounted

var mission: Resource  # <- no exportado, no necesita tipo específico
@export var time_started: float
@export var status: String = "active"
@export var progress: int = 0
