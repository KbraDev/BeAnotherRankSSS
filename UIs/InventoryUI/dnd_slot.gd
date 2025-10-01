extends TextureRect
class_name DnDSlot

# --- Datos del ítem en este slot ---
var item_data: ItemData = null
var amount: int = 0

# --- Señales ---
signal hover_started(item_data, global_position, slot)
signal hover_ended()
signal item_used(item_data)

@onready var amount_label : Label = $Amount

func _ready():
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))
	amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_item(item: ItemData, count: int):
	item_data = item
	amount = count
	texture = item.icon if item else null
	amount_label.text = str(count) if count > 1 else ""

# --- Hover ---
func _on_mouse_entered() -> void:
	if item_data:
		emit_signal("hover_started", item_data, get_global_position(), self)

func _on_mouse_exited() -> void:
	emit_signal("hover_ended")

# --- Drag & Drop ---
func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_data == null:
		return null

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

	return {
		"item_data": item_data,
		"amount": amount,
		"origin_slot": self
	}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("item_data")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var other_slot: DnDSlot = data["origin_slot"]

	var temp_item = item_data
	var temp_amount = amount

	set_item(data["item_data"], data["amount"])
	other_slot.set_item(temp_item, temp_amount)

	var caller := get_parent()
	while caller != null and not caller.has_method("on_slots_swapped"):
		caller = caller.get_parent()

	if caller != null:
		caller.on_slots_swapped(self, other_slot)
