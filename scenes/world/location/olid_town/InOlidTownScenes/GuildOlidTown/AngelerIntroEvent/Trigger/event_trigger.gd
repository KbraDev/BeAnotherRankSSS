extends Area2D

@export var required_flag: String = "ANGELER_INTRO_DONE"

@onready var event_node = $".."


func _ready() -> void:
	print("Trigger del gremio listo")


func _on_body_entered(body: Node) -> void:
	print("ALGO ENTRO AL TRIGGER:", body.name)
	if not body.is_in_group("player"):
		return

	if GameState.has_flag(required_flag):
		return

	event_node.start_event()
