extends Node
class_name PhisycAttackController

signal attack_started(attack_id: int)
signal attack_finished(attack_id: int)
signal attack_blocked()

enum AttackType {
	RIGHT_SLASH = 1,
	LEFT_SLASH  = 2,
	DOUBLE_SLASH = 3
}

@export_category("Cooldowns")
@export var right_slash_cooldown: float = 0.3
@export var left_slash_cooldown: float = 0.3
@export var combo_buffer_time: float = 0.12

var _can_attack: bool = true
var _is_attacking: bool = false
var _current_attack: int = 0

var _buffered_attack: int = 0
var _combo_timer: Timer
@onready var _cooldown_timer: Timer = Timer.new()

func _ready() -> void:
	_cooldown_timer.one_shot = true
	add_child(_cooldown_timer)
	_cooldown_timer.timeout.connect(_on_cooldown_finished)

	_combo_timer = Timer.new()
	_combo_timer.one_shot = true
	add_child(_combo_timer)
	_combo_timer.timeout.connect(_on_combo_buffer_timeout)

func request_attack(attack_type: int) -> void:
	if not _can_attack or _is_attacking:
		emit_signal("attack_blocked")
		return

	if _buffered_attack == 0:
		_buffered_attack = attack_type
		_combo_timer.start(combo_buffer_time)
		return

	if _is_combo(_buffered_attack, attack_type):
		_combo_timer.stop()
		_execute_attack(AttackType.DOUBLE_SLASH)
		_clear_buffer()

func _on_combo_buffer_timeout() -> void:
	if _buffered_attack != 0:
		_execute_attack(_buffered_attack)
		_clear_buffer()

func _execute_attack(attack_type: int) -> void:
	_is_attacking = true
	_can_attack = false
	_current_attack = attack_type

	_start_cooldown(attack_type)
	emit_signal("attack_started", attack_type)

func _is_combo(a: int, b: int) -> bool:
	return (
		(a == AttackType.RIGHT_SLASH and b == AttackType.LEFT_SLASH)
		or
		(a == AttackType.LEFT_SLASH and b == AttackType.RIGHT_SLASH)
	)

func _clear_buffer() -> void:
	_buffered_attack = 0

func _start_cooldown(attack_type: int) -> void:
	var cooldown: float = 0.0

	match attack_type:
		AttackType.RIGHT_SLASH:
			cooldown = right_slash_cooldown
		AttackType.LEFT_SLASH:
			cooldown = left_slash_cooldown
		AttackType.DOUBLE_SLASH:
			cooldown = 0.6
		_:
			cooldown = 0.3

	_cooldown_timer.start(cooldown)

func _on_cooldown_finished() -> void:
	_can_attack = true
	_is_attacking = false
	_current_attack = 0

func lock_attacks() -> void:
	_can_attack = false

func unlock_attacks() -> void:
	_can_attack = true

func is_attacking() -> bool:
	return _is_attacking

func notify_attack_finished() -> void:
	if not _is_attacking:
		return

	_is_attacking = false
	emit_signal("attack_finished", _current_attack)
