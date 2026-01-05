extends Node2D

@onready var music = $VillageMusic

func _ready() -> void:
	music.play()
