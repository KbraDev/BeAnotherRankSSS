extends Control ##NotificactionManager

@onready var stack := $NotificationStack
const MAX_NOTIFICATIONS := 3
const NotificationScene := preload("res://UIs/Notificaction/floating_notiification.tscn")

func show_message(text: String, color := Color.WHITE, duration := 4.0):
	if stack.get_child_count() >= MAX_NOTIFICATIONS:
		print("⚠️ Límite de notificaciones activas alcanzado")
		return
	
	var notif = NotificationScene.instantiate()
	stack.add_child(notif)
	notif.show_message(text, duration, color)

	# Eliminar del stack al terminar
	notif.notification_finished.connect(func():
		notif.queue_free()
	)
