extends Area2D

@export var event_controller_path: NodePath
var controller: Node

func _ready() -> void:
	monitoring = false
	await get_tree().process_frame
	monitoring = true
	body_entered.connect(_on_body_entered)

	controller = get_node_or_null(event_controller_path)
	if not controller:
		push_error("BossTriggerArea: EventController no asignado")

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	if GameState.has_flag("KingGlobbinEvent"):
		queue_free()
		return

	if controller:
		controller.start_event()

	monitoring = false
	$CollisionShape2D.disabled = true
