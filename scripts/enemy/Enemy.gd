extends CharacterBody2D
class_name Enemy
## Base class for all enemies in the game.
## Handles core enemy logic: stats, health, death, drops, knockback, hit reactions, and shared audio/animation behavior.

# ====================================================================
# ========================= BASE STATS ================================
# ====================================================================

@export_group("Base Stats")
@export var max_health: float = 10.0                 # Maximum enemy HP
@export var move_speed: float = 50.0                 # Base movement speed (actual AI movement is defined in child classes)
@export var xp_reward_range: Vector2i = Vector2i(5, 10) # XP dropped on death
@export var armor: float = 0.0                       # Damage reduction value
@export var drop_item: Resource                      # Optional item dropped on death
@export var enemy_name: String = "Generic Enemy"     # Display/Identifier name

# ====================================================================
# ======================= KNOCKBACK / PHYSICS =========================
# ====================================================================

@export_group("Knockback")
@export var mass: float = 3.6                        # Higher mass = weaker knockback
@export var knockback_friction: float = 200.0        # How fast knockback velocity decays
var is_being_pushed: bool = false                    # True while knockback is active

var knockback_velocity: Vector2 = Vector2.ZERO       # (Unused in final knockback system, but kept for compatibility)
var knockback_time: float = 0.0
var knockback_duration: float = 0.15                 # Duration of forced push before AI regains control

# ====================================================================
# ======================= COMMON COMPONENTS ===========================
# ====================================================================

@onready var health_bar: Node = $HealthBar if has_node("HealthBar") else null
@onready var animation: AnimatedSprite2D = (
	$AnimatedSprite2D if has_node("AnimatedSprite2D") else null
)

# Optional audio components
@onready var audio_hit: AudioStreamPlayer2D = $Audio_Hit if has_node("Audio_Hit") else null
@onready var audio_attack: AudioStreamPlayer2D = $Audio_Attack if has_node("Audio_Attack") else null
@onready var audio_death: AudioStreamPlayer2D = $Audio_Death if has_node("Audio_Death") else null

# ====================================================================
# ========================= INTERNAL STATE ============================
# ====================================================================

var current_health: float
var has_died: bool = false
var _death_failsafe_timer: Timer = null              # Ensures enemies don't get stuck in death animations
var is_hurt: bool = false                            # Blocks AI during hurt animations
var can_move: bool = true
var last_direction: String = "front"

# ====================================================================
# ============================== READY ================================
# ====================================================================

# --------------------------------------------------------------------
# _ready()
# --------------------------------------------------------------------
# Initializes health, UI components, animation bindings, and ensures
# the enemy is added to the "enemies" group. Also ensures that if an
# AnimatedSprite2D is not directly assigned, the script searches for
# one among the children.
# --------------------------------------------------------------------
func _ready() -> void:
	current_health = max_health

	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.visible = false

	# Auto-detect AnimatedSprite2D if not manually assigned
	if animation == null:
		for n in get_children():
			if n is AnimatedSprite2D:
				animation = n
				break

	# Connect to animation_finished for flows like death/hurt
	if animation:
		if not animation.is_connected("animation_finished", Callable(self, "_on_animation_finished_internal")):
			animation.animation_finished.connect(_on_animation_finished_internal)

	add_to_group("enemies")

# ====================================================================
# ========================== PHYSICS PROCESS ==========================
# ====================================================================

# --------------------------------------------------------------------
# _physics_process(delta)
# --------------------------------------------------------------------
# PRIORITY ORDER:
# 1. Active knockback (timer-based): enemy is forced to move.
# 2. Passive push state (is_being_pushed): friction gradually stops it.
# 3. Normal movement: delegated to child enemy AI scripts.
#
# Child AI scripts ONLY define velocity. This function acts as a
# controller that decides which system overrides movement each frame.
# --------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	# --- GLOBAL FREEZE ---
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	# --- Forced knockback mode ---
	if knockback_time > 0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 300 * delta)
		knockback_time -= delta
		move_and_slide()
		return  # AI is locked during knockback

	# --- Passive friction-based knockback ---
	if is_being_pushed:
		velocity = velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
		move_and_slide()
		return  # AI movement cannot override knockback

	# --- Normal behavior ---
	move_and_slide()


# ====================================================================
# ============================ DAMAGE SYSTEM ==========================
# ====================================================================

# --------------------------------------------------------------------
# _take_damage(amount, last_direction)
# --------------------------------------------------------------------
# Central damage-processing function.
# Handles:
#   - Damage reduction using armor
#   - Health bar UI updates
#   - Playing hurt animations based on attack direction
#   - Locking AI during hurt animation
#   - Triggering death flow when reaching 0 HP
#
# Child classes may override `_on_enemy_hurt_end()` for specific logic.
# --------------------------------------------------------------------
func take_damage(amount: float, last_direction: String = "front") -> void:
	if has_died:
		return

	var final_damage = max(amount - armor, 0.0)
	current_health = max(current_health - final_damage, 0.0)

	if health_bar:
		health_bar.value = current_health
		health_bar.visible = true

	play_sound("hit")

	# 🔴 MUERTE INMEDIATA (SIN await)
	if current_health <= 0:
		die(last_direction)
		return

	is_hurt = true

	# --- HURT ANIMATION ---
	if animation:
		var hurt_anim = "hurt_" + last_direction
		animation.stop()

		if animation.sprite_frames.has_animation(hurt_anim):
			animation.play(hurt_anim)
		elif animation.sprite_frames.has_animation("hurt_front"):
			animation.play("hurt_front")

		await animation.animation_finished

	is_hurt = false

	if has_method("_on_enemy_hurt_end"):
		_on_enemy_hurt_end()

