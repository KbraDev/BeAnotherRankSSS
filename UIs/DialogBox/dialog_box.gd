extends Control ## DialogBox

@onready var dialog_label = $Panel/Label

var is_showing := false

func _ready() -> void:
	visible = false

func show_dialog(text: String) -> void:
	visible = true
	dialog_label.text = text
	is_showing = true

func hide_dialog():
	visible = false
	is_showing = false
