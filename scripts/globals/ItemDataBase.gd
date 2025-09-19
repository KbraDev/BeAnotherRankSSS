# ItemDatabase.gd (autoload)
extends Node

var all_items := {
	"slimeTear": preload("res://items/resources/slime_teardrop.tres"),
	"carnivorousFang": preload("res://items/resources/carnivorusPlant_fang.tres"),
	"ArmorSpider": preload("res://items/resources/ArmorSpider.tres"),
	"SmallHealthPotion": preload("res://items/resources/SmallHealthPotion.tres")
}



func get_item_by_name(name: String) -> ItemData:
	return all_items.get(name, null)

func get_item_by_id(id: String) -> ItemData:
	return all_items.get(id, null)
