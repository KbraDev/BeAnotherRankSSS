extends Panel

var item_data: ItemData = null

signal hover_started(item_data, global_position)
signal hover_ended()

func set_item(item: ItemData, amount: int):
	item_data = item
	$icon.texture = item.icon if item != null else null
	$amount.text = str(amount) if amount > 0 else ""
	

func _ready():
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))

func _on_mouse_entered():
	if item_data:
		emit_signal("hover_started", item_data, get_global_position())

func _on_mouse_exited():
	emit_signal("hover_ended")
