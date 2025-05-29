extends Control ## deliveryMissionMenu
signal menu_closed

@onready var btn_close = $btnClose
@onready var mission_list = $ActiveMissionList
var DeliveryCardScene = preload("res://UIs/DeliveryMisionMenu/delivery_mission_card.tscn")

func _ready():
	visible = false
	if not btn_close.pressed.is_connected(_on_close_pressed):
		btn_close.pressed.connect(_on_close_pressed)

func open(missions: Array):
	print("✅ MissionDeliveryMenu abierto. Misiones activas:", missions.size())
	visible = true
	_clear_list()

	for mission_state in missions:
		print("📄 Agregando tarjeta para misión activa:", mission_state.mission.name)
		var card = DeliveryCardScene.instantiate()
		card.set_mission_state(mission_state)
		mission_list.add_child(card)

func _on_close_pressed():
	close()

func close():
	visible = false
	_clear_list()
	emit_signal("menu_closed")

func _clear_list():
	for child in mission_list.get_children():
		child.queue_free()
