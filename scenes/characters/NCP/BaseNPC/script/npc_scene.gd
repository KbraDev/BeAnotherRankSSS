extends CharacterBody2D

@export var new_spritesheet: Texture2D
@export var speed: float = 100.0

@onready var anim := $AnimatedSprite2D
@onready var path_follow := get_parent() as PathFollow2D

const FRAME_SIZE = Vector2(48, 96)

const ANIM_NAMES = [
	"idle_front",
	"idle_left_side",
	"idle_right_side",
	"idle_back",
	"walk_front",
	"walk_left_side",
	"walk_right_side",
	"walk_back",
]

var last_position: Vector2
var last_direction: String = "front"
var can_move := true

func _ready():
	_generate_animations()
	last_position = global_position
	anim.play("idle_" + last_direction)


func _process(delta):
	if path_follow and can_move:
		path_follow.progress += speed * delta
	_update_animation()

func _generate_animations():
	var frames = SpriteFrames.new()

	for row in ANIM_NAMES.size():
		var anim_name = ANIM_NAMES[row]
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, true)
		frames.set_animation_speed(anim_name, 7)  # Walk animación rápida

		for i in range(4):  # 4 frames por animación
			var atlas := AtlasTexture.new()
			atlas.atlas = new_spritesheet
			atlas.region = Rect2(Vector2(i, row) * FRAME_SIZE, FRAME_SIZE)
			frames.add_frame(anim_name, atlas)

	anim.sprite_frames = frames

func _update_animation():
	var movement = global_position - last_position

	if not can_move or movement.length_squared() < 0.01:
		anim.play("idle_" + last_direction)
	else:
		if abs(movement.x) > abs(movement.y):
			last_direction = "right_side" if movement.x > 0 else "left_side"
		else:
			last_direction = "front" if movement.y > 0 else "back"

		anim.play("walk_" + last_direction)

	last_position = global_position
