extends Globbin
class_name KingGlobbin

var is_active: bool = false
var phase_2: bool = false

@onready var boss_bar = $CanvasLayer/BossHealthBar
@onready var war_scream = $WarScream
@export var boss_ui_path: NodePath
var boss_ui

func _ready() -> void:
	super()

	if boss_ui_path != NodePath():
		boss_ui = get_node_or_null(boss_ui_path)
		if boss_ui:
			boss_ui.set_max_health(max_health)
			boss_ui.update_health(current_health)
			boss_ui.boss_name = enemy_name

	# Mantener al boss congelado al inicio
	set_inactive()


func _take_damage(amount: float, dir: String = "front") -> void:
	super._take_damage(amount, dir)

	if boss_ui:
		boss_ui.update_health(current_health)


func set_inactive() -> void:
	is_active = false
	freeze_globbin()

	# Ya no tocamos colisiones nunca
	# CollisionShape2D siempre permanece activa

	# Ocultar UI del boss
	if boss_ui:
		boss_ui.visible = false
		boss_ui.modulate.a = 0.0


func activate(start_ai := true) -> void:
	if is_active:
		return

	is_active = true

	# Ya no activamos colisión. Siempre está activa.

	if start_ai:
		unfreeze_globbin()
	else:
		freeze_globbin()   # Queda congelado hasta que la cámara vuelva


func freeze_globbin():
	# Conservar compatibilidad si futuro IA externa
	if has_node("AI"):
		return

	can_move = false
	is_attacking = false
	velocity = Vector2.ZERO

	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("idle_front")


func unfreeze_globbin():
	can_move = true
