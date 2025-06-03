extends Control
signal notification_finished

@onready var label = $Panel/Label

func show_message(text: String, duration := 3.0, color := Color.WHITE):
	label.text = text
	label.modulate = color
	modulate.a = 1.0
	show()

	var tween = create_tween()
	tween.tween_interval(0.1)
	tween.tween_property(self, "position:y", position.y - 20, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5).set_delay(duration)
	tween.tween_callback(func():
		hide()
		emit_signal("notification_finished")
	)
