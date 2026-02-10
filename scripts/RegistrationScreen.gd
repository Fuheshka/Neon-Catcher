extends Control
## RegistrationScreen - UI for entering nickname after achieving a high score

@onready var nickname_input: LineEdit = $Panel/VBoxContainer/NicknameInput
@onready var confirm_button: Button = $Panel/VBoxContainer/ConfirmButton
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var score_label: Label = $Panel/VBoxContainer/ScoreLabel
@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel

var current_score: int = 0
var online_leaderboard: Node = null

signal nickname_submitted(success: bool)


func _ready() -> void:
	hide()
	
	# Setup OnlineLeaderboard
	_setup_online_leaderboard()
	
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_pressed)
	
	if nickname_input:
		nickname_input.text_submitted.connect(_on_text_submitted)
		nickname_input.max_length = 12
	
	if status_label:
		status_label.text = ""
		status_label.hide()


func show_screen(score: int) -> void:
	current_score = score
	if score_label:
		score_label.text = "Your Score: " + str(score)
	
	if nickname_input:
		nickname_input.text = ""
		nickname_input.grab_focus()
	
	show()


func _on_confirm_pressed() -> void:
	_submit_score()


func _on_text_submitted(_text: String) -> void:
	_submit_score()


func _submit_score() -> void:
	if not nickname_input:
		return
	
	var nickname: String = nickname_input.text.strip_edges()
	
	# Validate nickname
	if nickname.is_empty():
		nickname = "Anonymous"
	
	# Disable input during submission
	_set_ui_loading(true)
	_show_status("Submitting score...", Color.YELLOW)
	
	# Add to local leaderboard (backup)
	var leaderboard_mgr = get_node_or_null("/root/LeaderboardManager")
	if leaderboard_mgr:
		leaderboard_mgr.add_score(nickname, current_score)
	
	# Post to online leaderboard
	if online_leaderboard:
		online_leaderboard.post_score_online(nickname, current_score)
	else:
		# Fallback if OnlineLeaderboard is not available
		push_warning("OnlineLeaderboard not available, using local only")
		_on_score_submission_complete(false, "Online service unavailable")


## Callback when online score submission completes
func _on_score_submission_complete(success: bool, error_message: String) -> void:
	_set_ui_loading(false)
	
	if success:
		_show_status("Score submitted successfully!", Color.GREEN)
		await get_tree().create_timer(1.5).timeout
		
		# Emit signal to notify parent
		nickname_submitted.emit(true)
		
		# Hide this screen
		hide()
	else:
		# Show error but don't block the flow
		_show_status("Network error - saved locally", Color.ORANGE)
		push_warning("Failed to submit online score: " + error_message)
		
		# Still allow progression after a delay
		await get_tree().create_timer(2.0).timeout
		nickname_submitted.emit(false)
		hide()


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
			online_leaderboard.score_post_completed.connect(_on_score_submission_complete)
		else:
			push_error("Failed to load OnlineLeaderboard.gd script")


## Set UI to loading state
func _set_ui_loading(is_loading: bool) -> void:
	if confirm_button:
		confirm_button.disabled = is_loading
		confirm_button.text = "Submitting..." if is_loading else "Confirm"
	
	if nickname_input:
		nickname_input.editable = not is_loading


## Display status message to user
func _show_status(message: String, color: Color) -> void:
	if status_label:
		status_label.text = message
		status_label.modulate = color
		status_label.show()
