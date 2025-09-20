extends Panel

var item_data: ItemData = null
var amount: int = 0

signal hover_started(item_data, global_position)
signal hover_ended()
signal item_used(item_data)  # 👈 Nueva señal

func set_item(item: ItemData, count: int):
	item_data = item
	amount = count
	$icon.texture = item.icon if item != null else null
	$amount.text = str(amount) if count > 1 else ""  # No mostrar "1" si es único

func _ready():
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))

func _on_mouse_entered():
	if item_data:
		emit_signal("hover_started", item_data, get_global_position())

func _on_mouse_exited():
	emit_signal("hover_ended")

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if item_data != null and item_data is UsableItemData:
			emit_signal("item_used", item_data)
