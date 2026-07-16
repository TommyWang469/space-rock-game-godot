extends Area2D
## Power-up dropped by destroyed rocks. Drifts slowly, blinks when about to
## expire. Types: 0 = shield, 1 = extra life, 2 = rapid fire.

const LIFETIME := 10.0
const BLINK_TIME := 2.5
const DRIFT_SPEED := 30.0

const TYPE_TEXTURES := [
	preload("res://sprites/powerup_shield.png"),
	preload("res://sprites/powerup_life.png"),
	preload("res://sprites/powerup_rapid.png"),
]

var type: int = 0
var life := LIFETIME
var drift := Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("powerup")
	sprite.texture = TYPE_TEXTURES[type]
	drift = Vector2.RIGHT.rotated(randf() * TAU) * DRIFT_SPEED


func _physics_process(delta: float) -> void:
	position += drift * delta

	life -= delta
	if life <= 0.0:
		queue_free()
	elif life < BLINK_TIME:
		visible = fmod(life, 0.3) > 0.12
