extends Area2D
## Enemy UFO: crosses the screen with a sine bob, fires aimed shots at the
## player, and is worth 200 points when destroyed.

const SPEED := 120.0
const BOB_AMPLITUDE := 40.0
const BOB_FREQUENCY := 2.5
const SHOOT_INTERVAL := 1.6
const ROOM := Vector2(1366, 768)

const EnemyBulletScene := preload("res://scenes/enemy_bullet.tscn")

var move_dir := 1.0          # 1 = left-to-right, -1 = right-to-left
var base_y := 200.0
var time := 0.0
var shoot_timer := SHOOT_INTERVAL

@onready var game: Node2D = get_parent()


func _ready() -> void:
	add_to_group("hazard")
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	time += delta
	position.x += SPEED * move_dir * delta
	position.y = base_y + sin(time * BOB_FREQUENCY) * BOB_AMPLITUDE

	# Left once it has fully crossed the room.
	if (move_dir > 0 and position.x > ROOM.x + 80) \
			or (move_dir < 0 and position.x < -80):
		queue_free()
		return

	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = SHOOT_INTERVAL
		_shoot()


func _shoot() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return

	var bullet := EnemyBulletScene.instantiate()
	bullet.position = position + Vector2(0, 16)
	bullet.velocity = (players[0].position - bullet.position).normalized() * 300.0
	game.add_child(bullet)
	game.play_sound("shoot", 0.5, 0.6)


func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group("bullet"):
		return

	area.queue_free()
	game.add_points(200)
	game.spawn_popup(position, "+200")
	game.spawn_explosion(position, Color(1.0, 0.6, 0.3))
	game.play_sound("explosion", 0.7, 0.8)
	game.add_shake(8.0)
	queue_free()
