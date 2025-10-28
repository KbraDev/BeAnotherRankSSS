extends CanvasLayer

@onready var panel = $Panel
@onready var popup_container = $PopupPanel

# Botones principales
@onready var btn_resume = $Panel/VBoxContainer/Resume
@onready var btn_save = $Panel/VBoxContainer/btn_save
@onready var btn_load = $Panel/VBoxContainer/btn_load
@onready var btn_settings = $Panel/VBoxContainer/btn_settings
@onready var btn_exit = $Panel/VBoxContainer/btn_leave

# Submenús
const SaveMenuScene := preload("res://UIs/Save_Load_popup/SaveMenu/popup_save_menu.tscn")
const LoadMenuScene := preload("res://UIs/Save_Load_popup/LoadMenu/popup_load_menu.tscn")

var save_menu: Panel = null
var load_menu: Panel = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	visible = false

	btn_resume.pressed.connect(_on_resume_pressed)
	btn_save.pressed.connect(_on_save_pressed)
	btn_load.pressed.connect(_on_load_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)

func _input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()

# --- Control de pausa ---
func toggle_pause():
	if visible:
		_reset_pause_menu_state()  # 🔥 limpiar todo
		hide_menu()
	else:
		show_menu()

func _reset_pause_menu_state() -> void:
	print("♻️ Reiniciando estado del menú de pausa")

	# Si existen los menús, los ocultamos o los borramos (tú eliges)
	if save_menu:
		save_menu.queue_free()
		save_menu = null
	if load_menu:
		load_menu.queue_free()
		load_menu = null

	# También aseguramos que el contenedor popup esté oculto
	if popup_container:
		popup_container.hide()

	# Mostrar solo el menú principal la próxima vez
	panel.visible = false
	visible = false


func show_menu():
	print("🟢 Mostrando menú de pausa")
	panel.visible = true
	visible = true
	get_tree().paused = true

func hide_menu():
	print("🔵 Cerrando menú de pausa")
	panel.visible = false
	visible = false
	get_tree().paused = false

# --- Botones ---
func _on_resume_pressed():
	print("⏯ Botón: Reanudar presionado")
	hide_menu()

# Función helper para mostrar panels
func __prepare_and_show_panel(panel_node: Control) -> void:
	if not panel_node:
		return

	panel_node.process_mode = Node.PROCESS_MODE_ALWAYS
	panel_node.mouse_filter = Control.MOUSE_FILTER_STOP
	panel_node.focus_mode = Control.FOCUS_ALL

	if popup_container and not popup_container.visible:
		popup_container.show()

	panel_node.visible = true
	panel_node.move_to_front()  # ✅ Godot 4.x compatible

	call_deferred("_deferred_center_panel", panel_node)

	if panel_node.has_method("refresh_slots"):
		panel_node.call_deferred("refresh_slots")

	if panel_node.has_node("VBoxContainer/back_button"):
		panel_node.get_node("VBoxContainer/back_button").grab_focus()

	print("ℹ️ Panel mostrado -> vis:", panel_node.visible)

func _deferred_center_panel(panel_node: Control) -> void:
	if not panel_node or not popup_container:
		return

	var parent_size: Vector2 = popup_container.get_size()
	var child_size: Vector2 = panel_node.get_size()

	if parent_size.x > 0 and child_size.x > 0:
		panel_node.position = (parent_size - child_size) * 0.5


# --- Guardar/Cargar ---
func _on_save_pressed():
	print("💾 Botón: Guardar presionado")
	if not save_menu:
		save_menu = SaveMenuScene.instantiate()
		popup_container.add_child(save_menu)
		if save_menu.has_signal("request_back"):
			save_menu.request_back.connect(_on_submenu_closed)

	panel.visible = false
	__prepare_and_show_panel(save_menu)
	get_tree().paused = true

func _on_load_pressed():
	print("📂 Botón: Cargar presionado")
	if not load_menu:
		load_menu = LoadMenuScene.instantiate()
		popup_container.add_child(load_menu)
		if load_menu.has_signal("request_back"):
			load_menu.request_back.connect(_on_submenu_closed)

	panel.visible = false
	__prepare_and_show_panel(load_menu)
	get_tree().paused = true

# --- Regresar ---
func _on_submenu_closed():
	print("🔙 Volviendo al menú de pausa")
	_reset_pause_menu_state()
	show_menu()  # volver a mostrar el panel principal en pausa
	get_tree().paused = true

	panel.visible = true
	visible = true
	get_tree().paused = true

func _on_exit_pressed():
	print("🚪 Botón: Salir (implementación pendiente)")
