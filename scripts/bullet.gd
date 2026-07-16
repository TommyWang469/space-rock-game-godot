extends Area2D
## Port of bullet_object: speed 10 px/frame, destroyed once outside the room.

const SPEED := 600.0
const ROOM := Vector2(1366, 768)


func _ready() -> void:
	add_to_group("bullet")


func _physics_process(delta: float) -> void:
	position += Vector2.RIGHT.rotated(rotation) * SPEED * delta

	if position.x < -16 or position.x > ROOM.x + 16 \
			or position.y < -16 or position.y > ROOM.y + 16:
		queue_free()