# ====================================================================
# =============================== DEATH ===============================
# ====================================================================

# --------------------------------------------------------------------
# die(direction)
# --------------------------------------------------------------------
# Handles the full enemy death sequence:
#   - Stops movement/AI
#   - Disables collisions
#   - Plays death animation (directional if available)
#   - Starts failsafe timer to avoid stuck states
#   - Fades out sprite with a tween
#   - Calls _on_enemy_died() at the end
#
# Ensures enemies ALWAYS complete their death flow gracefully.
# --------------------------------------------------------------------
func die(dir: String = "front") -> void:
	if has_died:
		return
	
	has_died = true
	can_move = false
	is_hurt = false

	velocity = Vector2.ZERO
	set_physics_process(false)
	set_process(false)

	play_sound("death")

	# Disable all physics bodies
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D or child is Area2D:
			child.set_deferred("monitoring", false)
			child.set_deferred("disabled", true)

	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	# --- ANIMATION & FAILSAFE ---
	if animation:
		var anim_name_dir = "dying_" + dir
		var has_dir_anim = animation.sprite_frames.has_animation(anim_name_dir)
		var has_default_anim = animation.sprite_frames.has_animation("dying")

		_death_failsafe_timer = Timer.new()
		_death_failsafe_timer.one_shot = true
		_death_failsafe_timer.wait_time = 4.0
		_death_failsafe_timer.timeout.connect(Callable(self, "_on_death_failsafe_timeout"))
		add_child(_death_failsafe_timer)
		_death_failsafe_timer.start()

		if has_dir_anim:
			animation.play(anim_name_dir)
			await animation.animation_finished
		elif has_default_anim:
			animation.play("dying")
			await animation.animation_finished
		else:
			_on_enemy_died()
			return
	else:
		_on_enemy_died()
		return

	# Stop and remove failsafe timer
	if _death_failsafe_timer:
		_death_failsafe_timer.stop()
		_death_failsafe_timer.queue_free()
		_death_failsafe_timer = null

	# Fade out corpse
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.5)
	tween.tween_callback(Callable(self, "_on_enemy_died"))

func _on_death_failsafe_timeout() -> void:
	_on_enemy_died()

# Used only for analytic animation flow
func _on_animation_finished_internal(_anim_name: String) -> void:
	pass

# --------------------------------------------------------------------
# _on_enemy_died()
# --------------------------------------------------------------------
# Final cleanup after the death animation/tween is done.
# Responsible for:
#   - Dropping items
#   - Giving XP to the player
#   - Cleaning timers
#   - Deleting the enemy node
# --------------------------------------------------------------------
func _on_enemy_died() -> void:
	if drop_item:
		var pickup_scene = preload("res://scenes/World_pick-ups/pick_ups_items.tscn")
		var pickup = pickup_scene.instantiate()
		pickup.item_data = drop_item
		pickup.amount = 1
		pickup.global_position = global_position

		var cs = get_tree().current_scene
		if cs:
			cs.add_child(pickup)

	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("gain_experience"):
		var xp = randi_range(xp_reward_range.x, xp_reward_range.y)
		player.gain_experience(xp)

	queue_free()

# ====================================================================
# ============================ KNOCKBACK ==============================
# ====================================================================

# --------------------------------------------------------------------
# apply_knockback(direction, force)
# --------------------------------------------------------------------
# Knockback system explanation:
#
# 1. Enemy velocity is overwritten with:
#        velocity = direction.normalized() * (force / mass)
#
#    - Force determines the raw push strength.
#    - Mass lowers the effect (heavier = less push).
#
# 2. is_being_pushed becomes TRUE:
#       _physics_process() stops AI movement.
#       friction reduces velocity each frame until stopped.
#
# 3. After knockback_duration (0.15s):
#       is_being_pushed becomes FALSE,
#       AI regains control.
#
# This system provides:
#   - Consistent push behavior
#   - Smooth deceleration (feels physical)
#   - No interference with hurt/death animations
# --------------------------------------------------------------------
func apply_knockback(direction: Vector2, force: float, player_force: float = 0.0) -> void:
	is_being_pushed = true
	velocity = direction.normalized() * (force / mass)

	await get_tree().create_timer(knockback_duration).timeout
	is_being_pushed = false

# ====================================================================
# ============================== AUDIO ===============================
# ====================================================================

# --------------------------------------------------------------------
# play_sound(type)
# --------------------------------------------------------------------
# Plays one of the optional enemy sound effects:
#   - "hit"
#   - "attack"
#   - "death"
#
# Pitch is slightly randomized each time to add variation and prevent
# repetitive audio.
# --------------------------------------------------------------------
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
		player.pitch_scale = randf_range(0.95, 1.05)
		player.play()

# ====================================================================
# ========================= OVERRIDABLE CALLBACK =====================
# ====================================================================

# --------------------------------------------------------------------
# _on_enemy_hurt_end()
# --------------------------------------------------------------------
# Called when the hurt animation finishes and the enemy is ready to
# return to normal behavior. Child classes may override this to reset
# states, choose new behaviors, etc.
# --------------------------------------------------------------------
func _on_enemy_hurt_end() -> void:
	pass
