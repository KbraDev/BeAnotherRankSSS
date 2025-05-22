extends StaticBody2D ## MagicPortal

@onready var PortalOff = $animationOff
@onready var PortalOn = $animationOn
@onready var area = $Area2D  # Asegúrate de que este sea el nombre correcto

var is_on_activate_area = false

func _ready() -> void:
	PortalOff.play("default")
	PortalOff.visible = true
	PortalOn.visible = false

	# Conectamos las señales por código (por si no están conectadas desde el editor)
	area.body_entered.connect(_on_area_2d_body_entered)
	area.body_exited.connect(_on_area_2d_body_exited)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Jugador entró al portal")
		is_on_activate_area = true
		handle_animation_change()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Jugador salió del portal")
		is_on_activate_area = false
		handle_animation_change()

func handle_animation_change():
	if is_on_activate_area:
		PortalOff.visible = false
		PortalOn.visible = true
		PortalOn.play("default")
	else:
		PortalOff.visible = true
		PortalOn.visible = false
		PortalOff.play("default")
