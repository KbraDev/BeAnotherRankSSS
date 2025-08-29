extends Node2D

func _ready() -> void:
	var letter_item = $Items/letterItem
	letter_item.connect("letter_opened", Callable(self, "_on_letter_opened"))

func _on_letter_opened(pages: Array[String]) -> void:
	var letter_ui_scene = preload("res://items/letterItem/letter_ui.tscn")
	var letter_ui = letter_ui_scene.instantiate()
	$CanvasLayer.add_child(letter_ui)
	letter_ui.call_deferred("set_pages", pages)

	# Pausa el juego (excepto nodos marcados como "Process when paused")
	get_tree().paused = true
	letter_ui.process_mode = Node.PROCESS_MODE_ALWAYS  # para que la UI sí funcione
