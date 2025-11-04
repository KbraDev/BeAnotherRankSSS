extends Control

@onready var quit_dialog = $ConfirmationDialog

func _ready():
	$CenterContainer/VBoxContainer/NewGame.pressed.connect(_on_new_game_pressed)
	$CenterContainer/VBoxContainer/LoadGame.pressed.connect(_on_load_game_pressed)
	$CenterContainer/VBoxContainer/Settings.pressed.connect(_on_settings_pressed)
	$CenterContainer/VBoxContainer/Leave.pressed.connect(_on_exit_pressed)
	quit_dialog.confirmed.connect(_on_quit_confirmed)
	

func _on_new_game_pressed() -> void:
	var load_menu_scene := preload("res://UIs/Save_Load_popup/LoadMenu/popup_load_menu.tscn")
	var load_menu = load_menu_scene.instantiate()
	load_menu.mode = "new_game"
	
	# Agregar al root (para que no se oculte con el MainMenu)
	get_tree().root.add_child(load_menu)

	# Ocultamos el MainMenu mientras el submenú está activo
	self.visible = false

	# Cuando el load_menu emita 'request_back', lo volvemos a mostrar
	load_menu.request_back.connect(func(_resume_game: bool):
		if not _resume_game:
			self.visible = true
		load_menu.queue_free()
	)

	load_menu.show()


func _on_load_game_pressed() -> void:
	var load_menu_scene := preload("res://UIs/Save_Load_popup/LoadMenu/popup_load_menu.tscn")
	var load_menu = load_menu_scene.instantiate()
	load_menu.mode = "load"

	# Si estás usando el sistema del "LoadAnchor", colócalo ahí:
	# var anchor = $LoadAnchor.global_position
	# load_menu.position = anchor

	get_tree().root.add_child(load_menu)
	self.visible = false

	load_menu.request_back.connect(func(_resume_game: bool):
		if not _resume_game:
			self.visible = true
		load_menu.queue_free()
	)

	load_menu.show()


func _on_settings_pressed():
	print("Abrir ajustes")
	# Aquí podrías cargar otra escena de ajustes

func _on_exit_pressed():
	quit_dialog.popup_centered()

func _on_quit_confirmed():
	get_tree().quit()
