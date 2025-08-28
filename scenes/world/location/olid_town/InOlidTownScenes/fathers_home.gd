extends Node2D

func _ready() -> void:
	var letter_item = $Items/letterItem
	letter_item.connect("letter_opened", Callable(self, "_on_letter_opened"))

func _on_letter_opened(pages: Array[String]) -> void:
	var letter_ui_scene = preload("res://items/letterItem/letter_ui.tscn")
	var letter_ui = letter_ui_scene.instantiate()
	$CanvasLayer.add_child(letter_ui)
	letter_ui.call_deferred("set_pages", pages)
	
	print(letter_ui)                 
	print(letter_ui.get_class())     
	print(letter_ui.get_script())    
	print(letter_ui.has_node("RichTextLabel"))  # 👈 ahora checa RichTextLabel en vez de Label
