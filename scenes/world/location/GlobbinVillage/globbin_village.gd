extends Node2D

@onready var music = $VillageMusic
@onready var king = $Globbins/King/GlobbinKing

func _ready() -> void:
	music.play()

	if GameState.has_flag("KingGlobbinEvent"):
		if king:
			king.queue_free()
