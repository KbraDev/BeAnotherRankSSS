extends Control ## selected Menu

signal mission_selected(mission: MissionResource)
signal menu_closed

@onready var btn_close = $btnClose
@onready var mission_list = $MissionList
@onready var notif_manager = get_tree().get_root().get_node("WorldManager/HUD/FloatingNotificationManager")


var MissionCardScene = preload("res://UIs/MissionSelecteMenu/missionCard/mission_card.tscn")



func _ready() -> void:
	if not btn_close.pressed.is_connected(_on_close_pressed):
		btn_close.pressed.connect(_on_close_pressed)
	visible = false

func open(missions: Array):  # Array[Mission]
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

func _on_mission_accepted(mission: MissionResource):
	var floating = get_tree().get_root().get_node_or_null("WorldManager/HUD/FloatingNotificationManager")
	# Agregar al tracker
	var succes := MissionTracker.add_mission(mission)

	if succes: 
		emit_signal("mission_selected", mission)
		floating.show_message("🎉 Task Acepted: %s" % mission.name, Color.WHITE)
	else: 
		floating.show_message("⚠️ Active task limit reached", Color.ORANGE)

	close()


func _on_close_pressed():
	close()

func close():
	_clear_list()
	visible = false
	emit_signal("menu_closed")
