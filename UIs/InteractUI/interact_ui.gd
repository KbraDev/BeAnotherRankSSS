extends AnimatedSprite2D

@onready var anim = $"."

func _ready() -> void:
	anim.play("default")
