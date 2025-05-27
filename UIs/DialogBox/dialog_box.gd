extends Control

@onready var dialog_label = $Panel/Label
@onready var next_button = $Panel/Button  # Asegúrate que se llama así

var dialog_lines := []
var current_line: int = 0
var is_showing := false

signal dialog_finished

func _ready() -> void:
	visible = false
	next_button.pressed.connect(_on_next_button_pressed)

func show_dialog(texts: Array) -> void:
	dialog_lines = texts
	current_line = 0
	visible = true
	is_showing = true
	_display_current_line()

func _display_current_line():
	if current_line < dialog_lines.size():
		dialog_label.text = dialog_lines[current_line]
	else:
		hide_dialog()
		emit_signal("dialog_finished")

func _on_next_button_pressed():
	current_line += 1
	_display_current_line()

func hide_dialog():
	visible = false
	is_showing = false
	dialog_lines = []
	current_line = 0


func _unhandled_input(event: InputEvent) -> void:
	if is_showing and event.is_action_pressed("interact"):
		_on_next_button_pressed()
