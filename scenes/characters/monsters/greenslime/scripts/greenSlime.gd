extends CharacterBody2D
## GREEN SLIME – AI implementation

@export var enemy_id := "GreenSlime"

@export var speed: float = 40.0
@export var panic_speed: float = 60.0
@export var idle_time: float = 4.0
@export var move_time: float = 5.0
@export var extra_escape_distance: float = 200.0

@onready var vision_area: Area2D = $VisionArea
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: TextureProgressBar = $HealthBar

@export_group("Drops")
@export var drop_item: Resource
@export var drop_amount: int = 1

@export var pickup_scene: PackedScene

@export_group("Experience")
@export var exp_min: int = 12
@export var exp_max: int = 16

@export_group("Stats")
@export var max_health: float = 12.0

# =========================
# CORE
# =========================
var enemy = EnemyCore.new()

# =========================
# STATE
# =========================
var player: Node2D = null
var direction := Vector2.ZERO
var timer := 0.0
var state := "idle"
var panic_origin := Vector2.ZERO
var last_direction := "front"

# =========================
# READY
# =========================
func _ready() -> void:
	enemy.setup(self, max_health)
	enemy.max_health = 12
	enemy.current_health = enemy.max_health

	# 🔥 CALCULAR XP ALEATORIA
	enemy.exp_reward = randi_range(exp_min, exp_max)

	enemy.died.connect(_on_enemy_died)
	enemy.damaged.connect(_on_enemy_damaged)
	add_to_group("enemies")
	add_to_group("slime")

	if health_bar:
		health_bar.max_value = enemy.max_health
		health_bar.value = enemy.current_health
		health_bar.visible = false

	if animation:
		animation.play("idle_front")

# =========================
# PHYSICS
# =========================
func _physics_process(delta: float) -> void:
	if enemy.has_died:
		return

	# 🔴 Knockback tiene prioridad
	if enemy.update_knockback(delta):
		move_and_slide()
		return

	if not enemy.can_move or enemy.is_hurt:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_enemy_ai(delta)
	move_and_slide()

# =========================
# AI
# =========================
func _enemy_ai(delta: float) -> void:
	timer += delta

	match state:
		"idle":
			velocity = Vector2.ZERO
			if timer >= idle_time:
				_start_moving()

		"move":
			velocity = direction * speed
			if timer >= move_time:
				_start_idle()

		"panic":
			if player:
				direction = (global_position - player.global_position).normalized()
			velocity = direction * panic_speed

			if not player:
				if global_position.distance_to(panic_origin) >= extra_escape_distance:
					_start_idle()

	_update_last_direction_from_velocity()
	_update_animation()

# =========================
# STATES
# =========================
func _start_idle() -> void:
	state = "idle"
	timer = 0.0
	velocity = Vector2.ZERO

func _start_moving() -> void:
	state = "move"
	timer = 0.0
	_set_random_direction()

func _start_panic() -> void:
	if not player:
		return
	state = "panic"
	timer = 0.0
	panic_origin = global_position
	direction = (global_position - player.global_position).normalized()

# =========================
# ANIMATION
# =========================
func _update_animation() -> void:
	if not animation:
		return

	if velocity == Vector2.ZERO:
		animation.play("idle_" + last_direction)
	else:
		var prefix := "walk_"
		if state == "panic":
			prefix = "run_"
		animation.play(prefix + last_direction)


func _update_last_direction_from_velocity() -> void:
	if velocity == Vector2.ZERO:
		return

	if abs(velocity.x) > abs(velocity.y):
		last_direction = "right_side" if velocity.x > 0 else "left_side"
	else:
		last_direction = "front" if velocity.y > 0 else "back"

# =========================
# UTILS
# =========================
func _set_random_direction() -> void:
	var angle := randf() * TAU
	direction = Vector2(cos(angle), sin(angle)).normalized()

# =========================
# PLAYER DETECTION
# =========================
func _on_vision_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		_start_panic()

func _on_vision_area_body_exited(body: Node2D) -> void:
	if body == player:
		player = null

# =========================
# DAMAGE API
# =========================
func take_damage(amount: float, hit_direction: String = "front") -> void:
	last_direction = hit_direction
	enemy.take_damage(amount)

func _on_enemy_damaged() -> void:
	if health_bar:
		health_bar.value = enemy.current_health
		health_bar.visible = true

	if animation:
		var anim := "hurt_" + last_direction
		if animation.sprite_frames.has_animation(anim):
			animation.play(anim)

func _on_enemy_died(exp_amount: int) -> void:
	if exp_amount > 0:
		var player_node := get_tree().get_first_node_in_group("player")
		if player_node and player_node.has_method("gain_experience"):
			player_node.gain_experience(exp_amount)

	velocity = Vector2.ZERO
	set_physics_process(false)
	set_process(false)

	if health_bar:
		health_bar.visible = false

	await _play_death_animation()
	_drop_item()
	await _fade_out()

	queue_free()

func _play_death_animation() -> void:
	if not animation:
		return

	var anim := "dying_" + last_direction
	if animation.sprite_frames.has_animation(anim):
		animation.play(anim)
		await animation.animation_finished
	elif animation.sprite_frames.has_animation("dying_front"):
		animation.play("dying_front")
		await animation.animation_finished

func _fade_out() -> void:
	var tween := get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.5)
	await tween.finished

func _drop_item() -> void:
	if not pickup_scene or not drop_item:
		return

	var pickup := pickup_scene.instantiate()
	pickup.item_data = drop_item
	pickup.amount = drop_amount
	pickup.global_position = global_position

	var world := get_tree().current_scene
	if world:
		world.add_child(pickup)
