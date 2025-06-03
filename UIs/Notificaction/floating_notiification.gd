extends Control
signal notification_finished

@onready var label = $Panel/Label

func show_message(text: String, duration := 4.0, color := Color.WHITE):
	label.text = text
	label.modulate = color
	modulate.a = 1.0
	show()

	# Reset position por si se vuelve a usar (en caso de pooling)
	position.y = 0

	# Crear animación de fade y movimiento
	var tween = create_tween()
	tween.tween_interval(duration)  # Espera los 4 segundos completos
	tween.tween_property(self, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(self, "position:y", position.y - 20, 0.6)
	tween.tween_callback(func():
		hide()
		emit_signal("notification_finished")
	)
