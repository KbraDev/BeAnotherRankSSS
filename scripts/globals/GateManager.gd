extends Node ## GateManager

var next_gate_name: String = ""
var player_path: NodePath = "player" # Esto puede ser configurado si el jugador no esta en la raiz

func set_next_gate(name: String):
	next_gate_name = name
	
func consume_gate_name() -> String:
	var name = next_gate_name
	next_gate_name = "" # Limpiar despues de usar
	return name

func position_player_at_gate():
	var gate_name = consume_gate_name()
	if gate_name == "":
		return
	
	# Buscar Jugador
	var player = get_tree().current_scene.get_node_or_null(player_path)
	if not player:
		push_warning("No se encontro al jugador en la ruta: %s" % player_path)
		return
		
	# Buscar el gate de la escena cargado
	var gate = get_tree().current_scene.find_child(gate_name, true, true)
	if not gate:
		push_warning("NO se ceontro el gate con el nombre: %s" % gate_name)
		return
	
	player.global_position = gate.global_position
