extends Control

@onready var dialog_label = $Panel/Label
@onready var next_button = $Panel/Button  

var dialog_lines := []
var current_line: int = 0
var is_showing := false
var finished = false

signal dialog_finished

func _ready() -> void:
	visible = false
	next_button.pressed.connect(_on_next_button_pressed)

func show_dialog(texts: Array) -> void:
	dialog_lines = texts
	current_line = 0
	finished = false
	visible = true
	is_showing = true
	_display_current_line()


func _display_current_line():
	dialog_label.text = dialog_lines[current_line]

func _on_next_button_pressed():
	if current_line < dialog_lines.size() - 1:
		current_line += 1
		_display_current_line()
	elif not finished:
		finished = true
		emit_signal("dialog_finished")



func hide_dialog():
	visible = false
	is_showing = false
	dialog_lines = []
	current_line = 0


func _unhandled_input(event: InputEvent) -> void:
	if is_showing and event.is_action_pressed("interact"):
		_on_next_button_pressed()
