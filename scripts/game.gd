extends Node2D
## Port of room_object plus the upgrade features: score, lives, rock and UFO
## spawning, power-up drops, respawn, screen shake, sounds, popups and HUD.

const ROOM_WIDTH := 1366.0
const ROOM_HEIGHT := 768.0
const POWERUP_DROP_CHANCE := 0.12

const PlayerScene := preload("res://scenes/player.tscn")
const RockScene := preload("res://scenes/rock.tscn")
const ExplosionScene := preload("res://scenes/explosion.tscn")
const UfoScene := preload("res://scenes/ufo.tscn")
const PowerupScene := preload("res://scenes/powerup.tscn")

const SOUNDS := {
	"shoot": preload("res://sounds/shoot.wav"),
	"explosion": preload("res://sounds/explosion.wav"),
	"death": preload("res://sounds/death.wav"),
	"powerup": preload("res://sounds/powerup.wav"),
	"upgrade": preload("res://sounds/upgrade.wav"),
}

var points: int = 0
var lives: int = 3
var game_over: bool = false
var weapon_tier: int = 1
var next_rock_score: int = 750
var shake_strength: float = 0.0

@onready var respawn_timer: Timer = $RespawnTimer
@onready var ufo_timer: Timer = $UfoTimer
@onready var camera: Camera2D = $Camera2D
@onready var score_label: Label = $HUD/ScoreLabel
@onready var high_score_label: Label = $HUD/HighScoreLabel
@onready var lives_label: Label = $HUD/LivesLabel
@onready var weapon_label: Label = $HUD/WeaponLabel
@onready var powerup_label: Label = $HUD/PowerupLabel
@onready var center_label: Label = $HUD/CenterLabel


func _ready() -> void:
	# Same starting layout as Room1 in the GameMaker project.
	spawn_player(Vector2(576, 384), 1, 0.0)
	spawn_rock(Vector2(256, 672), true)
	spawn_rock(Vector2(768, 160), false)
	_schedule_ufo()


func _process(delta: float) -> void:
	score_label.text = "Score: %d" % points
	high_score_label.text = "High Score: %d" % Globals.high_score
	lives_label.text = "Lives: %d" % lives

	match weapon_tier:
		3:
			weapon_label.text = "Weapon: Ultimate Triple Auto"
		2:
			weapon_label.text = "Weapon: Dual Shot | Ultimate unlocks at 5000 points"
		_:
			weapon_label.text = "Dual Shot unlocks at 2500 points"

	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		center_label.text = "GAME OVER\nRestarting..." if game_over else "SHIP DESTROYED\nRespawning..."
		center_label.visible = true
		powerup_label.text = ""
	else:
		center_label.visible = false
		var player: Node = players[0]
		if player.rapid_fire_time > 0.0:
			powerup_label.text = "RAPID FIRE %.1fs" % player.rapid_fire_time
		elif player.invincible_time > 0.0:
			powerup_label.text = "SHIELD %.1fs" % player.invincible_time
		else:
			powerup_label.text = ""

	# Screen shake decays over time.
	if shake_strength > 0.0:
		shake_strength = maxf(shake_strength - 30.0 * delta, 0.0)
		camera.offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
	else:
		camera.offset = Vector2.ZERO


func spawn_player(pos: Vector2, tier: int, invincible: float) -> void:
	var player := PlayerScene.instantiate()
	player.position = pos
	player.tier = tier
	player.invincible_time = invincible
	add_child(player)


func spawn_rock(pos: Vector2, big: bool) -> Node:
	var rock := RockScene.instantiate()
	rock.position = pos
	rock.big = big
	add_child(rock)
	return rock


func spawn_powerup(pos: Vector2) -> void:
	var powerup := PowerupScene.instantiate()
	powerup.position = pos
	powerup.type = randi() % 3
	add_child(powerup)


func maybe_drop_powerup(pos: Vector2) -> void:
	if randf() < POWERUP_DROP_CHANCE:
		spawn_powerup(pos)


func spawn_explosion(pos: Vector2, color: Color = Color.WHITE) -> void:
	var explosion := ExplosionScene.instantiate()
	explosion.position = pos
	explosion.modulate = color
	add_child(explosion)


func spawn_popup(pos: Vector2, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos + Vector2(-24, -36)
	label.z_index = 50
	add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 40.0, 0.7)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.7)
	tween.tween_callback(label.queue_free)


func play_sound(sound_name: String, pitch_min := 1.0, pitch_max := 1.0, volume_db := -8.0) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = SOUNDS[sound_name]
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func add_shake(strength: float) -> void:
	shake_strength = maxf(shake_strength, strength)


func rock_count() -> int:
	return get_tree().get_nodes_in_group("rock").size()


func max_rocks() -> int:
	return mini(8 + points / 1000, 16)


## Called when a bullet destroys a rock or UFO.
func add_points(amount: int) -> void:
	points += amount
	Globals.high_score = maxi(Globals.high_score, points)

	var rock_interval := 750
	if points >= 5000:
		rock_interval = 250
	elif points >= 2500:
		rock_interval = 500

	if points >= next_rock_score:
		if rock_count() < max_rocks():
			spawn_rock(Vector2(-100, randf_range(0, ROOM_HEIGHT - 1)), true)
		next_rock_score += rock_interval


## Called by the player when it collides with a rock or hazard.
func player_died() -> void:
	lives = maxi(0, lives - 1)
	game_over = lives <= 0
	Globals.save_high_score()
	respawn_timer.start(2.0)


func _on_respawn_timer_timeout() -> void:
	if game_over:
		get_tree().reload_current_scene()
	else:
		spawn_player(Vector2(ROOM_WIDTH * 0.5, ROOM_HEIGHT * 0.5), weapon_tier, 3.0)


func _schedule_ufo() -> void:
	ufo_timer.start(randf_range(15.0, 25.0))


func _on_ufo_timer_timeout() -> void:
	# One UFO at a time, and only once the game has warmed up a little.
	if points >= 300 and get_tree().get_nodes_in_group("hazard").is_empty():
		var ufo := UfoScene.instantiate()
		var from_left := randf() < 0.5
		ufo.move_dir = 1.0 if from_left else -1.0
		ufo.base_y = randf_range(100, ROOM_HEIGHT - 200)
		ufo.position = Vector2(-60 if from_left else ROOM_WIDTH + 60, ufo.base_y)
		add_child(ufo)
	_schedule_ufo()
