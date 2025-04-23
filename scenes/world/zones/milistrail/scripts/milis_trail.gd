extends Node2D

func _ready() -> void:
	var gate_name = GateManager.consume_gate_name()
	if gate_name != "":
		var gate = $Gates.get_node_or_null(gate_name)
		if gate:
			$player.global_position = gate.global_position
			
