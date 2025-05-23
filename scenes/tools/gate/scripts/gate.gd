extends Area2D ## Gate

@export var target_scene: String
@export var target_gate_name: String

var can_trigger := true

func _ready() -> void:
	can_trigger = false
	await get_tree().create_timer(0.4).timeout
	can_trigger = true

func _on_body_entered(body: Node2D) -> void:
	if body.name == "player" and can_trigger:
		can_trigger = false
		GateManager.set_next_gate(target_gate_name)

		# En vez de change_scene, llamamos al WorldManager
		var world_manager = get_tree().get_root().get_node("WorldManager")
		world_manager.change_world(target_scene)



func _on_body_exited(body: Node2D) -> void:
	if body.name == "player":
		can_trigger = true
