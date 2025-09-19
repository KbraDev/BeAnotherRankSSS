extends StaticBody2D

@export var hits_to_open: int = 3
var hit_count: int = 0
var is_open: bool = false

@onready var sfx_hit = $AudioStreamPlayer2D

# Loot table: cada entrada define un ítem, cantidad mínima/máxima y chance
@export var loot_table: Array[Dictionary] = [
	{"id": "coin", "min": 1, "max": 3, "chance": 1.0},
	{"id": "SmallHealthPotion", "min": 1, "max": 2, "chance": 1.0}
]

func _ready():
	$AnimatedSprite2D.play("close")

func hit():
	if is_open:
		return
	hit_count += 1
	sfx_hit.play()
	print("Cofre golpeado: ", hit_count, "/", hits_to_open)

	if hit_count >= hits_to_open:
		open_chest()

func open_chest():
	is_open = true
	$AnimatedSprite2D.play("open")
	drop_items()

func drop_items():
	var rng = RandomNumberGenerator.new()

	for entry in loot_table:
		var chance: float = entry.get("chance", 1.0)
		if rng.randf() <= chance:
			var min_amount: int = entry.get("min", 1)
			var max_amount: int = entry.get("max", 1)
			var amount: int = rng.randi_range(min_amount, max_amount)
			spawn_item(entry["id"], amount)

func spawn_item(item_name: String, amount: int = 1):
	var item_data = ItemDataBase.get_item_by_id(item_name)
	if not item_data:
		print("⚠️ Item no encontrado en base:", item_name)
		return

	var pickup_scene = preload("res://scenes/World_pick-Ups/pick_ups_items.tscn")

	for i in range(amount):
		var pickup = pickup_scene.instantiate()
		pickup.item_data = item_data
		pickup.amount = 1  # cada pickup es 1 ítem

		get_parent().add_child(pickup)

		# Spawn cerca del cofre con variación
		var offset = Vector2(randf_range(-12, 12), randf_range(-12, 12))
		pickup.global_position = global_position + offset

		print("✔️ Cofre dropeó:", item_data.item_name, " en ", pickup.global_position, " offset=", offset)
