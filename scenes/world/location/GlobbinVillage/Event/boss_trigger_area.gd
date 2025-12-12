extends Area2D

@export var king_path: NodePath
@export var king_camera_path: NodePath
@export var blend_camera_path: NodePath
@export var focus_duration: float = 3.0
@export var blend_time: float = 1.5
@export var boss_fade_duration: float = 0.3

var king
var king_camera
var player_camera
var blend_camera

var triggered := false

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

	king = get_node(king_path)
	king_camera = get_node(king_camera_path)
	blend_camera = get_node(blend_camera_path)

	var cams = get_tree().get_nodes_in_group("player_camera")
	if cams.size() > 0:
		player_camera = cams[0]


func _on_body_entered(body):
	if triggered or not body.is_in_group("player"):
		return

	triggered = true
	monitoring = false
	get_node("CollisionShape2D").disabled = true

	# Activamos boss pero permanece congelado (start_ai = false)
	king.call("activate", false)

	# Mantener UI oculta durante la intro
	if king.boss_ui:
		king.boss_ui.visible = false
		king.boss_ui.modulate.a = 0

	SmoothCameraChanger.play_cutscene(
		player_camera,
		king_camera,
		blend_camera,
		blend_time,
		focus_duration,
		Callable(self, "_on_camera_sequence_finished")
	)


func _on_camera_sequence_finished():
	if king:
		king.can_move = true

	# Fade-in UI boss
	if king.boss_ui:
		var ui = king.boss_ui
		ui.visible = true
		ui.modulate.a = 0

		var t = create_tween()
		t.tween_property(ui, "modulate:a", 1.0, boss_fade_duration)

	# Start AI
	if king.has_node("AI"):
		king.get_node("AI").set_active(true)
