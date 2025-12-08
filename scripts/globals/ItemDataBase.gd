# ItemDatabase.gd (autoload)
extends Node

var all_items := {
	# Items
	"slimeTear": preload("res://items/resources/slime_teardrop.tres"),
	"carnivorousFang": preload("res://items/resources/carnivorusPlant_fang.tres"),
	"ArmorSpider": preload("res://items/resources/ArmorSpider.tres"),
	"SmallHealthPotion": preload("res://items/resources/SmallHealthPotion.tres"),
	"GlobbinKingFinger": preload("res://items/resources/GlobbinKingFinger.tres"),
	"GlobbinMajorFinger": preload("res://items/resources/GlobbinMajorFinger.tres"),
	"GlobbinRockieFinger": preload("res://items/resources/GlobbinRockieFinger.tres"),
	
	# Coins
	"BronzeCoin": preload("res://items/resources/Coins/BronzeCoin.tres"),
	"GoldCoin": preload("res://items/resources/Coins/GoldCoin.tres"),
	"SilverCoin": preload("res://items/resources/Coins/SilverCoin.tres")
}

# Ahora devolvemos Resource en lugar de ItemData
func get_item_by_name(name: String) -> Resource:
	return all_items.get(name, null)

func get_item_by_id(id: String) -> Resource:
	return all_items.get(id, null)
