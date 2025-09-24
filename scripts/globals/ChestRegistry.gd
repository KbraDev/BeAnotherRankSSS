# ChestRegistry.gd
extends Node

# Guardamos el estado de cada cofre por su ID
var opened_chests: Dictionary = {}

func is_opened(chest_id: String) -> bool:
	return opened_chests.get(chest_id, false)

func set_opened(chest_id: String) -> void:
	opened_chests[chest_id] = true
