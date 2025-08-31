extends Area2D

@export var required_badge: String = ""
@export var message: String = "Necesitas leer la carta primero."
@export var push_back: float = 16.0  # en píxeles

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if not GameState.has_badge(required_badge):
			NotificationManager.show_message(message, 3.0, Color.WHITE)

			# dirección desde el área hacia el jugador
			var dir: Vector2 = (body.global_position - global_position).normalized()
			# lo mandamos unos píxeles atrás
			body.global_position += dir * push_back
