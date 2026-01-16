extends Node2D

@export var item_data: Resource  # Puede ser ItemData o CoinData
@export var amount: int = 1


func _ready():
	print("📦 Pickup spawneado en:", global_position)
	
	$Area2D/Sprite2D.texture = item_data.icon
	$Area2D.connect("body_entered", Callable(self, "_on_body_entered"))
	
	# Posición inicial un poco más arriba
	await get_tree().process_frame
	print("⬆️ Ajustado hacia arriba:", global_position)
	
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y + 20, 0.7).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _on_body_entered(body):
	if not body.is_in_group("player"):
		return

	# 👇 Si es moneda → va al PlayerWallet
	if item_data is CoinData:
		Playerwallet.add_coins(item_data.coin_id, amount)
		print("💰 Moneda recogida:", item_data.coin_name, "x", amount)
		queue_free()
		return

	# 👇 Si es un ítem normal → va al inventario
	if body.has_method("add_item_to_inventory"):
		if not body.add_item_to_inventory(item_data, amount):
			return
		else:
			print("🎒 Item recogido:", item_data.item_name, "x", amount)
			queue_free()
