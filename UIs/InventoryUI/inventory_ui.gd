extends Control  ## INVENTARIO

@export var player: Node               # Referencia al jugador dueño del inventario
var slots: Array = []                  # Array con todos los slots de la UI
var inventory_cooldown := false        # Previene abrir/cerrar inventario demasiado rápido

@onready var tooltip = $ItemTooltip/Label  # Tooltip para mostrar info del item

func _ready() -> void:
	# Ocultar inventario al inicio
	visible = false

	# Guardar referencias a todos los slots dentro del GridContainer
	slots = $NinePatchRect/GridContainer.get_children()

	# Conectar señales de los slots (hover e interacción con ítems)
	for slot in slots:
		slot.connect("hover_started", Callable(self, "_on_slot_hover_started"))
		slot.connect("hover_ended", Callable(self, "_on_slot_hover_ended"))
		slot.connect("item_used", Callable(self, "_on_slot_item_used"))

	# Conectar señal del jugador para refrescar la UI si cambia el inventario
	if player:
		player.inventory_updated.connect(update_ui)


func _unhandled_input(event):
	# Detectar cuando se abre/cierra inventario con la acción asignada
	if event.is_action_pressed("Inventory") and not inventory_cooldown:
		if player == null:
			return  # Seguridad: no hay jugador asignado
		toggle_inventory()
		start_cooldown()


func toggle_inventory():
	# Mostrar u ocultar inventario
	visible = !visible
	if visible:
		# Bloquear movimiento y ataques mientras el inventario está abierto
		player.can_attack = false
		player.can_move = false
		player.velocity = Vector2.ZERO
		player.animation.play("idle_" + player.last_direction)
		update_ui(player.inventory)  # Refrescar contenido
	else:
		# Rehabilitar movimiento y ataques
		player.can_move = true
		player.can_attack = true


func start_cooldown():
	# Evita abrir/cerrar inventario muy rápido
	inventory_cooldown = true
	await get_tree().create_timer(0.2).timeout
	inventory_cooldown = false


func update_ui(inventory_data: Array):
	# Actualiza cada slot en la UI con el contenido real del inventario
	var n: int = min(slots.size(), inventory_data.size())
	for i in range(n):
		var slot: DnDSlot = slots[i]
		var data = inventory_data[i]
		if data != null:
			slot.set_item(data["item_data"], data["amount"])
		else:
			slot.set_item(null, 0)

	# Limpiar slots sobrantes en caso de que la UI tenga más que el inventario
	for i in range(n, slots.size()):
		var slot: DnDSlot = slots[i]
		slot.set_item(null, 0)


func _on_slot_hover_started(item_data: ItemData, global_pos: Vector2):
	# Mostrar tooltip al pasar el mouse sobre un ítem
	if item_data == null:
		return
	tooltip.text = "Nombre: %s\nDescripción: %s" % [
		item_data.item_name,
		item_data.description
	]
	$ItemTooltip.visible = true


func _on_slot_hover_ended():
	# Ocultar tooltip al quitar el mouse
	$ItemTooltip.visible = false


func _on_slot_item_used(item_data: ItemData):
	# Usar ítem (ejemplo: pociones)
	if item_data is UsableItemData:
		item_data.use(player)  # Ejecuta efecto del ítem
		player._remove_item_from_inventory(item_data, 1)  # Consume 1 del stack
		update_ui(player.inventory)  # Refresca UI


func on_slots_swapped(slot_a: DnDSlot, slot_b: DnDSlot):
	# Se llama cuando se intercambian 2 slots en la UI
	var index_a := slots.find(slot_a)
	var index_b := slots.find(slot_b)

	if index_a != -1 and index_b != -1:
		if player == null:
			return  # Seguridad: sin jugador asignado

		# Guardar la información de cada slot (mismo formato que usa el inventario real)
		var data_a = null
		if slot_a.item_data != null:
			data_a = {"item_data": slot_a.item_data, "amount": slot_a.amount}

		var data_b = null
		if slot_b.item_data != null:
			data_b = {"item_data": slot_b.item_data, "amount": slot_b.amount}

		# Aplicar el swap dentro del array del inventario real del jugador
		player.inventory[index_a] = data_a
		player.inventory[index_b] = data_b

		# Notificar a otros sistemas que el inventario cambió
		player.emit_signal("inventory_updated", player.inventory)
