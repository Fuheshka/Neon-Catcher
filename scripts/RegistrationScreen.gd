extends Control
## RegistrationScreen - UI for entering nickname after achieving a high score

const PLAYER_PROFILE_FILE: String = "user://player_profile.json"

@onready var nickname_input: LineEdit = $Panel/VBoxContainer/NicknameInput
@onready var confirm_button: Button = $Panel/VBoxContainer/ConfirmButton
@onready var tap_to_type_button: Button = $Panel/VBoxContainer/TapToTypeButton
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var score_label: Label = $Panel/VBoxContainer/ScoreLabel
@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel

var current_score: int = 0
var saved_nickname: String = ""
var player_id: String = ""  # Unique player identifier

signal nickname_submitted(success: bool)


func _ready() -> void:
	hide()
	
	# Load saved player profile
	_load_player_profile()
	
	# Connect to OnlineLeaderboard autoload signals
	var online_leaderboard = get_node_or_null("/root/OnlineLeaderboard")
	if online_leaderboard:
		online_leaderboard.score_posted.connect(_on_score_submission_complete)
	else:
		push_error("[RegistrationScreen] OnlineLeaderboard autoload not found!")
	
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_pressed)
	
	if tap_to_type_button:
		tap_to_type_button.pressed.connect(_on_tap_to_type_pressed)
		# Show "Tap to Type" button only on web builds
		if OS.has_feature("web"):
			tap_to_type_button.show()
		else:
			tap_to_type_button.hide()
	
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
		# Auto-fill with saved nickname if exists
		if not saved_nickname.is_empty():
			nickname_input.text = saved_nickname
			nickname_input.select_all()
			if title_label:
				title_label.text = "New High Score!"
		else:
			nickname_input.text = ""
			if title_label:
				title_label.text = "Enter Your Nickname"
		
		# Try to grab focus for native keyboard (may not work on mobile web)
		nickname_input.grab_focus()
		# Small delay to ensure UI is visible before focusing
		await get_tree().create_timer(0.1).timeout
		nickname_input.grab_focus()
	
	show()


func _on_confirm_pressed() -> void:
	_submit_score()


func _on_text_submitted(_text: String) -> void:
	_submit_score()


## Handle "Tap to Type" button press (web-specific)
func _on_tap_to_type_pressed() -> void:
	if OS.has_feature("web"):
		_prompt_nickname_web()
	else:
		# Fallback for non-web builds (shouldn't happen as button is hidden)
		if nickname_input:
			nickname_input.grab_focus()


## Use JavaScript prompt for reliable mobile web input
func _prompt_nickname_web() -> void:
	if not OS.has_feature("web"):
		return
	
	var default_value = saved_nickname if not saved_nickname.is_empty() else ""
	
	# Use JavaScriptBridge to call native browser prompt
	var js_code = "prompt('Enter your nickname (max 12 characters):', '%s')" % default_value
	var result = JavaScriptBridge.eval(js_code)
	
	if result != null and result != "":
		# Limit to 12 characters and clean up
		var nickname = str(result).strip_edges().substr(0, 12)
		
		if not nickname.is_empty():
			if nickname_input:
				nickname_input.text = nickname
			print("✓ Nickname entered via web prompt: ", nickname)
			# Auto-submit after web input
			_submit_score()
		else:
			print("⚠ Empty nickname from web prompt")
	else:
		print("⚠ User cancelled web prompt")


func _submit_score() -> void:
	if not nickname_input:
		return
	
	var nickname: String = nickname_input.text.strip_edges()
	
	# Validate nickname
	if nickname.is_empty():
		# On web, prompt user instead of defaulting to Anonymous
		if OS.has_feature("web"):
			_show_status("Please enter a nickname!", Color.ORANGE)
			_prompt_nickname_web()
			return
		else:
			nickname = "Anonymous"
	
	# Ensure nickname is limited to 12 characters
	nickname = nickname.substr(0, 12)
	
	# Save nickname for future use
	_save_player_profile(nickname)
	
	# Disable input during submission
	_set_ui_loading(true)
	_show_status("Submitting score...", Color.YELLOW)
	
	# Add to local leaderboard (will update if same player)
	var leaderboard_mgr = get_node_or_null("/root/LeaderboardManager")
	if leaderboard_mgr:
		leaderboard_mgr.add_or_update_score(nickname, current_score, player_id)
	
	# Post to online leaderboard
	var online_leaderboard = get_node_or_null("/root/OnlineLeaderboard")
	if online_leaderboard:
		online_leaderboard.post_score(nickname, current_score, player_id)
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


## Load saved player profile
func _load_player_profile() -> void:
	if not FileAccess.file_exists(PLAYER_PROFILE_FILE):
		# Generate new player ID for first-time player
		player_id = _generate_player_id()
		print("✨ New player ID generated: ", player_id)
		return
	
	var file = FileAccess.open(PLAYER_PROFILE_FILE, FileAccess.READ)
	if file == null:
		player_id = _generate_player_id()
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error == OK and json.data is Dictionary:
		var data = json.data
		saved_nickname = data.get("nickname", "")
		player_id = data.get("player_id", "")
		
		# Generate player_id if missing (for old profiles)
		if player_id.is_empty():
			player_id = _generate_player_id()
			print("🔄 Upgrading old profile with player_id: ", player_id)
			_save_player_profile(saved_nickname)  # Re-save with player_id
		else:
			print("✓ Loaded player profile: ", saved_nickname, " (ID: ", player_id.substr(0, 8), "...)")
	else:
		player_id = _generate_player_id()


## Save player profile for future use
func _save_player_profile(nickname: String) -> void:
	var profile = {
		"nickname": nickname,
		"player_id": player_id,
		"last_updated": Time.get_unix_time_from_system()
	}
	
	var file = FileAccess.open(PLAYER_PROFILE_FILE, FileAccess.WRITE)
	if file == null:
		push_error("Failed to save player profile: " + str(FileAccess.get_open_error()))
		return
	
	var json_string = JSON.stringify(profile, "\t")
	file.store_string(json_string)
	file.close()
	
	saved_nickname = nickname
	print("✓ Saved player profile: ", nickname, " (ID: ", player_id.substr(0, 8), "...)")


## Generate a unique player ID
func _generate_player_id() -> String:
	# Generate UUID-like identifier
	var timestamp = Time.get_unix_time_from_system()
	var random_bytes = []
	
	for i in range(16):
		random_bytes.append(randi() % 256)
	
	# Format as hex string
	var hex_chars = "0123456789abcdef"
	var result = ""
	
	for byte in random_bytes:
		result += hex_chars[byte >> 4]
		result += hex_chars[byte & 0xF]
	
	return str(timestamp) + "-" + result
