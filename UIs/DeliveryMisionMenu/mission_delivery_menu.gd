extends Control ## deliveryMissionMenu
signal menu_closed
signal mission_delivered_event(state: MissionState)


@onready var btn_close = $btnClose
@onready var mission_list = $ActiveMissionList
var DeliveryCardScene = preload("res://UIs/DeliveryMisionMenu/delivery_mission_card.tscn")

func _ready():
	visible = false
	if not btn_close.pressed.is_connected(_on_close_pressed):
		btn_close.pressed.connect(_on_close_pressed)

func open(missions: Array):
	visible = true
	_clear_list()

	for mission_state in missions:
		var card = DeliveryCardScene.instantiate()
		card.set_mission_state(mission_state, true) 
		card.mission_delivered.connect(_on_mission_delivered)
		mission_list.add_child(card)

func _on_mission_delivered(state: MissionState):
	print("🎉 Misión entregada:", state.mission.name)

	MissionTracker.complete_mission(state)
	MissionTracker.remove_mission(state)

	emit_signal("mission_delivered_event", state)

	# 👉 Si el menú va a cerrarse, NO deberíamos reabrirlo
	if not visible:
		return

	# Si no se cerró, refrescar lista
	_clear_list()
	open(MissionTracker.get_active_mission())

func _on_close_pressed():
	close()

func close():
	visible = false
	_clear_list()
	emit_signal("menu_closed")

func _clear_list():
	for child in mission_list.get_children():
		child.queue_free()
