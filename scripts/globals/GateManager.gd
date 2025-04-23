extends Node ## GateManager

var next_gate_name: String = ""

func set_next_gate(name: String):
	next_gate_name = name
	
func consume_gate_name() -> String:
	var name = next_gate_name
	next_gate_name = "" # Limpiar despues de usar
	return name
