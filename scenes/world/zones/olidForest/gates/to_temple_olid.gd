extends Area2D

@export var target_scene: String
@export var target_marker_name: String

var can_trigger := true

func _ready():
	can_trigger = false
	await get_tree().create_timer(0.5).timeout
	can_trigger = true

func _on_body_entered(body):
	if can_trigger and body.name == "player":
		can_trigger = false

		var world_manager = get_tree().get_root().get_node("WorldManager")
		world_manager.change_world(target_scene, target_marker_name)
