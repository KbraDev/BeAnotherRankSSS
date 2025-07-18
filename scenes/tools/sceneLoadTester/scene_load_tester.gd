extends Node2D

func _ready():
	var scene := load("res://scenes/world/location/MilisCity/city_milis.tscn")
	print("Resultado de load directo:", scene)
	if scene:
		var instance = scene.instantiate()
		add_child(instance)
		print("✅ Escena instanciada correctamente.")
	else:
		print("❌ Error: escena es null.")
