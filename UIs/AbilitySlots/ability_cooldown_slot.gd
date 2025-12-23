extends Control
class_name AbilityCooldownSlot

@export var cooldown_duration := 0.35
@export var icon: Texture2D

@onready var icon_rect: TextureRect = $Icon
@onready var bar: ColorRect = $Bar
@onready var mat: ShaderMaterial = bar.material

var _tween: Tween


func _ready() -> void:
	if icon:
		icon_rect.texture = icon

	mat = mat.duplicate()
	bar.material = mat
	mat.set_shader_parameter("progress", 1.0)

func start_cooldown() -> void:
	if _tween:
		_tween.kill()

	# 1️⃣ Vaciar INSTANTÁNEO
	mat.set_shader_parameter("progress", 0.0)

	# 2️⃣ Rellenar animado durante el cooldown
	_tween = get_tree().create_tween()
	_tween.tween_method(
		func(v): mat.set_shader_parameter("progress", v),
		0.0,
		1.0,
		cooldown_duration
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
