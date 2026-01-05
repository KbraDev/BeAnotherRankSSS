extends Node2D

@onready var music = $AudioStreamPlayer2D

func _ready():
	music.play()
	
	if GameState.has_flag("ANGELER_INTRO_DONE"):
		if has_node("Angeler"):
			$Angeler.queue_free()
