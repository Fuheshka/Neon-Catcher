extends Control
class_name GameOverScreen

"""Shows a Game Over overlay and handles restart/quit actions."""

@export var restart_button: Button
@export var quit_button: Button
@onready var _events: Node = get_node("/root/Events")


func _ready() -> void:
	visible = false
	_events.connect("game_over", _on_game_over)
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_game_over() -> void:
	visible = true
	get_tree().paused = true


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().quit()
