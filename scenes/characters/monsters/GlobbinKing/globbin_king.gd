extends Globbin
class_name KingGlobbin

signal boss_defeated

# ====================================================
# ===================== STATE ========================
# ====================================================

var is_active: bool = false
var phase_2: bool = false
var is_dead := false

var anchor_position: Vector2
var ceremonial_idle := true

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
@export var boss_name := "King Globbin"

@export_group("Experience")
@export var boss_exp: int = 350

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
	anchor_position = global_position
	ceremonial_idle = true
	locked_by_event = true
	enemy.can_move = false
	
	enemy.exp_reward = boss_exp
	enemy.setup(self, max_health)
	super()

	_base_speed = move_speed
	_base_damage = damage

	if boss_ui_path != NodePath():
		boss_ui = get_node_or_null(boss_ui_path)
		if boss_ui:
			boss_ui.set_max_health(enemy.max_health)
			boss_ui.update_health(enemy.current_health)
			boss_ui.boss_name = boss_name

	# 🔒 ESTADO INICIAL CORRECTO
	set_inactive()

	# 🚫 IA APAGADA DESDE EL FRAME 0
	if has_node("AI"):
		$AI.set_active(false)

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

func _physics_process(delta: float) -> void:
	if ceremonial_idle: 
		global_position = anchor_position
		velocity = Vector2.ZERO
		return
	
	super._physics_process(delta)

# ====================================================
# ===================== DAMAGE =======================
# ====================================================

func take_damage(amount: float, dir: String = "front") -> void:
	super.take_damage(amount, dir)

	if boss_ui:
		boss_ui.update_health(enemy.current_health)

	_check_phase_2()

# ====================================================
# ===================== PHASE 2 ======================
# ====================================================

func _check_phase_2() -> void:
	if phase_2:
		return

	var health_ratio: float = enemy.current_health / enemy.max_health
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
	move_speed = _base_speed * phase2_multiplier
	damage = _base_damage * phase2_multiplier

	enemy.is_hurt = false
	is_attacking = false

	_choose_new_direction()

	unfreeze_globbin()



# ====================================================
# ===================== FLOW =========================
# ====================================================

func set_inactive() -> void:
	is_active = false
	ceremonial_idle = true

	enemy.can_move = false
	velocity = Vector2.ZERO
	is_attacking = false

	if has_node("AI"):
		$AI.set_active(false)

	if sprite:
		sprite.play("idle_front") # mirando al jugador / trono

	if boss_ui:
		boss_ui.visible = false
		boss_ui.modulate.a = 0.0


func activate(start_ai := true) -> void:
	if is_active:
		return

	is_active = true
	ceremonial_idle = false

	if start_ai:
		unfreeze_globbin()
	else:
		freeze_globbin()

	if has_node("AI") and start_ai:
		$AI.set_active(true)


# ====================================================
# ===================== FREEZE =======================
# ====================================================

func freeze_globbin() -> void:
	enemy.can_move = false
	is_attacking = false
	velocity = Vector2.ZERO

	if sprite:
		sprite.play("idle_front")


func unfreeze_globbin() -> void:
	enemy.can_move = true
	enemy.is_hurt = false
	is_attacking = false

	_choose_new_direction()

	_choose_new_direction()

func _on_enemy_died(exp_amount: int) -> void:
	if is_dead:
		return
	is_dead = true

	emit_signal("boss_defeated")
	GameState.set_flag("KingGlobbinEvent")
	print("[EVENT] KingGlobbin defeated → Event completed")

	super._on_enemy_died(exp_amount)

func debug_print_stats(context := "UNKNOWN") -> void:
	print("========== KING GLOBBIN STATS ==========")
	print("Context:", context)
	print("HP:", enemy.current_health, "/", enemy.max_health)
	print("Damage:", damage)
	print("Move Speed:", move_speed)
	print("Phase 2:", phase_2)
	print("Can Move:", enemy.can_move)
	print("Is Active:", is_active)
	print("Is Dead:", is_dead)
	print("=======================================")
