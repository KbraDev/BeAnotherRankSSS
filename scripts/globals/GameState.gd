extends Node

var flags: Dictionary = {}

func set_flag(flag: String) -> void:
	flags[flag] = true

func has_flag(flag: String) -> bool:
	return flags.get(flag, false)

func clear_flag(flag: String) -> void:
	flags.erase(flag)
