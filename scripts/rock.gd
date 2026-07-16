extends Area2D
## Port of rockbig_object / rocksmall_object (they shared identical code,
## switching sprites when hit). `big` selects which form this rock is in.
## Upgrades: explosion sound, screen shake, score popup and power-up drops.

const ROOM := Vector2(1366, 768)
const WRAP_MARGIN := 100.0
const SPIN_SPEED := 60.0           # 1 degree/frame at 60 fps

const BIG_TEXTURE := preload("res://sprites/rock_big.png")
const SMALL_TEXTURE := preload("res://sprites/rock_small.png")
const BIG_RADIUS := 78.0
const SMALL_RADIUS := 36.0

var big: bool = true
var move_angle: float = 0.0

@onready var game: Node2D = get_parent()
@onready var sprite: Sprite2D = $Sprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("rock")
	shape.shape = CircleShape2D.new()
	move_angle = randf() * TAU
	rotation = randf() * TAU
	_apply_size()
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	# Rocks steadily accelerate as the player's score increases
	# (1 -> 2.5 px/frame in GameMaker, converted to px/second).
	var speed := minf(1.0 + game.points / 5000.0, 2.5) * 60.0
	position += Vector2.RIGHT.rotated(move_angle) * speed * delta
	rotation += deg_to_rad(SPIN_SPEED) * delta

	# move_wrap with a 100 px margin.
	if position.x < -WRAP_MARGIN:
		position.x += ROOM.x + WRAP_MARGIN * 2
	elif position.x > ROOM.x + WRAP_MARGIN:
		position.x -= ROOM.x + WRAP_MARGIN * 2
	if position.y < -WRAP_MARGIN:
		position.y += ROOM.y + WRAP_MARGIN * 2
	elif position.y > ROOM.y + WRAP_MARGIN:
		position.y -= ROOM.y + WRAP_MARGIN * 2


func _apply_size() -> void:
	sprite.texture = BIG_TEXTURE if big else SMALL_TEXTURE
	shape.shape.radius = BIG_RADIUS if big else SMALL_RADIUS


func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group("bullet"):
		return

	area.queue_free()
	game.add_points(50)
	game.spawn_popup(position, "+50")
	game.spawn_explosion(position)
	game.play_sound("explosion", 1.0, 1.3, -10.0)
	game.add_shake(4.0)
	game.maybe_drop_powerup(position)

	move_angle = randf() * TAU

	if big:
		# Big rock splits into two small rocks.
		big = false
		_apply_size()
		if game.rock_count() < game.max_rocks():
			game.spawn_rock(position, false)
	elif game.rock_count() < game.max_rocks():
		# Small rock respawns as a big rock entering from the left edge.
		big = true
		_apply_size()
		position.x = -100
	else:
		queue_free()
