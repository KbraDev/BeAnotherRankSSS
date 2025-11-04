extends Control

@onready var quit_dialog = $ConfirmationDialog

func _ready():
	$CenterContainer/VBoxContainer/NewGame.pressed.connect(_on_new_game_pressed)
	$CenterContainer/VBoxContainer/LoadGame.pressed.connect(_on_load_game_pressed)
	$CenterContainer/VBoxContainer/Settings.pressed.connect(_on_settings_pressed)
	$CenterContainer/VBoxContainer/Leave.pressed.connect(_on_exit_pressed)
	quit_dialog.confirmed.connect(_on_quit_confirmed)


# --- Nueva partida ---
func _on_new_game_pressed() -> void:
	_open_load_menu("new_game")


# --- Cargar partida ---
func _on_load_game_pressed() -> void:
	_open_load_menu("load")


# --- Método común para abrir el menú de slots ---
func _open_load_menu(mode: String) -> void:
	var load_menu_scene := preload("res://UIs/Save_Load_popup/LoadMenu/popup_load_menu.tscn")
	var load_menu = load_menu_scene.instantiate()
	load_menu.mode = mode
	
	get_tree().root.add_child(load_menu)
	self.visible = false  # 🔒 Ocultar MainMenu mientras se ve el LoadMenu

	load_menu.request_back.connect(func(_resume_game: bool):
		# Solo reactivar el MainMenu si no se cargó ni empezó juego
		if not _resume_game:
			self.visible = true
		load_menu.queue_free()
	)

	load_menu.show()


# --- Ajustes y salida ---
func _on_settings_pressed():
	print("Abrir ajustes")

func _on_exit_pressed():
	quit_dialog.popup_centered()

func _on_quit_confirmed():
	get_tree().quit()
