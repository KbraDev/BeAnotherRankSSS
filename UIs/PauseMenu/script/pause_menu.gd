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

@export var save_menu_offset := Vector2(0, -40)
@export var load_menu_offset := Vector2(0, -40)
@export var settings_menu_offset := Vector2(0, -200)

# Submenús (guardar / cargar)
const SaveMenuScene := preload("res://UIs/Save_Load_popup/SaveMenu/popup_save_menu.tscn")
const LoadMenuScene := preload("res://UIs/Save_Load_popup/LoadMenu/popup_load_menu.tscn")
const SettingsMenuScene := preload("res://UIs/MenuSettings/settings_menu.tscn")


var save_menu: Panel = null
var load_menu: Panel = null
var settings_menu: Control = null
var active_submenu: Control = null
var pause_lock := false
var pause_requested := false

# --- Inicialización ---
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	btn_resume.pressed.connect(_on_resume_pressed)
	btn_save.pressed.connect(_on_save_pressed)
	btn_load.pressed.connect(_on_load_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)



# --- Entrada de usuario ---
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_handle_pause()

func _handle_pause() -> void:
	if pause_requested:
		return

	pause_requested = true

	if active_submenu:
		_close_active_submenu()
	else:
		toggle_pause()

	await get_tree().process_frame
	pause_requested = false

# --- Control general de pausa ---
func toggle_pause() -> void:
	if visible:
		_reset_pause_menu_state()
		hide_menu()   # ← ahora sí se ejecuta
	else:
		show_menu()


# Limpia todo el estado del menú de pausa
func _reset_pause_menu_state() -> void:
	if save_menu:
		save_menu.queue_free()
		save_menu = null

	if load_menu:
		load_menu.queue_free()
		load_menu = null

	if settings_menu:
		settings_menu.queue_free()
		settings_menu = null

	if popup_container:
		popup_container.hide()

	active_submenu = null

	panel.visible = false



# Muestra el menú de pausa principal y detiene el juego
func show_menu() -> void:
	if visible:
		return

	panel.visible = true
	visible = true
	get_tree().paused = true

# Cierra el menú de pausa y reanuda el juego
func hide_menu() -> void:
	if not visible:
		return

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
			save_menu.request_back.connect(func(resume_game):
				_on_submenu_closed(resume_game)
			)

	panel.visible = false
	await _show_panel_manual(save_menu, save_menu_offset)
	active_submenu = save_menu
	get_tree().paused = true

# --- Abrir submenú de carga ---
func _on_load_pressed() -> void:
	if not load_menu:
		load_menu = LoadMenuScene.instantiate()
		popup_container.add_child(load_menu)

		if load_menu.has_signal("request_back"):
			load_menu.request_back.connect(func(resume_game):
				_on_submenu_closed(resume_game)
			)

	panel.visible = false
	await _show_panel_manual(load_menu, load_menu_offset)
	active_submenu = load_menu
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
	_reset_pause_menu_state()
	hide_menu()

	var world_manager = get_tree().get_first_node_in_group("world_manager")

	if world_manager and world_manager.has_node("HUD/TransitionOverlay/AnimationPlayer"):
		var anim := world_manager.get_node("HUD/TransitionOverlay/AnimationPlayer")
		get_tree().paused = false 
		anim.play("fade_out")
		await anim.animation_finished

	get_tree().change_scene_to_file("res://scenes/mainScreen/MainScreen.tscn")

func _on_settings_pressed() -> void:
	if not settings_menu:
		settings_menu = SettingsMenuScene.instantiate()
		popup_container.add_child(settings_menu)

		if settings_menu.has_signal("request_back"):
			settings_menu.request_back.connect(_on_settings_closed)

	panel.visible = false
	popup_container.show()   # ← CLAVE

	await get_tree().process_frame

	var parent_size = popup_container.size
	var menu_size := settings_menu.size
	var manual_offset := Vector2(0, -200)

	settings_menu.position = (parent_size - menu_size) * 0.5 + manual_offset
	settings_menu.visible = true
	settings_menu.move_to_front()

	active_submenu = settings_menu
	get_tree().paused = true


func _on_settings_closed() -> void:
	if settings_menu:
		settings_menu.queue_free()
		settings_menu = null

	active_submenu = null

	panel.visible = true
	visible = true
	get_tree().paused = true


func _show_panel_manual(panel_node: Control, offset: Vector2) -> void:
	if not panel_node or not popup_container:
		return

	panel_node.process_mode = Node.PROCESS_MODE_ALWAYS
	panel_node.mouse_filter = Control.MOUSE_FILTER_STOP
	panel_node.focus_mode = Control.FOCUS_ALL

	if not popup_container.visible:
		popup_container.show()

	panel_node.visible = true
	panel_node.move_to_front()

	await get_tree().process_frame

	var parent_size = popup_container.size
	var panel_size := panel_node.size

	panel_node.position = (parent_size - panel_size) * 0.5 + offset

func _close_active_submenu() -> void:
	if not active_submenu:
		return

	active_submenu.queue_free()
	active_submenu = null

	if popup_container:
		popup_container.hide()

	panel.visible = true
	visible = true
	get_tree().paused = true
