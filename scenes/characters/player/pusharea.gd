extends Area2D ## Push Area



func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		var push_direction = (body.global_position - global_position).normalized()
		
		# Aplicar un empuje sencillo modificando la velocidad del enemigo
		if body.has_method("apply_push"):
			body.apply_push(push_direction)
