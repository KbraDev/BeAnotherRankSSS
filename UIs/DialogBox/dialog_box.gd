extends Control

@onready var dialog_label = $Panel/Label
@onready var next_icon = $InteractUI   

var dialog_lines: Array[String] = []
var current_line: int = 0
var is_showing := false
var finished := false

signal dialog_finished

func _ready() -> void:
	visible = false
	# El next_icon es decorativo, no tiene señal de botón
	if next_icon:
		next_icon.visible = false


func show_dialog(texts: Array) -> void:
	dialog_lines = texts
	current_line = 0
	finished = false
	is_showing = true
	visible = true
	
	if next_icon:
		next_icon.visible = true
	
	_display_current_line()


func _display_current_line() -> void:
	dialog_label.text = dialog_lines[current_line]


func _on_next_button_pressed() -> void:
	# Avanzar diálogo
	if current_line < dialog_lines.size() - 1:
		current_line += 1
		_display_current_line()
	else:
		# Diálogo terminado
		finished = true
		is_showing = false
		if next_icon:
			next_icon.visible = false
		emit_signal("dialog_finished")
		hide_dialog()


func hide_dialog() -> void:
	visible = false
	is_showing = false
	dialog_lines = []
	current_line = 0
	
	if next_icon:
		next_icon.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not is_showing:
		return
	
	if event.is_action_pressed("interact"):
		_on_next_button_pressed()
