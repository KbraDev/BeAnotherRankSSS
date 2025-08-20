extends Control

@onready var quit_dialog = $ConfirmationDialog

func _ready():
	$CenterContainer/VBoxContainer/NewGame.pressed.connect(_on_new_game_pressed)
	$CenterContainer/VBoxContainer/LoadGame.pressed.connect(_on_load_game_pressed)
	$CenterContainer/VBoxContainer/Settings.pressed.connect(_on_settings_pressed)
	$CenterContainer/VBoxContainer/Leave.pressed.connect(_on_exit_pressed)
	quit_dialog.confirmed.connect(_on_quit_confirmed)
	

func _on_new_game_pressed():
	print("Nueva partida")
	# Aquí cargas tu escena de juego:
	# get_tree().change_scene_to_file("res://ruta_a_tu_juego.tscn")

func _on_load_game_pressed():
	print("Cargar partida")
	# Aquí pondrías tu lógica de carga

func _on_settings_pressed():
	print("Abrir ajustes")
	# Aquí podrías cargar otra escena de ajustes

func _on_exit_pressed():
	quit_dialog.popup_centered()

func _on_quit_confirmed():
	get_tree().quit()
