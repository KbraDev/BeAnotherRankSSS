extends StaticBody2D

@onready var animation = $AnimatedSprite2D

func _ready() -> void:
	animation.play("default")
