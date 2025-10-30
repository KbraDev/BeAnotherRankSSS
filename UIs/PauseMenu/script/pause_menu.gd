extends CanvasLayer

# --- Referencias UI principales ---
@onready var panel = $Panel
@onready var popup_container = $PopupPanel

# Botones del menú principal
@onready var btn_resume = $Panel/VBoxContainer/Resume
@onready var btn_save = $Panel/VBoxContainer/btn_save
@onready var btn_load = $Panel/VBoxContainer/btn_load
@onready var btn_settings = $Panel/VBoxContainer/btn_settings
@onready var btn_exit = $Panel/VBoxContainer/btn_leave

# Submenús (guardar / cargar)
const SaveMenuScene := preload("res://UIs/Save_Load_popup/SaveMenu/popup_save_menu.tscn")
const LoadMenuScene := preload("res://UIs/Save_Load_popup/LoadMenu/popup_load_menu.tscn")

var save_menu: Panel = null
var load_menu: Panel = null


# --- Inicialización ---
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	visible = false

	# Conectar botones del menú principal
	btn_resume.pressed.connect(_on_resume_pressed)
	btn_save.pressed.connect(_on_save_pressed)
	btn_load.pressed.connect(_on_load_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)


# --- Entrada de usuario ---
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()


# --- Control general de pausa ---
func toggle_pause() -> void:
	# Si está abierto, lo cerramos completamente y reanudamos el juego
	if visible:
		_reset_pause_menu_state()
		hide_menu()
	else:
		# Si no está abierto, lo mostramos y pausamos el juego
		show_menu()


# Limpia todo el estado del menú de pausa
func _reset_pause_menu_state() -> void:
	# Eliminar menús existentes si los hay
	if save_menu:
		save_menu.queue_free()
		save_menu = null
	if load_menu:
		load_menu.queue_free()
		load_menu = null

	# Ocultar el contenedor de submenús
	if popup_container:
		popup_container.hide()

	# Ocultar panel principal
	panel.visible = false
	visible = false


# Muestra el menú de pausa principal y detiene el juego
func show_menu() -> void:
	panel.visible = true
	visible = true
	get_tree().paused = true


# Cierra el menú de pausa y reanuda el juego
func hide_menu() -> void:
	panel.visible = false
	visible = false
	get_tree().paused = false


# --- Botones principales ---
func _on_resume_pressed() -> void:
	hide_menu()


# --- Configuración y despliegue de submenús ---
func __prepare_and_show_panel(panel_node: Control) -> void:
	if not panel_node:
		return

	panel_node.process_mode = Node.PROCESS_MODE_ALWAYS
	panel_node.mouse_filter = Control.MOUSE_FILTER_STOP
	panel_node.focus_mode = Control.FOCUS_ALL

	# Asegurar que el contenedor esté visible
	if popup_container and not popup_container.visible:
		popup_container.show()

	# Mostrar panel centrado
	panel_node.visible = true
	panel_node.move_to_front()
	call_deferred("_deferred_center_panel", panel_node)

	# Refrescar datos si el submenú tiene esa función
	if panel_node.has_method("refresh_slots"):
		panel_node.call_deferred("refresh_slots")

	# Dar foco al botón de “Regresar”
	if panel_node.has_node("VBoxContainer/back_button"):
		panel_node.get_node("VBoxContainer/back_button").grab_focus()


# Centra el panel dentro del contenedor de popups
func _deferred_center_panel(panel_node: Control) -> void:
	if not panel_node or not popup_container:
		return

	var parent_size: Vector2 = popup_container.get_size()
	var child_size: Vector2 = panel_node.get_size()

	if parent_size.x > 0 and child_size.x > 0:
		panel_node.position = (parent_size - child_size) * 0.5


# --- Abrir submenú de guardado ---
func _on_save_pressed() -> void:
	if not save_menu:
		save_menu = SaveMenuScene.instantiate()
		popup_container.add_child(save_menu)
		if save_menu.has_signal("request_back"):
			save_menu.request_back.connect(func(resume_game): _on_submenu_closed(resume_game))

	panel.visible = false
	__prepare_and_show_panel(save_menu)
	get_tree().paused = true


# --- Abrir submenú de carga ---
func _on_load_pressed() -> void:
	if not load_menu:
		load_menu = LoadMenuScene.instantiate()
		popup_container.add_child(load_menu)
		if load_menu.has_signal("request_back"):
			load_menu.request_back.connect(func(resume_game): _on_submenu_closed(resume_game))

	panel.visible = false
	__prepare_and_show_panel(load_menu)
	get_tree().paused = true


# --- Cierre de submenús ---
func _on_submenu_closed(resume_game: bool) -> void:
	# Si el parámetro “resume_game” es true, significa que se cargó una partida
	if resume_game:
		# Cerramos todo y reanudamos el juego
		_reset_pause_menu_state()
		hide_menu()
		get_tree().paused = false
	else:
		# Solo regresamos al menú de pausa (manteniendo el juego detenido)
		if save_menu:
			save_menu.hide()
		if load_menu:
			load_menu.hide()

		panel.visible = true
		visible = true
		get_tree().paused = true


# --- Salir al menú principal ---
func _on_exit_pressed() -> void:
	# Aquí puedes implementar la transición al menú principal
	pass
