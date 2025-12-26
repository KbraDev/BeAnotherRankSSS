extends Area2D

@export var required_flag: String = ""
@export var message: String = "Necesitas leer la carta primero."
@export var push_back: float = 16.0  # píxeles

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	if required_flag != "" and not GameState.has_flag(required_flag):
		NotificationManager.show_message(message, 3.0, Color.WHITE)

		# dirección desde el área hacia el jugador
		var dir: Vector2 = (body.global_position - global_position).normalized()
		body.global_position += dir * push_back
