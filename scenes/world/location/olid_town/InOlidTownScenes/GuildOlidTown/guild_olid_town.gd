extends Node2D

func _ready():
	if GameState.has_flag("ANGELER_INTRO_DONE"):
		if has_node("Angeler"):
			$Angeler.queue_free()
