extends Area2D

@export var checkpoint_id: String
@export var checkpoint_name: String = ""

signal checkpoint_reached(id: String)

func _ready():
	add_to_group("checkpoint")
	CheckPointRegistry.register_checkpoint(checkpoint_id, self)


func _exit_tree():
	CheckPointRegistry.unregister_checkpoint(checkpoint_id)

func _on_body_entered(body):
	if body.is_in_group("player"):
		emit_signal("checkpoint_reached", checkpoint_id)
