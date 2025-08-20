extends Node2D

@onready var label = $CanvasLayer/Label
@onready var path_follow = $CanvasLayer/Path2D/PathFollow2D

var speed := 100.0  # ajusta la velocidad

func _ready():
	# Inicia el parpadeo del Label
	blink_label()
	set_process(false) # desactivar movimiento al inicio

func blink_label():
	var tween = label.create_tween()
	tween.set_loops()
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_property(label, "modulate:a", 1.0, 0.8)

func _unhandled_input(event):
	# Detecta cualquier tecla o clic del mouse
	if event.is_pressed() and (event is InputEventKey or event is InputEventMouseButton):
		label.hide()       # Ocultamos el mensaje
		set_process(true)  # Activamos el movimiento del PathFollow

func _process(delta):
	# Mueve el PathFollow cuando está activo
	if path_follow and not label.visible:
		path_follow.progress += speed * delta
