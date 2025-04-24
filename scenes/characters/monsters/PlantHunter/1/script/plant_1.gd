extends CharacterBody2D ## Plant Hunter 1

@onready var animation = $AnimatedSprite2D

func _ready() -> void:
	animation.play("idle_front")
