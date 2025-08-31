extends Node

var badges: Dictionary = {}

func add_badge(name: String) -> void:
	badges[name] = true

func has_badge(name: String) -> bool:
	return badges.get(name, false)
