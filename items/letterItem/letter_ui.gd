extends Control

@onready var text_label = $Label
@onready var next_button = $next
@onready var prev_button = $prev
@onready var close_button = $Close

var pages: Array[String] = []
var current_page: int = 0

func set_pages(new_pages: Array[String]) -> void:
	pages = new_pages
	current_page = 0
	update_page()

func update_page() -> void:
	if pages.size() > 0:
		text_label.text = pages[current_page]
	else:
		text_label.text = "Sin contenido."

	# Botones de navegación
	prev_button.visible = current_page > 0
	next_button.visible = current_page < pages.size() - 1

func _on_next_pressed() -> void:
	if current_page < pages.size() - 1:
		current_page += 1
		update_page()

func _on_prev_pressed() -> void:
	if current_page > 0:
		current_page -= 1
		update_page()


func _on_close_pressed() -> void:
	
