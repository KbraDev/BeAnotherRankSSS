extends Control  ## INVENTARIO

@export var player: Node
var slots: Array = []
var inventory_cooldown := false

var hide_button_timer = null

@onready var tooltip = $ItemTooltip/Label
@onready var use_button = $UseButton

var _current_slot: DnDSlot = null

func _ready() -> void:
	visible = false
	use_button.visible = false
	
	# Guardar referencias a todos los slots
	slots = $GridContainer.get_children()

	# Conectar señales de cada slot
	for slot in slots:
		print_debug("Conectando señales de slot:", slot.name)
		slot.connect("hover_started", Callable(self, "_on_slot_hover_started"))
		slot.connect("hover_ended", Callable(self, "_on_slot_hover_ended"))
		slot.connect("item_used", Callable(self, "_on_slot_item_used"))

	# Conectar botón global
	use_button.connect("pressed", Callable(self, "_on_use_button_pressed"))
	use_button.connect("mouse_entered", Callable(self, "_on_use_button_mouse_enter"))


	if player:
		player.inventory_updated.connect(update_ui)


func _unhandled_input(event):
	if event.is_action_pressed("Inventory") and not inventory_cooldown:
		if player == null:
			return
		toggle_inventory()
		start_cooldown()

func toggle_inventory():
	visible = !visible
	if visible:
		player.can_attack = false
		player.can_move = false
		player.velocity = Vector2.ZERO
		player.animation.play("idle_" + player.last_direction)
		update_ui(player.inventory)
	else:
		player.can_move = true
		player.can_attack = true

func start_cooldown():
	inventory_cooldown = true
	await get_tree().create_timer(0.2).timeout
	inventory_cooldown = false

func update_ui(inventory_data: Array):
	var n: int = min(slots.size(), inventory_data.size())
	for i in range(n):
		var slot: DnDSlot = slots[i]
		var data = inventory_data[i]
		if data != null:
			slot.set_item(data["item_data"], data["amount"])
		else:
			slot.set_item(null, 0)

	for i in range(n, slots.size()):
		var slot: DnDSlot = slots[i]
		slot.set_item(null, 0)

	use_button.visible = false
	_current_slot = null

# --- Hover sobre un slot ---
func _on_slot_hover_started(item_data, global_pos, slot):

	if item_data == null:
		return

	tooltip.text = "Nombre: %s\nDescripción: %s" % [
		item_data.item_name,
		item_data.description
	]
	$ItemTooltip.visible = true

	if item_data is UsableItemData:
		use_button.visible = true
		use_button.global_position = slot.global_position + Vector2(
			(slot.size.x - use_button.size.x) / 2,
			(slot.size.y - use_button.size.y) / 2
		)
		_current_slot = slot
	else:
		use_button.visible = false
		_current_slot = null

func _on_slot_hover_ended():
	$ItemTooltip.visible = false

	# Cancelamos lógicamente cualquier temporizador previo
	hide_button_timer = null

	# Creamos uno nuevo
	var timer = get_tree().create_timer(0.15)
	hide_button_timer = timer

	timer.timeout.connect(func():
		# Solo actuamos si este sigue siendo el timer activo
		if hide_button_timer == timer:
			if not use_button.get_rect().has_point(use_button.get_global_mouse_position()):
				use_button.visible = false
				_current_slot = null
			hide_button_timer = null
	)

func _on_use_button_pressed():
	if _current_slot and _current_slot.item_data is UsableItemData:
		_current_slot.emit_signal("item_used", _current_slot.item_data)

func _on_slot_item_used(item_data):
	if item_data is UsableItemData:
		item_data.use(player)
		player._remove_item_from_inventory(item_data, 1)
		update_ui(player.inventory)

func on_slots_swapped(slot_a: DnDSlot, slot_b: DnDSlot):
	var index_a := slots.find(slot_a)
	var index_b := slots.find(slot_b)

	if index_a != -1 and index_b != -1 and player:
		var data_a = null
		if slot_a.item_data != null:
			data_a = {"item_data": slot_a.item_data, "amount": slot_a.amount}

		var data_b = null
		if slot_b.item_data != null:
			data_b = {"item_data": slot_b.item_data, "amount": slot_b.amount}

		player.inventory[index_a] = data_a
		player.inventory[index_b] = data_b
		player.emit_signal("inventory_updated", player.inventory)
		

func _on_use_button_mouse_enter():
	# Simplemente anulamos el temporizador activo
	hide_button_timer = null
