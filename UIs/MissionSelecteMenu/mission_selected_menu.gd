extends Control ## selected Menu

signal mission_selected(mission: Mission)
signal menu_closed

@onready var btn_close = $btnClose
@onready var mission_list = $MissionList

var MissionCardScene = preload("res://UIs/MissionSelecteMenu/missionCard/mission_card.tscn")

func _ready() -> void:
	if not btn_close.pressed.is_connected(_on_close_pressed):
		btn_close.pressed.connect(_on_close_pressed)
	visible = false

func open(missions: Array):  # Array[Mission]
	print("menu de misiones")
	visible = true
	_clear_list()

	for mission in missions:
		var card = MissionCardScene.instantiate()
		card.set_mission(mission)
		card.mission_accepted.connect(_on_mission_accepted)
		mission_list.add_child(card)

func _clear_list():
	for child in mission_list.get_children():
		child.queue_free()

func _on_mission_accepted(mission: Mission):
	print("Misión aceptada: %s" % mission.name)
	emit_signal("mission_selected", mission)
	close()

func _on_close_pressed():
	close()

func close():
	_clear_list()
	visible = false
	emit_signal("menu_closed")
