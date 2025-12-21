extends Node
class_name PhisycAttackController
##
## Controlador central de ataques físicos del jugador.
##
## Responsabilidades:
## - Validar si el jugador puede atacar
## - Iniciar y finalizar ataques
## - Gestionar cooldowns entre ataques
## - Activar / desactivar el Area2D de ataque
## - Detectar enemigos golpeados (NO calcula daño)
##
## El daño real se aplica en el Player, no aquí.
##

# ───────────────────────────────
# ────────── SEÑALES ────────────
# ───────────────────────────────

## Se emite al comenzar un ataque
signal attack_started(attack_id: int, hit_index: int)

## Se emite al finalizar completamente un ataque
signal attack_finished(attack_id: int)

## Se emite si el ataque fue bloqueado (cooldown / estado inválido)
signal attack_blocked()

## Se emite cuando un enemigo es golpeado por el Area2D
signal enemy_hit(enemy: Node)


# ───────────────────────────────
# ────────── ENUMS ──────────────
# ───────────────────────────────

enum AttackType {
	BASIC_SLASH = 1,
	DOUBLE_SLASH = 2
}


# ───────────────────────────────
# ─────── CONFIGURACIÓN ─────────
# ───────────────────────────────

## Tiempo de espera entre ataques BASIC_SLASH
@export var basic_slash_cooldown := 0.35
@export var double_slash_cooldown := 3.0
@export var double_click_window := 0.5

## Ruta al Area2D de ataque del jugador
@export var attack_area_path: NodePath

# ───────────────────────────────
# ─────── ESTADO INTERNO ─────────
# ───────────────────────────────

var _can_attack: bool = true
var _is_attacking: bool = false
var _current_attack: int = 0

var _current_hit : int = 0
var _click_count : int = 0

var _attack_area: Area2D
@onready var _cooldown_timer: Timer = Timer.new()
@onready var _double_click_timer: Timer = Timer.new()

# ───────────────────────────────
# ─────────── READY ─────────────
# ───────────────────────────────

func _ready() -> void:
	# Configurar cooldown
	_cooldown_timer.one_shot = true
	add_child(_cooldown_timer)
	_cooldown_timer.timeout.connect(_on_cooldown_finished)
	
	_double_click_timer.one_shot = true
	add_child(_double_click_timer)
	_double_click_timer.timeout.connect(_on_double_click_timeout)

	# Obtener referencia al Area2D de ataque
	if attack_area_path != NodePath():
		_attack_area = get_node(attack_area_path)
		_attack_area.monitoring = false


# ───────────────────────────────
# ────────── INPUT ──────────────
# ───────────────────────────────

## Solicitud externa para iniciar un ataque
func request_attack() -> void:
	if not _can_attack or _is_attacking:
		emit_signal("attack_blocked")
		return

	_click_count += 1

	# PRIMER CLIC → ATAQUE INMEDIATO
	if _click_count == 1:
		_start_basic_slash()
		_double_click_timer.start(double_click_window)

	# SEGUNDO CLIC → DOUBLE SLASH
	elif _click_count == 2:
		_double_click_timer.stop()
		_click_count = 0
		_start_double_slash()

# ───────────────────────────────
# ─────── LÓGICA DE ATAQUE ───────
# ───────────────────────────────

## Inicia el ataque BASIC_SLASH
func _start_basic_slash() -> void:
	_is_attacking = true
	_can_attack = false
	_current_attack = AttackType.BASIC_SLASH

	_enable_attack_area()
	emit_signal("attack_started", _current_attack, 1)


## Debe llamarse cuando la animación de ataque termina
func notify_attack_finished() -> void:
	if not _is_attacking:
		return

	_is_attacking = false
	_disable_attack_area()

	emit_signal("attack_finished", _current_attack)

	if _current_attack == AttackType.DOUBLE_SLASH:
		_cooldown_timer.start(double_slash_cooldown)
	else:
		_cooldown_timer.start(basic_slash_cooldown)

	_current_attack = 0
	_current_hit = 0



## Cooldown terminado → se puede volver a atacar
func _on_cooldown_finished() -> void:
	_can_attack = true


## Estado público de ataque
func is_attacking() -> bool:
	return _is_attacking

## DOUBLE_SLASH
func _on_double_click_timeout() -> void:
	_click_count = 0

func _start_double_slash() -> void:
	_is_attacking = true
	_can_attack = false
	_current_attack = AttackType.DOUBLE_SLASH
	_current_hit = 1

	_enable_attack_area()
	emit_signal("attack_started", _current_attack, _current_hit)

func notify_next_hit() -> void:
	if _current_attack != AttackType.DOUBLE_SLASH:
		return

	if _current_hit == 1:
		_current_hit = 2
		_enable_attack_area()
		emit_signal("attack_started", _current_attack, _current_hit)




# ───────────────────────────────
# ────── BLOQUEO DE ATAQUES ──────
# ───────────────────────────────

## Bloquea completamente los ataques (menús, cinemáticas, muerte)
func lock_attacks() -> void:
	_can_attack = false
	_is_attacking = false
	_current_attack = 0
	_cooldown_timer.stop()


## Habilita nuevamente los ataques
func unlock_attacks() -> void:
	_can_attack = true
	_is_attacking = false
	_current_attack = 0


# ───────────────────────────────
# ────── DETECCIÓN DE ENEMIGOS ───
# ───────────────────────────────

## Activa el Area2D de ataque y conecta detección
func _enable_attack_area() -> void:
	if not _attack_area:
		return

	_attack_area.monitoring = true
	_attack_area.body_entered.connect(_on_attack_area_body_entered)

	# Detectar enemigos que ya estén dentro
	for body in _attack_area.get_overlapping_bodies():
		_process_body(body)


## Desactiva el Area2D y desconecta señales
func _disable_attack_area() -> void:
	if not _attack_area:
		return

	if _attack_area.body_entered.is_connected(_on_attack_area_body_entered):
		_attack_area.body_entered.disconnect(_on_attack_area_body_entered)

	_attack_area.monitoring = false


## Callback cuando un cuerpo entra al área
func _on_attack_area_body_entered(body: Node) -> void:
	_process_body(body)


## Valida y notifica impacto a enemigos
func _process_body(body: Node) -> void:
	if not _is_attacking:
		return

	if body.is_in_group("enemies"):
		emit_signal("enemy_hit", body)
