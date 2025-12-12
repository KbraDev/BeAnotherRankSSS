extends TextureProgressBar

@export var boss_name: String:
	set(value):
		boss_name = value
		_update_name()

@export var boss_portrait: CompressedTexture2D:
	set(value):
		boss_portrait = value
		_update_portrait()

@onready var portrait_rect: TextureRect = $TextureRect
@onready var name_label: Label = $Label

func _ready():
	_update_name()
	_update_portrait()

func _update_name():
	if name_label and boss_name:
		name_label.text = boss_name

func _update_portrait():
	if portrait_rect and boss_portrait:
		portrait_rect.texture = boss_portrait

func set_max_health(hp: float):
	max_value = hp
	value = hp

func update_health(hp: float):
	value = hp
