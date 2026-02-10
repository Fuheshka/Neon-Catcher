extends Control
## LeaderboardUI - Display the top 10 scores

@onready var leaderboard_container: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/LeaderboardContainer
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel

const LEADERBOARD_ROW = preload("res://scenes/LeaderboardRow.tscn")

var online_leaderboard: Node = null

signal closed()


func _ready() -> void:
	hide()
	
	# Setup OnlineLeaderboard
	_setup_online_leaderboard()
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	if status_label:
		status_label.text = ""
		status_label.hide()
	
	# Listen for leaderboard updates (local fallback)
	var leaderboard_mgr = get_node_or_null("/root/LeaderboardManager")
	if leaderboard_mgr:
		leaderboard_mgr.leaderboard_updated.connect(_on_local_leaderboard_updated)


func show_leaderboard() -> void:
	show()
	refresh_leaderboard()


func refresh_leaderboard() -> void:
	# Clear existing rows
	_clear_leaderboard()
	
	# Show connecting state
	_show_status("⚡ CONNECTING TO CYBER-NET...", Color.CYAN)
	
	# Fetch online scores
	if online_leaderboard:
		online_leaderboard.get_top_scores(10)
	else:
		# Fallback to local leaderboard
		push_warning("[LeaderboardUI] OnlineLeaderboard not available, using local leaderboard")
		_show_status("⚠ OFFLINE - SHOWING LOCAL SCORES", Color.ORANGE)
		_display_local_leaderboard()


## Display leaderboard scores on the UI
func _display_scores(scores: Array[Dictionary]) -> void:
	_clear_leaderboard()
	
	if scores.is_empty():
		_show_empty_message()
		_show_status("No scores yet!", Color.GRAY)
		return
	
	# Hide status when scores are displayed
	if status_label:
		status_label.hide()
	
	# Create rows for each entry
	for i in range(scores.size()):
		var entry: Dictionary = scores[i]
		var row = LEADERBOARD_ROW.instantiate()
		leaderboard_container.add_child(row)
		
		# Set row data - SilentWolf uses different field names
		var rank_label = row.get_node("RankLabel")
		var name_label = row.get_node("NameLabel")
		var score_label = row.get_node("ScoreLabel")
		
		if rank_label:
			rank_label.text = str(i + 1) + "."
		if name_label:
			# SilentWolf uses "player_name" instead of "name"
			var player_name: String = entry.get("player_name", entry.get("name", "Unknown"))
			name_label.text = player_name
		if score_label:
			# SilentWolf stores score as various types
			var score_value = entry.get("score", 0)
			score_label.text = str(score_value)


## Display local leaderboard as fallback
func _display_local_leaderboard() -> void:
	var leaderboard_mgr = get_node_or_null("/root/LeaderboardManager")
	if not leaderboard_mgr:
		push_error("[LeaderboardUI] LeaderboardManager autoload not found")
		return
	
	var leaderboard: Array[Dictionary] = leaderboard_mgr.get_leaderboard()
	_display_scores(leaderboard)
	# Note: Status label is set by caller (_on_leaderboard_error)


## Callback when online leaderboard is received
func _on_leaderboard_received(scores: Array[Dictionary]) -> void:
	print("[LeaderboardUI] ✓ Received ", scores.size(), " scores from online leaderboard")
	
	# Hide status on success - scores speak for themselves
	if status_label:
		status_label.hide()
	
	_display_scores(scores)


## Callback when online leaderboard fetch fails
func _on_leaderboard_error(error_message: String) -> void:
	push_warning("[LeaderboardUI] Failed to fetch online leaderboard: " + error_message)
	_show_status("⚠ CONNECTION FAILED - SHOWING LOCAL SCORES", Color.ORANGE)
	
	# Only fallback to local when network actually fails
	_display_local_leaderboard()


## Callback when local leaderboard updates (fallback)
func _on_local_leaderboard_updated() -> void:
	# Only update if we're showing the UI and using local fallback
	if visible and not online_leaderboard:
		_display_local_leaderboard()


## Setup the OnlineLeaderboard node
func _setup_online_leaderboard() -> void:
	# Create OnlineLeaderboard instance if not exists
	if not online_leaderboard:
		var OnlineLeaderboardScript = load("res://scripts/OnlineLeaderboard.gd")
		if OnlineLeaderboardScript:
			online_leaderboard = Node.new()
			online_leaderboard.set_script(OnlineLeaderboardScript)
			online_leaderboard.name = "OnlineLeaderboard"
			add_child(online_leaderboard)
			
			# Connect signals
			online_leaderboard.leaderboard_received.connect(_on_leaderboard_received)
			online_leaderboard.leaderboard_error.connect(_on_leaderboard_error)
		else:
			push_error("Failed to load OnlineLeaderboard.gd script")


## Clear all leaderboard rows
func _clear_leaderboard() -> void:
	if leaderboard_container:
		for child in leaderboard_container.get_children():
			child.queue_free()


## Show empty leaderboard message
func _show_empty_message() -> void:
	var empty_label = Label.new()
	empty_label.text = "No scores yet! Be the first!"
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	leaderboard_container.add_child(empty_label)


## Display status message to user
func _show_status(message: String, color: Color) -> void:
	if status_label:
		status_label.text = message
		status_label.modulate = color
		status_label.show()


func _on_close_pressed() -> void:
	closed.emit()
	hide()
