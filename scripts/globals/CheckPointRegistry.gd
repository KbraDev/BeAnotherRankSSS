extends Node

var checkpoint_map: Dictionary = {}

func register_checkpoint(id: String, node: Node):
	checkpoint_map[id] = node

func unregister_checkpoint(id: String):
	checkpoint_map.erase(id)

func get_checkpoint(id: String) -> Node:
	if checkpoint_map.has(id):
		return checkpoint_map[id]
	return null
