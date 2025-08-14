extends CharacterBody2D

# =============================
# CONFIGURACIÓN DE NPC PORCOPINE
# =============================

# Velocidad de movimiento en estado calmado
@export var calm_speed: float = 20.0
# Velocidad de movimiento en estado alerta
@export var alert_speed: float = 30.0

# =============================
# REFERENCIAS A NODOS INTERNOS
# =============================

# Controla las animaciones del NPC
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
# Área para detectar intrusos y cambiar a estado alerta
@onready var detection_area: Area2D = $DetectionArea

# =============================
# VARIABLES DE ESTADO
# =============================
# Estado actual del NPC: "calm" o "alert"
var state := "calm"

# =============================
# CONTROL DEL MOVIMIENTO
# =============================
# Dirección de movimiento actual
var direction := Vector2.ZERO
# Contador de tiempo en la dirección actual
var direction_timer := 0.0
# Tiempo que durará moviéndose en la dirección actual
var direction_duration := 0.0


func _ready():
	# Conectar señales del área de detección
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

	# Seleccionar una dirección inicial de movimiento
	_set_new_direction()


func _physics_process(delta: float):
	# Seleccionar velocidad según el estado
	var speed = calm_speed if state == "calm" else alert_speed

	# =============================
	# BUCLE DE MOVIMIENTO POR TIEMPO
	# =============================
	# Sumamos el tiempo transcurrido en esta dirección
	direction_timer += delta
	
	# Si hemos superado el tiempo asignado, elegimos nueva dirección
	if direction_timer >= direction_duration:
		_set_new_direction()

	# Aplicar velocidad en la dirección actual
	velocity = direction * speed
	
	# Mover y deslizar respetando colisiones
	move_and_slide()

	# Actualizar animación según dirección y estado
	_update_animation(direction)


func _set_new_direction():
	
	# Establece una nueva dirección de movimiento y un tiempo aleatorio
	# entre 4 y 9 segundos durante el cual se mantendrá esa dirección.
	
	# Reiniciamos el contador de tiempo
	direction_timer = 0.0
	# Asignamos un tiempo aleatorio en segundos
	direction_duration = randi_range(4, 9)

	# Elegimos una nueva dirección aleatoria
	# Restamos 0.5 para que el valor vaya de -0.5 a 0.5 y luego normalizamos
	direction = Vector2(randf() - 0.5, randf() - 0.5).normalized()


func _update_animation(dir: Vector2):
	
	# Selecciona la animación correcta según la dirección de movimiento
	# y el estado actual (calm o alert).
	# Si no hay movimiento, no actualizamos animación
	if dir == Vector2.ZERO:
		return

	# Prefijo según estado
	var anim_prefix = "walk" if state == "calm" else "walk_niddles"

	# Determinar si se mueve más en horizontal o vertical
	if abs(dir.x) > abs(dir.y):
		# Movimiento lateral
		anim.play(anim_prefix + ("_right_side" if dir.x > 0 else "_left_side"))
	else:
		# Movimiento frontal o trasero
		anim.play(anim_prefix + ("_front" if dir.y > 0 else "_back"))


func _on_detection_area_body_entered(body: Node2D) -> void:
	
	# Cuando un cuerpo entra en el área de detección,
	# si no pertenece al grupo 'porcopine', activamos estado alerta.
	if not body.is_in_group("porcopine"):
		state = "alert"


func _on_detection_area_body_exited(body: Node2D) -> void:
	
	# Cuando un cuerpo sale del área, comprobamos si aún quedan intrusos.
	# Si no hay más, regresamos a estado calm.
	
	var intrusos_presentes = false
	for b in detection_area.get_overlapping_bodies():
		if not b.is_in_group("porcopine"):
			intrusos_presentes = true
			break

	if not intrusos_presentes:
		state = "calm"
