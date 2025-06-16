@tool
extends HBoxContainer

@export var stat_name: String = "Salud":
	set(value):
		stat_name = value
		update_stat_label()

func _ready():
	update_stat_label()

func update_stat_label():
	if has_node("StatNameLabel"):
		$StatNameLabel.text = stat_name
