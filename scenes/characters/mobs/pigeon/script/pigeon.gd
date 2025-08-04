extends CharacterBody2D ## PIGEON

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var walk_area: Area2D = $WalkDetectionArea2
@onready var fly_area: Area2D = $FlyDetectionArea

var current_state: String = "idle"
var direction := 1 # 1 = derecha -1 = izq

var idle_timer := 0.0
var state_duration := 2.0

func _ready() -> void:
	walk_area.body_entered.connect(_on_walk_detection_area_body_entered)
	fly_area.body_entered.connect(_on_fly_detection_area_body_entered)

func _process(delta: float) -> void:
	if current_state in ["idle", "scratch", "walk"]:
		idle_timer += delta
		if idle_timer >= state_duration:
			idle_timer = 0.0
			_change_random_state()
		
	match current_state:
		"idle":
			sprite.play("idle")
		"scratch":
			sprite.play("scratch") # <- corregí el typo aquí si era 'scrathing'
		"walk":
			sprite.play("walk")
			velocity = Vector2(20 * direction, 0)
			move_and_slide()
		"fly":
			sprite.play("fly")
			velocity = Vector2(200 * direction, 0)
			move_and_slide()


func _change_random_state():
	var states = ["idle", "scratch", "walk"]
	current_state = states[randi() % states.size()]
	if current_state == "walk":
		direction = [1, -1][randi() % 2]
		sprite.flip_h = direction == -1

func _on_walk_detection_area_body_entered(body):
	if not body.is_in_group("pigeon"):
		current_state = "walk"
		direction = 1 if (global_position.x - body.global_position.x) > 0 else -1
		sprite.flip_h = direction == -1

func _on_fly_detection_area_body_entered(body):
	if not body.is_in_group("pigeon"):
		current_state = "fly"
		direction = 1 if (global_position.x - body.global_position.x) > 0 else -1
		sprite.flip_h = direction == -1
