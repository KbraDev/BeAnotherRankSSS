extends CharacterBody2D
class_name Angeler

@export var autonomous_movement_enabled: bool = true
## Controla si Angeler usa movimiento autónomo o no

@onready var autonomous_controller: AutonomousMovementController = $AutonomousMovementController


func _ready() -> void:
	if autonomous_controller:
		autonomous_controller.set_autonomous_enabled(
			autonomous_movement_enabled
		)

func _physics_process(delta: float) -> void:
	if autonomous_controller:
		autonomous_controller.physics_update(delta)
