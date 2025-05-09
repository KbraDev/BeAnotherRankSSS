extends Control

@export var player: Node
var slots: Array = []
var inventory_cooldown := false

func _ready() -> void:
	visible = false  # ← oculta el inventario al empezar
	slots = $NinePatchRect/GridContainer.get_children()

func _unhandled_input(event):
	if event.is_action_pressed("Inventory") and not inventory_cooldown:
		if player == null:
			print("⚠️ Player no está asignado.")
			return

		toggle_inventory()
		start_cooldown()

func toggle_inventory():
	visible = !visible
	if visible:
		update_ui(player.inventory)

func start_cooldown():
	inventory_cooldown = true
	await get_tree().create_timer(1).timeout
	inventory_cooldown = false

func update_ui(inventory_data: Array):
	for i in range(slots.size()):
		var slot = slots[i]
		var data = inventory_data[i]
		if data != null:
			slot.set_item(data["item_data"].icon, data["amount"])
		else:
			slot.set_item(null, 0)
