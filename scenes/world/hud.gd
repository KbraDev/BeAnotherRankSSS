extends CanvasLayer

var player_reference

func set_player(player):
	player_reference = player
	player.health_changed.connect(_on_health_changed)
	_on_health_changed(player.current_health, player.max_health) # 👈 Esto actualiza al instante


func _on_health_changed(current, max):
	$PlayerHUD/EllipseHealthBar.max_value = max
	$PlayerHUD/EllipseHealthBar.value = current
