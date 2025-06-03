extends Node

var cached_scenes := {}

func preload_scene(name: String, path: String) -> void:
	cached_scenes[name] = preload(path)

func get_scene(name: String) -> PackedScene:
	return cached_scenes.get(name)
