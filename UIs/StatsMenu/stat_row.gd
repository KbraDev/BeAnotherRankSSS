extends HBoxContainer

@onready var UpgradeButton: Button = $UpgradeButton
@export var stat_name: String = "Velocidad"
@onready var ProgressLabel = $ProgressBar/ValueLabel
@onready var progressBar =  $ProgressBar

signal stat_upgrade_requested(stat_name: String)

func _ready():
	$StatNameLabel.text = stat_name
	UpgradeButton.pressed.connect(_on_upgrade_pressed)


func _on_upgrade_pressed():
	emit_signal("stat_upgrade_requested", stat_name)

func set_progress(value: int, max_value: int):
	var percent = float(value) / float(max_value)
	progressBar.value = percent * 100

	if stat_name.to_lower() == "suerte":
		ProgressLabel.text = "%d%%" % int((value / max_value) * 100)
	else:
		ProgressLabel.text = "%d / %d" % [value, max_value]
