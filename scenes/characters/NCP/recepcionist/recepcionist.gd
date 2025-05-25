extends CharacterBody2D

@onready var animation = $AnimatedSprite2D
@onready var interacUIAnimation = $InteractUI
var player_in_range = false

@onready var dialog_box =  get_tree().get_root().get_node("WorldManager/HUD/DialogBox")

func _ready() -> void:
	animation.play("front")
	interacUIAnimation.visible = false


func _on_interact_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		interacUIAnimation.visible = true
		player_in_range = true


func _on_interact_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		interacUIAnimation.visible = false
		player_in_range = false
		if dialog_box.is_showing:
			dialog_box.hide_dialog()

func _process(delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		if not dialog_box.is_showing:
			dialog_box.show_dialog("¡Bienvenido! ¿Cómo podemos ayudarle hoy?")
