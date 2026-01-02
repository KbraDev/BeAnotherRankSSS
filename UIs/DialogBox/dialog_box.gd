extends Control
class_name DialogBox

@onready var dialog_label: Label = $Panel/Label
@onready var next_icon: Control = $InteractUI
@onready var portrait_panel: Control = $PortraitPanel
@onready var portrait_rect: TextureRect = $PortraitPanel/DialogBoxPortrait

var dialog_lines: Array[String] = []
var current_line := 0
var is_showing := false

signal dialog_finished

func _ready() -> void:
	visible = false
	if next_icon:
		next_icon.visible = false
	portrait_panel.visible = false


func show_dialog(texts: Array[String], portrait: Texture2D = null) -> void:
	dialog_lines = texts
	current_line = 0
	is_showing = true
	visible = true

	# --- Portrait handling ---
	if portrait:
		portrait_rect.texture = portrait
		portrait_panel.visible = true
	else:
		portrait_rect.texture = null
		portrait_panel.visible = false

	if next_icon:
		next_icon.visible = true

	_display_current_line()


func _display_current_line() -> void:
	dialog_label.text = dialog_lines[current_line]


func _advance_dialog() -> void:
	if current_line < dialog_lines.size() - 1:
		current_line += 1
		_display_current_line()
	else:
		_finish_dialog()


func _finish_dialog() -> void:
	is_showing = false
	visible = false
	dialog_lines.clear()

	if next_icon:
		next_icon.visible = false

	portrait_panel.visible = false
	portrait_rect.texture = null

	emit_signal("dialog_finished")


func _unhandled_input(event: InputEvent) -> void:
	if not is_showing:
		return

	if event.is_action_pressed("interact"):
		_advance_dialog()


func hide_dialog() -> void:
	if not is_showing:
		return

	is_showing = false
	visible = false
	dialog_lines.clear()

	if next_icon:
		next_icon.visible = false

	portrait_panel.visible = false
	portrait_rect.texture = null
