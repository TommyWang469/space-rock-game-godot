extends CPUParticles2D
## Stand-in for GameMaker's ef_explosion / ef_firework layer effects.


func _ready() -> void:
	one_shot = true
	emitting = true
	await get_tree().create_timer(lifetime + 0.2).timeout
	queue_free()
