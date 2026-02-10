extends Control
class_name MainMenu

"""Main menu UI with start/quit actions and a pulsing title."""

@export var start_button: Button
@export var quit_button: Button
@export var leaderboard_button: Button
@export var title_label: Label

var _title_tween: Tween
var _leaderboard_ui: Control

const LEADERBOARD_UI_SCENE = preload("res://scenes/LeaderboardUI.tscn")


func _ready() -> void:
	if is_instance_valid(start_button):
		start_button.pressed.connect(_on_start_pressed)
	if is_instance_valid(quit_button):
		quit_button.pressed.connect(_on_quit_pressed)
	if is_instance_valid(leaderboard_button):
		leaderboard_button.pressed.connect(_on_leaderboard_pressed)
	_start_title_pulse()
	_setup_leaderboard_ui()


func _setup_leaderboard_ui() -> void:
	# Instantiate the leaderboard UI
	_leaderboard_ui = LEADERBOARD_UI_SCENE.instantiate()
	add_child(_leaderboard_ui)
	
	# Connect closed signal
	if _leaderboard_ui.has_signal("closed"):
		_leaderboard_ui.closed.connect(_on_leaderboard_closed)


func _start_title_pulse() -> void:
	if not is_instance_valid(title_label):
		return
	if is_instance_valid(_title_tween):
		_title_tween.kill()
	title_label.pivot_offset = title_label.size * 0.5
	title_label.scale = Vector2.ONE
	_title_tween = create_tween()
	_title_tween.set_trans(Tween.TRANS_SINE)
	_title_tween.set_ease(Tween.EASE_IN_OUT)
	_title_tween.set_loops()
	_title_tween.tween_property(title_label, "scale", Vector2(1.08, 1.08), 0.8)
	_title_tween.tween_property(title_label, "scale", Vector2.ONE, 0.8)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_leaderboard_pressed() -> void:
	if _leaderboard_ui:
		_leaderboard_ui.show_leaderboard()


func _on_leaderboard_closed() -> void:
	# Leaderboard was closed, nothing special to do
	pass


func _on_quit_pressed() -> void:
	get_tree().quit()
