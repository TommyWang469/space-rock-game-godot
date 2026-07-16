extends Node
## Persistent state (high score, saved to disk) and the pause toggle.

const SAVE_PATH := "user://highscore.save"

var high_score: int = 0


func _ready() -> void:
	# Keep processing input while the tree is paused so Esc can unpause.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_high_score()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		var tree := get_tree()
		tree.paused = not tree.paused
		for label in tree.get_nodes_in_group("pause_label"):
			label.visible = tree.paused


func save_high_score() -> void:
	var config := ConfigFile.new()
	config.set_value("scores", "high_score", high_score)
	config.save(SAVE_PATH)


func _load_high_score() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		high_score = config.get_value("scores", "high_score", 0)
