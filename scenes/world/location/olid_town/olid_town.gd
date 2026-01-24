extends Node2D


@onready var music = $AudioStreamPlayer2D
const DEBUG := true


func _ready() -> void:
	music.play()
