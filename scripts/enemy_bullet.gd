extends Area2D
## Aimed shot fired by the UFO. Kills the player (unless shielded).

const ROOM := Vector2(1366, 768)

var velocity := Vector2.ZERO


func _ready() -> void:
	add_to_group("hazard")
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	position += velocity * delta

	if position.x < -16 or position.x > ROOM.x + 16 \
			or position.y < -16 or position.y > ROOM.y + 16:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	# The player script handles the death; the bullet just spends itself.
	if area.is_in_group("player"):
		queue_free()
