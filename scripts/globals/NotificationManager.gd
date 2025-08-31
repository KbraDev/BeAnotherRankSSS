extends CanvasLayer

var notification_scene := preload("res://UIs/Notificaction/floating_notiification.tscn")

func show_message(text: String, duration := 4.0, color := Color.WHITE):
	var notif = notification_scene.instantiate()
	add_child(notif)
	notif.show_message(text, duration, color)
