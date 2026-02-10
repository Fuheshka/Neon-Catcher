extends Node
## OnlineLeaderboard - Bridge between Game Logic and SilentWolf API
## Handles all online leaderboard operations with proper error handling

# Signals for cross-node communication
signal score_post_completed(success: bool, error_message: String)
signal leaderboard_received(scores: Array[Dictionary])
signal leaderboard_error(error_message: String)

# Constants
const DEFAULT_LEADERBOARD_NAME: String = "main"
const REQUEST_TIMEOUT_MS: int = 10000

# State tracking
var _is_posting: bool = false
var _is_fetching: bool = false


func _ready() -> void:
	# Verify SilentWolf is configured
	_check_configuration()


## Post a score to the online leaderboard
## @param player_name: The player's nickname (max 12 characters)
## @param score: The score value to submit
func post_score_online(player_name: String, score: int) -> void:
	if _is_posting:
		push_warning("Score post already in progress")
		return
	
	if not _check_configuration():
		score_post_completed.emit(false, "SilentWolf not configured properly")
		return
	
	if player_name.strip_edges().is_empty():
		push_error("Player name cannot be empty")
		score_post_completed.emit(false, "Invalid player name")
		return
	
	if score < 0:
		push_error("Score cannot be negative")
		score_post_completed.emit(false, "Invalid score value")
		return
	
	_is_posting = true
	
	# Sanitize player name
	var sanitized_name: String = player_name.strip_edges().substr(0, 12)
	
	# Call SilentWolf API
	print("Posting score to SilentWolf: ", sanitized_name, " - ", score)
	
	# Connect to signal before making request
	if not SilentWolf.Scores.sw_save_score_complete.is_connected(_on_score_posted):
		SilentWolf.Scores.sw_save_score_complete.connect(_on_score_posted)
	
	# Make the API call
	await SilentWolf.Scores.save_score(sanitized_name, score, DEFAULT_LEADERBOARD_NAME).sw_save_score_complete
	
	# Note: The callback _on_score_posted will handle the result


## Fetch top scores from the online leaderboard
## @param limit: Number of top scores to retrieve (default: 10)
func get_top_scores(limit: int = 10) -> void:
	if _is_fetching:
		push_warning("Leaderboard fetch already in progress")
		return
	
	if not _check_configuration():
		leaderboard_error.emit("SilentWolf not configured properly")
		return
	
	if limit <= 0:
		push_error("Limit must be positive")
		leaderboard_error.emit("Invalid limit value")
		return
	
	_is_fetching = true
	
	print("Fetching top ", limit, " scores from SilentWolf...")
	
	# Connect to signal before making request
	if not SilentWolf.Scores.sw_get_scores_complete.is_connected(_on_scores_received):
		SilentWolf.Scores.sw_get_scores_complete.connect(_on_scores_received)
	
	# Make the API call
	await SilentWolf.Scores.get_scores(limit, DEFAULT_LEADERBOARD_NAME).sw_get_scores_complete
	
	# Note: The callback _on_scores_received will handle the result


## Callback when score posting completes
func _on_score_posted(sw_result: Dictionary) -> void:
	_is_posting = false
	
	# Disconnect the signal
	if SilentWolf.Scores.sw_save_score_complete.is_connected(_on_score_posted):
		SilentWolf.Scores.sw_save_score_complete.disconnect(_on_score_posted)
	
	# Check if the request was successful
	if "success" in sw_result and sw_result["success"]:
		print("Score posted successfully! Score ID: ", sw_result.get("score_id", "unknown"))
		score_post_completed.emit(true, "")
	else:
		var error_msg: String = sw_result.get("error", "Unknown error")
		push_error("Failed to post score: " + error_msg)
		score_post_completed.emit(false, error_msg)


## Callback when leaderboard scores are received
func _on_scores_received(sw_result: Dictionary) -> void:
	_is_fetching = false
	
	# Disconnect the signal
	if SilentWolf.Scores.sw_get_scores_complete.is_connected(_on_scores_received):
		SilentWolf.Scores.sw_get_scores_complete.disconnect(_on_scores_received)
	
	# Check if the request was successful
	if "success" in sw_result and sw_result["success"]:
		var scores: Array = sw_result.get("scores", [])
		print("Leaderboard received: ", scores.size(), " scores")
		
		# Convert the scores to a typed array of dictionaries
		var typed_scores: Array[Dictionary] = []
		for score_entry in scores:
			if score_entry is Dictionary:
				typed_scores.append(score_entry)
		
		leaderboard_received.emit(typed_scores)
	else:
		var error_msg: String = sw_result.get("error", "Unknown error")
		push_error("Failed to fetch leaderboard: " + error_msg)
		leaderboard_error.emit(error_msg)


## Verify that SilentWolf is properly configured
func _check_configuration() -> bool:
	if not SilentWolf:
		push_error("SilentWolf autoload not found! Make sure it's enabled in project settings.")
		return false
	
	var api_key: String = SilentWolf.config.get("api_key", "")
	var game_id: String = SilentWolf.config.get("game_id", "")
	
	if api_key.is_empty() or api_key == "YOURAPIKEY" or api_key == "FmKF4gtm0Z2RbUAEU62kZ2OZoYLj4PYOURAPIKEY":
		push_error("SilentWolf API Key not configured! Please set your API key.")
		return false
	
	if game_id.is_empty() or game_id == "YOURGAMEID":
		push_error("SilentWolf Game ID not configured! Please set your Game ID.")
		return false
	
	return true


## Check if the game is running on web platform
func is_web_platform() -> bool:
	return OS.has_feature("web")
