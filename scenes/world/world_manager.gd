extends Node2D

@onready var player := $player
@onready var world_container := $WorldContainer

var current_world: Node = null

func _ready():
	current_world = world_container.get_child(0)

func change_world(scene_path: String, target_marker_name: String) -> void:
	# Limpieza total del contenedor
	for child in world_container.get_children():
		child.queue_free()
	await get_tree().process_frame

	# Cargar nuevo mundo
	var new_world = load(scene_path).instantiate()
	world_container.add_child(new_world)
	current_world = new_world

	# Buscar el marker de destino
	var marker = _find_marker_in(current_world, target_marker_name)
	if marker:
		player.global_position = marker.global_position
	else:
		print("❌ No se encontró el Marker2D de destino: ", target_marker_name)
	
	print("🧼 Confirmando nodos después del cambio:")
	for node in get_tree().get_nodes_in_group("slime"):
		print(" - ", node.name, " en ", node.get_parent().name)
		
	for s in get_tree().get_nodes_in_group("slime"):
		s.queue_free()


	
func _find_marker_in(node: Node, name: String) -> Node:
	for child in node.get_children():
		if child.name == name:
			return child
		var found = _find_marker_in(child, name)
		if found != null:
			return found
	return null
