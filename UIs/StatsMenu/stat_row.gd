extends HBoxContainer

@onready var UpgradeButton: Button = $UpgradeButton
@export var stat_name: String = "Velocidad"

signal stat_upgrade_requested(stat_name: String)

func _ready():
	$StatNameLabel.text = stat_name
	UpgradeButton.pressed.connect(_on_upgrade_pressed)


func _on_upgrade_pressed():
	emit_signal("stat_upgrade_requested", stat_name)

func set_progress(value: int, max_value: int):
	var percent = float(value) / float(max_value)
	$ProgressBar.value = percent * 100
	$ProgressBar.text = "%d / %d" % [value, max_value]
