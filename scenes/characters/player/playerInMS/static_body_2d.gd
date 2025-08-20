extends StaticBody2D

@onready var anim = $AnimatedSprite

func _ready() -> void:
	anim.play("new_animation")
