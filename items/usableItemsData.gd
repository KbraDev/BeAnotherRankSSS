# UsableItemData.gd
extends ItemData
class_name UsableItemData

@export var effect_amount: int = 0 # cantidad de vida/mana/etc
@export var effect_type: String = "heal" # podría ser "heal", "mana", "buff", etc.


func use(target) -> void:
	if effect_type == "heal" and target.has_method("heal"):
		target.heal(effect_amount)
