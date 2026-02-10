extends Control
class_name GameOverScreen

"""Shows a Game Over overlay and handles restart/quit actions."""

@export var restart_button: Button
@export var quit_button: Button
@export var leaderboard_button: Button
@onready var _events: Node = get_node("/root/Events")

var _registration_screen: Control
var _leaderboard_ui: Control
var _game_manager: GameManager


func _ready() -> void:
	visible = false
	_events.connect("game_over", _on_game_over)
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	if leaderboard_button:
		leaderboard_button.pressed.connect(_on_leaderboard_button_pressed)
	
	# Get references to the new screens
	call_deferred("_setup_leaderboard_references")


func _setup_leaderboard_references() -> void:
	# Get registration screen and leaderboard UI from parent (UI CanvasLayer)
	var parent = get_parent()
	if parent:
		_registration_screen = parent.get_node_or_null("RegistrationScreen")
		_leaderboard_ui = parent.get_node_or_null("LeaderboardUI")
		
		# Connect signals
		if _registration_screen and _registration_screen.has_signal("nickname_submitted"):
			_registration_screen.nickname_submitted.connect(_on_nickname_submitted)
		
		if _leaderboard_ui and _leaderboard_ui.has_signal("closed"):
			_leaderboard_ui.closed.connect(_on_leaderboard_closed)
	
	# Get game manager reference
	_game_manager = get_node_or_null("/root/Main/GameManager")


func _on_game_over() -> void:
	# Check if this is a high score
	var current_score = 0
	if _game_manager:
		current_score = _game_manager.score
	
	var leaderboard_mgr = get_node_or_null("/root/LeaderboardManager")
	if leaderboard_mgr and leaderboard_mgr.is_high_score(current_score):
		# Show registration screen for high score
		if _registration_screen:
			_registration_screen.show_screen(current_score)
			get_tree().paused = true
	else:
		# Show regular game over screen
		visible = true
		get_tree().paused = true


func _on_nickname_submitted(success: bool) -> void:
	# After nickname is submitted, show the leaderboard
	if _leaderboard_ui:
		_leaderboard_ui.show_leaderboard()


func _on_leaderboard_closed() -> void:
	# After leaderboard is closed, show the regular game over screen
	visible = true


func _on_leaderboard_button_pressed() -> void:
	# Show the leaderboard when button is pressed
	if _leaderboard_ui:
		visible = false
		_leaderboard_ui.show_leaderboard()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	# Grab tree once to avoid null after scene switch.
	var tree := get_tree()
	if tree == null:
		return
	tree.paused = false
	tree.change_scene_to_file("res://scenes/main_menu.tscn")
