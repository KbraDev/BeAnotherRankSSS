extends Globbin
class_name KingGlobbin

# ====================================================
# ===================== STATE ========================
# ====================================================

var is_active: bool = false
var phase_2: bool = false

# Guardar valores base para evitar bugs al buffear
var _base_speed: float
var _base_damage: float

# ====================================================
# ===================== NODES ========================
# ====================================================

@onready var war_scream: AudioStreamPlayer2D = $WarScream

@export var boss_ui_path: NodePath
var boss_ui

# Cámaras (asignadas desde el editor)
@export var king_camera_path: NodePath
@export var blend_camera_path: NodePath

var king_camera: Camera2D
var blend_camera: Camera2D

# ====================================================
# ===================== STATS ========================
# ====================================================

@export_group("Phase 2 Settings")
@export var phase2_multiplier: float = 1.5
@export var phase2_health_threshold: float = 0.45 # 45%

# ====================================================
# ===================== READY ========================
# ====================================================

func _ready() -> void:
	super()

	# Guardar stats base (CRÍTICO)
	_base_speed = move_speed
	_base_damage = damage

	# UI del boss
	if boss_ui_path != NodePath():
		boss_ui = get_node_or_null(boss_ui_path)
		if boss_ui:
			boss_ui.set_max_health(max_health)
			boss_ui.update_health(current_health)
			boss_ui.boss_name = enemy_name

	# Cámaras
	if king_camera_path != NodePath():
		king_camera = get_node_or_null(king_camera_path)

	if blend_camera_path != NodePath():
		blend_camera = get_node_or_null(blend_camera_path)

	if not king_camera:
		push_error("KingGlobbin: king_camera_path no asignado o inválido")

	if not blend_camera:
		push_error("KingGlobbin: blend_camera_path no asignado o inválido")

	# Boss inicia congelado
	set_inactive()

# ====================================================
# ===================== DAMAGE =======================
# ====================================================

func take_damage(amount: float, dir: String = "front") -> void:
	super.take_damage(amount, dir)

	if boss_ui:
		boss_ui.update_health(current_health)

	_check_phase_2()

# ====================================================
# ===================== PHASE 2 ======================
# ====================================================

func _check_phase_2() -> void:
	if phase_2:
		return

	var health_ratio := current_health / max_health
	if health_ratio <= phase2_health_threshold:
		_start_phase_2()

func _start_phase_2() -> void:
	phase_2 = true

	# Congelar boss
	freeze_globbin()

	# Pausar IA
	if has_node("AI"):
		$AI.set_active(false)

	# Obtener cámara actual del jugador
	var cams := get_tree().get_nodes_in_group("player_camera")
	if cams.is_empty():
		push_error("KingGlobbin: No player_camera found for phase 2")
		return

	var player_camera: Camera2D = cams[0]

	# Validación FINAL de cámaras
	if not king_camera or not blend_camera:
		push_error("KingGlobbin: Cameras not ready for phase 2 cutscene")
		return

	# Ejecutar cinemática
	SmoothCameraChanger.play_cutscene(
		player_camera,
		king_camera,
		blend_camera,
		1.2, # blend_time
		1.5, # hold_time
		Callable(self, "_on_phase_2_focus"),
		Callable(self, "_on_phase_2_finished"),
		true # YES shake
	)

func _on_phase_2_focus() -> void:
	if war_scream:
		war_scream.volume_db = 3.0
		war_scream.play()

func _on_phase_2_finished() -> void:
	# Buff real de stats
	move_speed = _base_speed * phase2_multiplier
	damage = _base_damage * phase2_multiplier

	# RESET DE ESTADOS BLOQUEANTES
	is_hurt = false
	is_being_pushed = false
	is_attacking = false

	# Forzar reactivación lógica
	_choose_new_direction()

	# Reactivar IA
	if has_node("AI"):
		$AI.set_active(true)

	# Volver al combate
	unfreeze_globbin()

	print("[KingGlobbin] Phase 2 started - AI unlocked")


# ====================================================
# ===================== FLOW =========================
# ====================================================

func set_inactive() -> void:
	is_active = false
	freeze_globbin()

	if boss_ui:
		boss_ui.visible = false
		boss_ui.modulate.a = 0.0

func activate(start_ai := true) -> void:
	if is_active:
		return

	is_active = true

	if start_ai:
		unfreeze_globbin()
	else:
		freeze_globbin()

# ====================================================
# ===================== FREEZE =======================
# ====================================================

func freeze_globbin() -> void:
	can_move = false
	is_attacking = false
	velocity = Vector2.ZERO

	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("idle_front")

func unfreeze_globbin() -> void:
	can_move = true
	is_hurt = false
	is_being_pushed = false
	is_attacking = false

	_choose_new_direction()
