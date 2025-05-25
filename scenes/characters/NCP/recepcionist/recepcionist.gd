extends CharacterBody2D

@onready var animation = $AnimatedSprite2D
@onready var interacUIAnimation = $InteractUI

func _ready() -> void:
	animation.play("front")
	interacUIAnimation.visible = false


func _on_interact_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		interacUIAnimation.visible = true


func _on_interact_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		interacUIAnimation.visible = false
