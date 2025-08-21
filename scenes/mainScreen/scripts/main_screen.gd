extends Node2D

@onready var label = $CanvasLayer/Label
@onready var path_follow = $CanvasLayer/Path2D/PathFollow2D
@onready var main_menu = $CanvasLayer/MainMenu
@onready var music = $AudioStreamPlayer2D
var speed := 200.0

func _ready():
	music.play() # reproduce el audio
	blink_label()
	set_process(false)
	main_menu.visible = false
	main_menu.modulate.a = 0.0  # empieza invisible (para fade)

func blink_label():
	var tween = label.create_tween()
	tween.set_loops()
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_property(label, "modulate:a", 1.0, 0.8)

func _unhandled_input(event):
	if event.is_pressed() and (event is InputEventKey or event is InputEventMouseButton):
		label.hide()
		set_process(true)

func _process(delta):
	if path_follow and not label.visible:
		path_follow.progress += speed * delta
		var length = path_follow.get_parent().curve.get_baked_length()
		if path_follow.progress >= length:
			set_process(false)
			show_menu()

func show_menu():
	main_menu.visible = true
	var tween = create_tween()
	tween.tween_property(main_menu, "modulate:a", 1.0, 1.2) # fade en 1.2 segs
