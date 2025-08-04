extends Area2D

@export var pigeon_scene: PackedScene
@export var spawn_area_size: Vector2 = Vector2(400, 200)

func _ready():
	var count = randi_range(3, 6)
	for i in range(count):
		var pigeon = pigeon_scene.instantiate()
		add_child(pigeon)
		pigeon.global_position = global_position + Vector2(
			randf_range(-spawn_area_size.x/2, spawn_area_size.x/2),
			randf_range(-spawn_area_size.y/2, spawn_area_size.y/2)
		)
