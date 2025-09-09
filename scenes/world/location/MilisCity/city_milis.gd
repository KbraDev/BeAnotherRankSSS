extends Node2D

@onready var music = $AudioStreamPlayer2D


func _ready() -> void:
	music.play()
