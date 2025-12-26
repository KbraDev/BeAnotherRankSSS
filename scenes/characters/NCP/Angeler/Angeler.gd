extends CharacterBody2D
class_name Angeler

@onready var autonomous_movement: AutonomousMovementController = $AutonomousMovementController

func _physics_process(delta: float) -> void:
	autonomous_movement.physics_update(delta)
