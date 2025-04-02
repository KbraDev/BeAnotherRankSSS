extends Area2D

@export var target_scene : String # Nombre de la escena a la que se quiere viajar

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D: 
		get_tree().change_scene_to_file("res://scenes/world/forest.tscn")
