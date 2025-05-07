extends Node2D

@export var item_data: ItemData
@export var amount: int = 1

func _ready():
	$Area2D/Sprite2D.texture = item_data.icon
	$Area2D.connect("body_entered", Callable(self, "_on_body_entered"))

	# Posición inicial un poco más arriba
	position.y -= 20

	# Creamos un tween usando el sistema nuevo
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y + 15, 0.7).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _on_body_entered(body):
	if body.name == "player": # Ajustalo según el nombre del nodo de tu jugador
		if not body.add_item_to_inventory(item_data, amount):
			return
		else:
			queue_free() # Destruye el ítem tras recogerlo
