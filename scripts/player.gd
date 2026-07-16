extends Area2D
## Port of player_object / fancy_player_object / ultimate_player_object.
## The three GameMaker objects shared identical Step code, so here they are
## one scene with a `tier` (1 = basic, 2 = dual shot, 3 = ultimate triple auto).
## Upgrades: power-up pickups (shield / extra life / rapid fire), thrust
## particles, hazard (UFO + enemy bullet) collisions and sound effects.

# GameMaker ran at 60 fps; per-frame values are converted to per-second.
const ACCELERATION := 240.0        # 0.05 px/frame^2
const TURN_SPEED := 240.0          # 4 degrees/frame, in degrees/second
const EDGE_MARGIN := 32.0          # half of the largest ship sprite dimension
const ROOM := Vector2(1366, 768)

const BulletScene := preload("res://scenes/bullet.tscn")

const TIER_TEXTURES := {
	1: preload("res://sprites/player.png"),
	2: preload("res://sprites/fancy_player.png"),
	3: preload("res://sprites/ultimate_player.png"),
}

enum PowerupType { SHIELD, EXTRA_LIFE, RAPID_FIRE }

var tier: int = 1
var velocity := Vector2.ZERO
var invincible_time: float = 0.0
var shoot_cooldown: float = 0.0
var rapid_fire_time: float = 0.0

@onready var game: Node2D = get_parent()
@onready var sprite: Sprite2D = $Sprite2D
@onready var thrust_particles: CPUParticles2D = $ThrustParticles


func _ready() -> void:
	add_to_group("player")
	sprite.texture = TIER_TEXTURES[tier]
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if shoot_cooldown > 0.0:
		shoot_cooldown -= delta
	rapid_fire_time = maxf(rapid_fire_time - delta, 0.0)

	# Weapon upgrades at 2500 and 5000 points (lives refill on upgrade).
	if game.weapon_tier < 2 and tier == 1 and game.points >= 2500:
		_upgrade(2)
	elif game.weapon_tier < 3 and tier == 2 and game.points >= 5000:
		_upgrade(3)

	# Movement: brake / thrust / turn.
	var thrusting := false
	if Input.is_action_pressed("brake"):
		velocity = Vector2.ZERO
	elif Input.is_action_pressed("thrust"):
		velocity += Vector2.RIGHT.rotated(rotation) * ACCELERATION * delta
		thrusting = true

	thrust_particles.emitting = thrusting

	if Input.is_action_pressed("turn_left"):
		rotation -= deg_to_rad(TURN_SPEED) * delta
	if Input.is_action_pressed("turn_right"):
		rotation += deg_to_rad(TURN_SPEED) * delta

	position += velocity * delta

	# Keep the entire ship inside the room, even while it is rotating.
	position.x = clampf(position.x, EDGE_MARGIN, ROOM.x - EDGE_MARGIN)
	position.y = clampf(position.y, EDGE_MARGIN, ROOM.y - EDGE_MARGIN)

	_handle_shooting()
	_handle_invincibility(delta)


func _handle_shooting() -> void:
	var shoot_now := Input.is_action_just_pressed("shoot")

	# The ultimate ship auto-fires while space is held down;
	# the rapid-fire power-up gives every ship held-button auto-fire.
	if tier == 3 and Input.is_key_pressed(KEY_SPACE):
		shoot_now = true
	if rapid_fire_time > 0.0 and Input.is_action_pressed("shoot"):
		shoot_now = true

	if not shoot_now or shoot_cooldown > 0.0:
		return

	var side := Vector2.RIGHT.rotated(rotation + PI / 2) * 10.0

	match tier:
		3:
			for shot in [-1, 0, 1]:
				_fire_bullet(position + side * shot)
			shoot_cooldown = 0.18
		2:
			_fire_bullet(position + side)
			_fire_bullet(position - side)
		_:
			_fire_bullet(position)

	if rapid_fire_time > 0.0:
		shoot_cooldown = 0.12

	game.play_sound("shoot", 0.9, 1.1, -12.0)


func _fire_bullet(pos: Vector2) -> void:
	var bullet := BulletScene.instantiate()
	bullet.position = pos
	bullet.rotation = rotation
	game.add_child(bullet)


func _handle_invincibility(delta: float) -> void:
	if invincible_time > 0.0:
		invincible_time -= delta
		var glow_pulse := (sin(Time.get_ticks_msec() * 0.012) + 1.0) * 0.5
		sprite.modulate = Color.WHITE.lerp(Color.AQUA, 0.4 + glow_pulse * 0.4)
		sprite.modulate.a = 0.7 + glow_pulse * 0.3
	else:
		invincible_time = 0.0
		sprite.modulate = Color.WHITE


func _upgrade(new_tier: int) -> void:
	tier = new_tier
	game.weapon_tier = new_tier
	game.lives = 3
	shoot_cooldown = 0.0
	sprite.texture = TIER_TEXTURES[new_tier]
	game.play_sound("upgrade")
	game.spawn_popup(position, "WEAPON UPGRADE!")


func _collect_powerup(powerup: Area2D) -> void:
	match powerup.type:
		PowerupType.SHIELD:
			invincible_time = maxf(invincible_time, 6.0)
			game.spawn_popup(position, "SHIELD!")
		PowerupType.EXTRA_LIFE:
			game.lives += 1
			game.spawn_popup(position, "+1 LIFE")
		PowerupType.RAPID_FIRE:
			rapid_fire_time = 8.0
			game.spawn_popup(position, "RAPID FIRE!")

	game.play_sound("powerup")
	powerup.queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("powerup"):
		_collect_powerup(area)
		return

	if not (area.is_in_group("rock") or area.is_in_group("hazard")):
		return
	if invincible_time > 0.0:
		return

	game.play_sound("death")
	game.add_shake(12.0)
	game.spawn_explosion(position)
	game.player_died()
	queue_free()
