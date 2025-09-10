extends Control  ## INVENTARIO

@export var player: Node
var slots: Array = []
var inventory_cooldown := false

@onready var tooltip = $ItemTooltip/Label

func _ready() -> void:
	visible = false
	slots = $NinePatchRect/GridContainer.get_children()

	for slot in slots:
		slot.connect("hover_started", Callable(self, "_on_slot_hover_started"))
		slot.connect("hover_ended", Callable(self, "_on_slot_hover_ended"))

	# Si asignas player por export, conecta aquí:
	if player:
		player.inventory_updated.connect(update_ui)


 

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
		player.can_attack = false
		player.can_move = false
		player.velocity = Vector2.ZERO  # Asegura que no siga deslizando
		player.animation.play("idle_" + player.last_direction)  # ← Forzar idle
		update_ui(player.inventory)
	else:
		player.can_move = true
		player.can_attack = true



func start_cooldown():
	inventory_cooldown = true
	await get_tree().create_timer(0.2).timeout
	inventory_cooldown = false

func update_ui(inventory_data: Array):
	# Rellena hasta el mínimo común
	var n: int = min(slots.size(), inventory_data.size())
	for i in range(n):
		var slot = slots[i]
		var data = inventory_data[i]
		if data != null:
			slot.set_item(data["item_data"], data["amount"])
		else:
			slot.set_item(null, 0)

	# Si hay más slots que datos, vacía los extras
	for i in range(n, slots.size()):
		var slot = slots[i]
		slot.set_item(null, 0)



func _on_slot_hover_started(item_data: ItemData, global_pos: Vector2):
	if item_data == null:
		return

	tooltip.text = "Nombre: %s\nDescripción: %s" % [
		item_data.item_name,
		item_data.description
	]

	$ItemTooltip.visible = true



func _on_slot_hover_ended():
	$ItemTooltip.visible = false
