extends CharacterBody2D
class_name Enemy
## Clase base para todos los enemigos del juego.
## Gestiona estadísticas comunes, vida, experiencia, drops y knockback.
## Las subclases solo deben definir su comportamiento de IA (movimiento, ataques, etc.)

# =========================
# === ESTADÍSTICAS BASE ===
# =========================

@export_group("Stats Base")
@export var max_health: float = 10.0                 ## Vida máxima del enemigo
@export var move_speed: float = 50.0                 ## Velocidad base de movimiento
@export var xp_reward_range: Vector2i = Vector2i(5, 10) ## Rango de experiencia otorgada al morir
@export var armor: float = 0.0                       ## Reducción plana de daño (opcional)
@export var drop_item: Resource                      ## Recurso que soltará al morir (opcional)
@export var enemy_name: String = "Generic Enemy"     ## Nombre descriptivo (útil para debug/logs)

# =========================
# === KNOCKBACK / FÍSICA ===
# =========================

@export_group("Knockback")
@export var mass: float = 3.6                        ## Masa usada para calcular el empuje
@export var knockback_scale: float = 3.0             ## Escala de conversión de fuerza a velocidad (ajusta según el tamaño del enemigo)
@export var knockback_friction: float = 200.0        ## Qué tan rápido se disipa el empuje (px/s²)

# =========================
# === COMPONENTES COMUNES ===
# =========================

@onready var health_bar: Node = $HealthBar if has_node("HealthBar") else null
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

# =========================
# === VARIABLES INTERNAS ===
# =========================

var current_health: float
var has_died: bool = false

# =========================
# === CICLO DE VIDA ===
# =========================

func _ready() -> void:
	## Inicializa la salud y la barra de vida (si existe)
	current_health = max_health
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.visible = false

	# Agrupar todos los enemigos bajo un mismo grupo
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	## Aplica la fricción del knockback si el enemigo está siendo empujado.
	if velocity.length() > 0.1:
		velocity = velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	move_and_slide()

# =========================
# === SISTEMA DE DAÑO ===
# =========================

func _take_damage(amount: float) -> void:
	## Recibe daño y actualiza la salud, respetando la armadura.
	if has_died:
		return

	var final_damage: float = max(amount - armor, 0.0)
	current_health = max(current_health - final_damage, 0.0)

	if health_bar:
		health_bar.value = current_health
		health_bar.show_for_a_while()

	# Reproducir animación de daño si existe
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

	# Reproducir animación de muerte si existe
	if animation and animation.sprite_frames.has_animation("dying"):
		animation.play("dying")
	else:
		_on_enemy_died()

func _on_enemy_died() -> void:
	## Se llama automáticamente cuando la animación de muerte termina
	## o directamente si no hay animación de muerte.

	# Instanciar drop si existe
	if drop_item:
		var pickup_scene = preload("res://scenes/World_pick-ups/pick_ups_items.tscn")
		var pickup = pickup_scene.instantiate()
		pickup.item_data = drop_item
		pickup.amount = 1
		pickup.global_position = global_position
		get_tree().current_scene.add_child(pickup)

	# Dar XP al jugador
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
	## Aplica una fuerza de empuje al enemigo, calculada con masa y escala.
	if mass <= 0.0:
		mass = 1.0

	var acceleration = force / mass
	var target_velocity = direction * (acceleration * knockback_scale)

	# Cancelar tweens anteriores para evitar acumulación
	get_tree().create_tween().kill()

	# Crear tween de knockback (subida rápida → caída suave)
	var tween = get_tree().create_tween()
	tween.tween_property(self, "velocity", target_velocity, 0.08).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "velocity", Vector2.ZERO, 0.35).set_ease(Tween.EASE_OUT)

	print("[Knockback] →", enemy_name, "dir:", direction, "vel:", target_velocity)
