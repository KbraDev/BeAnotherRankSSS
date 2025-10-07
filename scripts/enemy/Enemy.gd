extends CharacterBody2D
class_name Enemy
## Clase base para todos los enemigos del juego.
## Gestiona estadísticas comunes, vida, experiencia, drops, knockback y sonidos.

# =========================
# === ESTADÍSTICAS BASE ===
# =========================

@export_group("Stats Base")
@export var max_health: float = 10.0
@export var move_speed: float = 50.0
@export var xp_reward_range: Vector2i = Vector2i(5, 10)
@export var armor: float = 0.0
@export var drop_item: Resource
@export var enemy_name: String = "Generic Enemy"

# =========================
# === KNOCKBACK / FÍSICA ===
# =========================

@export_group("Knockback")
@export var mass: float = 3.6
@export var knockback_scale: float = 3.0
@export var knockback_friction: float = 200.0

# =========================
# === COMPONENTES COMUNES ===
# =========================

@onready var health_bar: Node = $HealthBar if has_node("HealthBar") else null
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

# 🎧 Audio opcional (detecta automáticamente si existen)
@onready var audio_hit: AudioStreamPlayer2D = $Audio_Hit if has_node("Audio_Hit") else null
@onready var audio_attack: AudioStreamPlayer2D = $Audio_Attack if has_node("Audio_Attack") else null
@onready var audio_death: AudioStreamPlayer2D = $Audio_Death if has_node("Audio_Death") else null

# =========================
# === VARIABLES INTERNAS ===
# =========================

var current_health: float
var has_died: bool = false

# =========================
# === CICLO DE VIDA ===
# =========================

func _ready() -> void:
	current_health = max_health
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.visible = false

	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if velocity.length() > 0.1:
		velocity = velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	move_and_slide()

# =========================
# === SISTEMA DE DAÑO ===
# =========================

func _take_damage(amount: float) -> void:
	if has_died:
		return

	var final_damage: float = max(amount - armor, 0.0)
	current_health = max(current_health - final_damage, 0.0)

	if health_bar:
		health_bar.value = current_health
		health_bar.show_for_a_while()

	# 🔊 Sonido de golpe
	play_sound("hit")

	if animation and animation.sprite_frames.has_animation("hurt_front"):
		animation.play("hurt_front")

	if current_health <= 0:
		die()

# =========================
# === MUERTE Y DROPS ===
# =========================

func die() -> void:
	if has_died:
		return

	has_died = true
	velocity = Vector2.ZERO
	set_physics_process(false)

	# 🔊 Sonido de muerte
	play_sound("death")

	if animation and animation.sprite_frames.has_animation("dying"):
		animation.play("dying")
	else:
		_on_enemy_died()

func _on_enemy_died() -> void:
	if drop_item:
		var pickup_scene = preload("res://scenes/World_pick-ups/pick_ups_items.tscn")
		var pickup = pickup_scene.instantiate()
		pickup.item_data = drop_item
		pickup.amount = 1
		pickup.global_position = global_position
		get_tree().current_scene.add_child(pickup)

	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("gain_experience"):
		var xp = randi_range(xp_reward_range.x, xp_reward_range.y)
		player.gain_experience(xp)
		print("🎁", player.name, "ganó", xp, "XP por matar a", enemy_name)

	queue_free()

# =========================
# === KNOCKBACK ===
# =========================

func apply_knockback(direction: Vector2, force: float):
	if mass <= 0.0:
		mass = 1.0

	var acceleration = force / mass
	var target_velocity = direction * (acceleration * knockback_scale)

	# Cancelar tweens anteriores para evitar acumulación
	get_tree().create_tween().kill()

	var tween = get_tree().create_tween()
	tween.tween_property(self, "velocity", target_velocity, 0.08).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "velocity", Vector2.ZERO, 0.35).set_ease(Tween.EASE_OUT)

	print("[Knockback] →", enemy_name, "dir:", direction, "vel:", target_velocity)

# =========================
# === SONIDOS ===
# =========================

func play_sound(type: String) -> void:
	var player: AudioStreamPlayer2D = null
	match type:
		"hit":
			player = audio_hit
		"attack":
			player = audio_attack
		"death":
			player = audio_death
	if player:
		player.pitch_scale = randf_range(0.95, 1.05) # variación natural
		player.play()
