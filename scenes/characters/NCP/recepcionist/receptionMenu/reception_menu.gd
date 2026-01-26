extends Control ## RECEPTION MENu

signal option_selected(option: String)

@onready var select_button = $"Panel/VBoxContainer/Button(SelectMIsion)"
@onready var deliver_button = $"Panel/VBoxContainer/Button(EntertMision)"
@onready var exit_button = $"Panel/VBoxContainer/Button(Salir)"

func _ready():
	select_button.pressed.connect(_on_select_pressed)
	deliver_button.pressed.connect(_on_deliver_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	visible = false

func open():
	visible = true

func close():
	visible = false

func _on_select_pressed():
	print("Seleccionar presionado")
	emit_signal("option_selected", "Select task")

func _on_deliver_pressed():
	print("Entregar presionado")
	emit_signal("option_selected", "Deliver task")

func _on_exit_pressed():
	print("Salir presionado")
	emit_signal("option_selected", "Nothing")
