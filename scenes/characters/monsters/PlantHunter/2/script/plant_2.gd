extends CharacterBody2D ## Plant Hunter 1

#=====================
#=== Configuración ===
#=====================

@export var walk_speed: float = 12.0
@export var run_speed: float = 30.0
@export var idle_time: float = 5.0
@export var walk_time: float = 4.0
@export var attack_interval: float = 1.4
@export var health: float = 18.0

@onready var animation = $AnimatedSprite2D
@onready var vision_area = $Vision_area
@onready var attack_vision_area = $attack_vision_area
@onready var attack_area = $attack_area
@onready var health_bar = $health_bar

signal plant_died
var has_died = false
signal player_hit(damage: float)

var player: Node2D = null
var direction: Vector2 = Vector2.ZERO
var state: String = "idle"
var timer: float = 0.0
var attack_timer: float = 0.0
var last_direction: String = "front"
var is_attacking: bool = false
var can_attack: bool = false

# Barra de vida
var health_timer: Timer

#=====================
#=== Métodos base ===
#=====================

func _ready() -> void:
	animation.play("idle_front")
	
	# Configurar Timer para ocultar barra de vida
	health_timer = Timer.new()
	add_child(health_timer)
	health_timer.wait_time = 4.0
	health_timer.one_shot = true
	health_timer.connect("timeout", _on_hide_health_bar)
	health_bar.visible = false

func _process(delta: float) -> void:
	timer += delta
	
	match state:
		"idle":
			velocity = Vector2.ZERO
			if timer >= idle_time:
				start_walk()
		"walk":
			velocity = direction * walk_speed
			if timer >= walk_time:
				start_idle()
		"chase":
			if player:
				direction = (player.global_position - global_position).normalized()
				update_last_direction(direction)
				velocity = direction * run_speed
				
				var new_animation = "run_" + last_direction
				if animation.animation != new_animation:
					animation.play(new_animation)
				
				if can_attack:
					attack_timer += delta
					if attack_timer >= attack_interval:
						start_attack()
			else:
				start_walk()
		"attack":
			velocity = Vector2.ZERO
		"dead":
			velocity = Vector2.ZERO
	
	move_and_slide()

func _physics_process(delta: float) -> void:
	if state == "walk" and is_on_wall():
		set_random_direction()
	move_and_slide()

#=====================
#=== Estados ===
#=====================

func start_idle():
	state = "idle"
	timer = 0
	animation.play("idle_" + last_direction)

func start_walk():
	state = "walk"
	timer = 0
	set_random_direction()
	animation.play("walk_" + last_direction)

func start_chase():
	state = "chase"
	timer = 0
	attack_timer = 0
	
	if player:
		direction = (player.global_position - global_position).normalized()
		update_last_direction(direction)
		animation.play("run_" + last_direction)

func start_attack():
	if is_attacking:
		return
	
	is_attacking = true
	state = "attack"
	timer = 0
	attack_timer = 0
	animation.play("attack_" + last_direction)
	
	await get_tree().create_timer(1.0).timeout # delay de 1s para ejecutar ataque real
	
	# Confirmar si el jugador sigue en el área real de ataque
	if player and attack_area.overlaps_body(player):
		player.take_damage(12.0)
	
	is_attacking = false
	
	if player:
		start_chase()
	else:
		start_walk()

func die():
	if has_died:
		return
	
	has_died = true
	state = "dead"
	velocity = Vector2.ZERO
	animation.play("death_" + last_direction)
	await get_tree().create_timer(1.5).timeout
	emit_signal("plant_died")
	queue_free()

#============================
#=== Funciones auxiliares ===
#============================

func set_random_direction():
	var angle = randf() * TAU
	direction = Vector2(cos(angle), sin(angle)).normalized()
	update_last_direction(direction)

func update_last_direction(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		last_direction = "right_side" if dir.x > 0 else "left_side"
	else:
		last_direction = "front" if dir.y > 0 else "back"

func take_damage(amount: float):
	if state == "dead":
		return
	
	animation.play("hurt_" + last_direction)
	health -= amount
	health_bar.visible = true
	health_bar.value = health
	health_timer.start()
	
	if health <= 0:
		die()

func _on_hide_health_bar():
	health_bar.visible = false
	

func _on_animated_sprite_2d_animation_finished() -> void:
	if has_died and animation.animation == "death_" + last_direction:
		var pickup_scene = preload("res://scenes/World_pick-ups/pick_ups_items.tscn")
		var pickup = pickup_scene.instantiate()
		pickup.item_data = preload("res://items/resources/carnivorusPlant_fang.tres")
		pickup.amount = 1
		pickup.global_position = global_position

		get_tree().current_scene.add_child(pickup)

		emit_signal("slime_died")
		queue_free()

#=====================
#=== Señales ===
#=====================

func _on_vision_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		start_chase()

func _on_vision_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Jugador salió de visión")
		player = null
		start_walk()

func _on_attack_vision_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		can_attack = true
		print("Jugador entró en zona de ataque")

func _on_attack_vision_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		can_attack = false
		print("Jugador salió de zona de ataque")
