extends TextureRect
class_name DnDSlot

# --- Datos del ítem en este slot ---
var item_data: ItemData = null   # Referencia al ítem
var amount: int = 0              # Cantidad (stack)

# --- Señales ---
signal hover_started(item_data, global_position)  # Al pasar el mouse sobre el slot
signal hover_ended()                              # Al quitar el mouse
signal hover_used(item_data)                      # Al usar un ítem (clic derecho)

# --- Referencias a nodos ---
@onready var amount_label : Label = $Amount       # Label que muestra la cantidad

func _ready():
	# Configurar señales de hover
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))

	# Ignorar eventos de mouse en el label de cantidad
	amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


# --- Seteo de datos del slot ---
func set_item(item: ItemData, count: int):
	# Actualiza ítem y cantidad
	item_data = item
	amount = count

	# Mostrar ícono o dejar vacío
	texture = item.icon if item else null

	# Mostrar cantidad solo si es mayor a 1
	amount_label.text = str(count) if count > 1 else ""


# --- Drag & Drop API ---
func _get_drag_data(_at_position: Vector2) -> Variant:
	# Si el slot está vacío, no arrastra nada
	if item_data == null:
		return null

	# Crear preview del arrastre (ícono + cantidad)
	var preview = Control.new()
	var preview_icon = TextureRect.new()
	preview_icon.texture = texture
	preview_icon.size = Vector2(32, 32)
	preview.add_child(preview_icon)

	if amount > 1:
		var preview_label = Label.new()
		preview_label.text = str(amount)
		preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		preview_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		preview_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		preview.add_child(preview_label)

	set_drag_preview(preview)

	# Paquete de datos que viaja en el drag
	return {
		"item_data": item_data,
		"amount": amount,
		"origin_slot": self
	}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Solo acepta paquetes válidos con item_data
	return data is Dictionary and data.has("item_data")


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var other_slot: DnDSlot = data["origin_slot"]

	# --- Swap visual entre slots ---
	var temp_item = item_data
	var temp_amount = amount

	set_item(data["item_data"], data["amount"])
	other_slot.set_item(temp_item, temp_amount)

	# --- Notificar al contenedor (inventario) ---
	var caller := get_parent()
	while caller != null and not caller.has_method("on_slots_swapped"):
		caller = caller.get_parent()

	if caller != null:
		caller.on_slots_swapped(self, other_slot)


# --- Hover ---
func _on_mouse_entered() -> void:
	if item_data:
		emit_signal("hover_started", item_data, get_global_position())


func _on_mouse_exited() -> void:
	emit_signal("hover_ended")


# --- Usar ítem con clic derecho ---
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT and item_data is UsableItemData:
			emit_signal("item_used", item_data)
