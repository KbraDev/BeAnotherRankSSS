extends Node2D

@onready var UI = $AnimatedSprite2D
@onready var interactArea = $interactArea

@export_multiline var pages: Array[String] = ["Página por defecto"]

var player_in_area: bool = false

# Señal para avisar que se debe abrir la carta
# Ahora mandamos TODO el array de páginas
signal letter_opened(pages: Array[String])

func _ready() -> void:
	UI.visible = false
	UI.play("default")

func _on_interact_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		UI.visible = true
		player_in_area = true

func _on_interact_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		UI.visible = false
		player_in_area = false

func _process(delta: float) -> void:
	if player_in_area and Input.is_action_just_pressed("interact"):
		emit_signal("letter_opened", pages) # 👈 ahora emitimos el array
