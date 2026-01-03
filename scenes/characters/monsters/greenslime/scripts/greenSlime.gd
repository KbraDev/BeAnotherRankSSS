extends Enemy ## GREEN SLIME

# === Stats específicos del Slime ===
@export var speed: float = 50.0
@export var panic_speed: float = 80.0
@export var idle_time: float = 4.0
@export var move_time: float = 5.0
@export var extra_escape_distance: float = 200.0

@onready var vision_area: Area2D = $VisionArea

signal slime_died

# === Variables internas ===
var player: Node2D = null
var direction: Vector2 = Vector2.ZERO
var timer: float = 0.0
var state: String = "idle"
var panic_origin: Vector2
var traveled_distance: float = 0.0

func _ready() -> void:
	super._ready() # inicializa stats base de Enemy
	enemy_name = "Slime Verde"
	animation.play("idle_front")
	add_to_group("slime")
	set_process(true)

func _process(delta: float) -> void:
	if has_died:
		return

	timer += delta

	match state:
		"idle":
			velocity = Vector2.ZERO
			if timer >= idle_time:
				start_moving()
		"move":
			velocity = direction * speed
			if timer >= move_time:
				start_idle()
		"panic":
			if player:
				var flee_direction = (global_position - player.global_position).normalized()
				velocity = flee_direction * panic_speed
				update_last_direction(flee_direction)
			else:
				velocity = direction * panic_speed
				traveled_distance = panic_origin.distance_to(global_position)
				if traveled_distance >= extra_escape_distance:
					start_idle()

	move_and_slide()

# === Estados ===
func start_idle():
	state = "idle"
	timer = 0
	animation.play("idle_" + last_direction)

func start_moving():
	state = "move"
	timer = 0
	set_random_direction()
	animation.play("walk_" + last_direction)

func start_panic():
	state = "panic"
	timer = 0
	traveled_distance = 0.0
	panic_origin = global_position
	direction = (global_position - player.global_position).normalized()
	update_last_direction(direction)
	animation.play("run_" + last_direction)

# === Utilidades ===
func set_random_direction():
	var angle = randf() * TAU
	direction = Vector2(cos(angle), sin(angle)).normalized()
	update_last_direction(direction)

func update_last_direction(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		last_direction = "right_side" if dir.x > 0 else "left_side"
	else:
		last_direction = "front" if dir.y > 0 else "back"

# === Detección de jugador ===
func _on_vision_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		start_panic()

func _on_vision_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = null


func _on_enemy_died() -> void:
	emit_signal("slime_died")
	super._on_enemy_died()
