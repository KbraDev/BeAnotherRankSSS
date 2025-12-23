extends Control
class_name AbilityCooldownSlot

@export var cooldown_duration := 0.35
@export var icon: Texture2D

@onready var icon_rect: TextureRect = $Icon
@onready var bar: ColorRect = $Bar
@onready var mat: ShaderMaterial = bar.material

var _tween: Tween

# ───── TOOLTIP ─────
@export_multiline var ability_tooltip: String
@export var tooltip_offset := Vector2(16, 16)

@export var tooltip_title: String
@export_multiline var tooltip_description: String
@export_multiline var tooltip_usage: String
@export var tooltip_icon: Texture2D

var _tooltip: AbilityTooltip


func _ready() -> void:
	if icon:
		icon_rect.texture = icon

	mat = mat.duplicate()
	bar.material = mat
	mat.set_shader_parameter("progress", 1.0)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func start_cooldown() -> void:
	if _tween:
		_tween.kill()

	mat.set_shader_parameter("progress", 0.0)

	_tween = get_tree().create_tween()
	_tween.tween_method(
		func(v): mat.set_shader_parameter("progress", v),
		0.0,
		1.0,
		cooldown_duration
	)


# ───── TOOLTIP LOGIC ─────

func _on_mouse_entered() -> void:
	if tooltip_title.is_empty() and tooltip_description.is_empty():
		return

	
	if _tooltip:
		return
	
	
	_tooltip = preload("res://UIs/AbilitySlots/tooltip.tscn").instantiate()
	get_parent().add_child(_tooltip)
	
	_tooltip.set_content(
		tooltip_title,
		tooltip_description,
		tooltip_usage,
		tooltip_icon
	)
	_update_tooltip_position()


func _process(_delta: float) -> void:
	if _tooltip:
		_update_tooltip_position()

func _update_tooltip_position() -> void:
	var mouse_pos := get_viewport().get_mouse_position()
	
	_tooltip.position = mouse_pos + tooltip_offset

func _on_mouse_exited() -> void:
	if _tooltip:
		_tooltip.queue_free()
		_tooltip = null
