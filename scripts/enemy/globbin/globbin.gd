extends Enemy
class_name Globbin

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_check = $CollisionCheck
@onready var detection_area = $DetectionArea

var direction: Vector2 = Vector2.ZERO
var last_direction: String = "front"
var player_detected = false
var player_target: Node2D = null

func _ready() -> void:
	super()
	randomize()
	_choose_new_direction()
	
	if collision_check: 
		collision_check.body_entered.connect(_on_collision_check_body_entered)
		
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)

func _physics_process(delta: float) -> void:
	if has_died:
		return

	if player_detected and player_target:
		_chase_player(delta)
	else:
		_patrol(delta)



# ===========================
# == Patrullaje del duende ==
# ===========================

func _choose_new_direction() -> void:
	var dirs = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	direction = dirs.pick_random()

	match direction:
		Vector2.LEFT:
			last_direction = "left_side"
		Vector2.RIGHT:
			last_direction = "right_side"
		Vector2.UP:
			last_direction = "back"
		Vector2.DOWN:
			last_direction = "front"

func _patrol(delta: float) -> void:
	velocity = direction * move_speed
	move_and_slide()
	_play_walk_animation()

	if randi() % 100 == 0:
		_choose_new_direction()


# ===========================
# == Deteccion del jugador ==
# ===========================

func _on_detection_area_body_entered(body: Node) -> void:
	if not body or not body.is_in_group("player"):
		return
	
	player_detected = true
	player_target = body
	print("Jugador detectado")
	
func _on_detection_area_body_exited(body: Node) -> void: 
	if not body or not body.is_in_group("player"):
		return
	
	player_detected = false
	player_target = null
	print("Jugador fuera de rango")
	
# =============================
# == Persecucion del jugador ==
# =============================

func _chase_player(delta: float) -> void:
	var to_player = (player_target.global_position - global_position).normalized()
	direction = to_player
	last_direction = _get_cardinal_direction(direction)
	
	velocity = direction * (move_speed * 1.5) 
	move_and_slide()
	_player_run_animation()
	
	print("persiguiendo al jugador -> ", last_direction, " ", direction)
	
# Funcion auxiliar para convertir direccion vectorial a animacion cardinal

func _get_cardinal_direction(vec: Vector2) -> String:
	if abs(vec.x) > abs(vec.y):
		return "right_side" if vec.x > 0 else "left_side"
	else:
		return "front" if vec.y > 0 else "back"
	

# =============================
# == Colision con el entorno ==
# =============================

func _on_collision_check_body_entered(body: Node) -> void:
	if not body:
		return

	# 🚫 Evitar el mismo globbin u otros enemigos
	if body.is_in_group("enemies") or body.is_in_group("player"):
		return

	# ✅ Detectar colisiones con el entorno
	if body is TileMap or body.get_class() == "TileMapLayer":
		_choose_new_direction()
		return

	# ✅ Detectar obstáculos físicos reales (StaticBody2D, etc.)
	if body is PhysicsBody2D:
		var c_layer = body.get_collision_layer()
		var c_mask  = body.get_collision_mask()

		# bits de capa/máscara (1=0b0001, 2=0b0010, 3=0b0100)
		var forbidden_layers = (1 << 2) | (1 << 3)
		var forbidden_masks  = (1 << 0) | (1 << 1)

		if (c_layer & forbidden_layers) != 0 or (c_mask & forbidden_masks) != 0:
			return

		_choose_new_direction()
		return

	# 🧩 Fallback por si se detecta cualquier otra cosa rara
	_choose_new_direction()

# =================
# == Animaciones ==
# =================

func _play_walk_animation() -> void:
	if not sprite:
		return

	var anim_name = "walk_" + last_direction
	if sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name:
			sprite.play(anim_name)
	else:
		print("⚠️ Falta animación:", anim_name)
		
func _player_run_animation() -> void:
	if not sprite: 
		return
	var anim_name = "run_" + last_direction
	if sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name:
			sprite.play(anim_name)
