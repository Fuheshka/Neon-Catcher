extends Node
## OnlineLeaderboard - Bridge between Game Logic and SilentWolf API
## Handles all online leaderboard operations with proper error handling

# Signals for cross-node communication
signal score_post_completed(success: bool, error_message: String)
signal score_synced_globally()
signal leaderboard_received(scores: Array[Dictionary])
signal leaderboard_error(error_message: String)

# Constants
const DEFAULT_LEADERBOARD_NAME: String = "main"
const REQUEST_TIMEOUT_MS: int = 10000

# State tracking
var _is_posting: bool = false
var _is_fetching: bool = false

# Reference to SilentWolfManager
var _sw_manager: Node = null


func _ready() -> void:
	# Get SilentWolfManager reference
	_sw_manager = get_node_or_null("/root/SilentWolfManager")
	
	# Wait for SilentWolf to be ready
	if _sw_manager:
		if not _sw_manager.is_ready():
			print("[OnlineLeaderboard] Waiting for SilentWolfManager...")
			await _sw_manager.sw_initialized
	
	# Verify SilentWolf is configured
	_check_configuration()


## Post a score to the online leaderboard
## @param player_name: The player's nickname (max 12 characters)
## @param score: The score value to submit
## @param player_id: Unique player identifier for preventing conflicts
func post_score_online(player_name: String, score: int, player_id: String = "") -> void:
	if _is_posting:
		push_warning("[OnlineLeaderboard] Score post already in progress")
		return
	
	if not _check_configuration():
		var error: String = "SilentWolf not configured properly"
		_log_error(error)
		score_post_completed.emit(false, error)
		return
	
	if player_name.strip_edges().is_empty():
		var error: String = "Player name cannot be empty"
		push_error("[OnlineLeaderboard] " + error)
		_log_error(error)
		score_post_completed.emit(false, error)
		return
	
	if score < 0:
		var error: String = "Score cannot be negative"
		push_error("[OnlineLeaderboard] " + error)
		_log_error(error)
		score_post_completed.emit(false, error)
		return
	
	_is_posting = true
	
	# Sanitize player name
	var sanitized_name: String = player_name.strip_edges().substr(0, 12)
	
	# Prepare metadata with player_id for identification
	var metadata: Dictionary = {
		"timestamp": Time.get_unix_time_from_system(),
		"platform": OS.get_name()
	}
	
	if not player_id.is_empty():
		metadata["player_id"] = player_id
	
	# Log attempt
	var log_msg: String = "Posting score: " + sanitized_name + " - " + str(score)
	print("[OnlineLeaderboard] ", log_msg)
	_log_info(log_msg)
	
	# Use the correct API: post_score with await
	var sw_result: Dictionary = await SilentWolf.Scores.post_score(
		sanitized_name, 
		score, 
		DEFAULT_LEADERBOARD_NAME
	).sw_post_score_complete
	
	# Process result
	_is_posting = false
	_handle_score_post_result(sw_result, sanitized_name, score)


## Fetch top scores from the online leaderboard
## @param limit: Number of top scores to retrieve (default: 10)
func get_top_scores(limit: int = 10) -> void:
	if _is_fetching:
		push_warning("[OnlineLeaderboard] Leaderboard fetch already in progress")
		return
	
	if not _check_configuration():
		var error: String = "SilentWolf not configured properly"
		_log_error(error)
		leaderboard_error.emit(error)
		return
	
	if limit <= 0:
		var error: String = "Limit must be positive"
		push_error("[OnlineLeaderboard] " + error)
		_log_error(error)
		leaderboard_error.emit(error)
		return
	
	_is_fetching = true
	
	var log_msg: String = "Fetching top " + str(limit) + " scores..."
	print("[OnlineLeaderboard] ", log_msg)
	_log_info(log_msg)
	
	# Use the correct API: get_high_scores with await
	var sw_result: Dictionary = await SilentWolf.Scores.get_high_scores(limit).sw_get_scores_complete
	
	# Process result
	_is_fetching = false
	_handle_scores_fetch_result(sw_result)


## Handle the result of score posting
func _handle_score_post_result(sw_result: Dictionary, player_name: String, score: int) -> void:
	# Log the raw result for debugging
	print("[OnlineLeaderboard] Score post result: ", sw_result)
	
	# Check if the request was successful
	if sw_result.get("success", false):
		var score_id: String = sw_result.get("score_id", "unknown")
		var success_msg: String = "✓ Score posted! Player: " + player_name + ", Score: " + str(score) + ", ID: " + score_id
		print("[OnlineLeaderboard] ", success_msg)
		_log_info(success_msg)
		
		score_synced_globally.emit()
		score_post_completed.emit(true, "")
	else:
		# Extract error information
		var error_msg: String = sw_result.get("error", "Unknown error")
		var http_status: int = sw_result.get("http_status", 0)
		
		var full_error: String = "Failed to post score: " + error_msg
		if http_status > 0:
			full_error += " (HTTP " + str(http_status) + ")"
		
		push_error("[OnlineLeaderboard] " + full_error)
		_log_error(full_error)
		
		# Log additional details if available
		if "error_details" in sw_result:
			_log_error("Details: " + str(sw_result["error_details"]))
		
		score_post_completed.emit(false, error_msg)


## Handle the result of leaderboard fetching
func _handle_scores_fetch_result(sw_result: Dictionary) -> void:
	# Log the raw result for debugging
	print("[OnlineLeaderboard] Leaderboard fetch result: ", sw_result)
	
	# Check if the request was successful
	if sw_result.get("success", false):
		var scores: Array = sw_result.get("scores", [])
		var success_msg: String = "✓ Leaderboard received: " + str(scores.size()) + " scores"
		print("[OnlineLeaderboard] ", success_msg)
		_log_info(success_msg)
		
		# Convert the scores to a typed array of dictionaries
		var typed_scores: Array[Dictionary] = []
		for score_entry in scores:
			if score_entry is Dictionary:
				typed_scores.append(score_entry)
		
		leaderboard_received.emit(typed_scores)
	else:
		# Extract error information
		var error_msg: String = sw_result.get("error", "Unknown error")
		var http_status: int = sw_result.get("http_status", 0)
		
		var full_error: String = "Failed to fetch leaderboard: " + error_msg
		if http_status > 0:
			full_error += " (HTTP " + str(http_status) + ")"
		
		push_error("[OnlineLeaderboard] " + full_error)
		_log_error(full_error)
		
		leaderboard_error.emit(error_msg)


## Verify that SilentWolf is properly configured
func _check_configuration() -> bool:
	if not SilentWolf:
		push_error("[OnlineLeaderboard] SilentWolf autoload not found!")
		return false
	
	# Check if SilentWolfManager is ready
	if _sw_manager and not _sw_manager.is_ready():
		push_error("[OnlineLeaderboard] SilentWolfManager not ready!")
		return false
	
	var api_key: String = SilentWolf.config.get("api_key", "")
	var game_id: String = SilentWolf.config.get("game_id", "")
	
	if api_key.is_empty() or game_id.is_empty():
		push_error("[OnlineLeaderboard] SilentWolf credentials not configured!")
		return false
	
	return true


## Check if the game is running on web platform
func is_web_platform() -> bool:
	return OS.has_feature("web")


## Log info message to browser console (web builds only)
func _log_info(message: String) -> void:
	if not is_web_platform():
		return
	
	if _sw_manager and _sw_manager.has_method("log_to_console"):
		_sw_manager.log_to_console(message)
	else:
		JavaScriptBridge.eval("console.log('[OnlineLeaderboard] " + message.replace("'", "\\'") + "');")


## Log error message to browser console (web builds only)
func _log_error(message: String) -> void:
	if not is_web_platform():
		return
	
	if _sw_manager and _sw_manager.has_method("log_error_to_console"):
		_sw_manager.log_error_to_console(message)
	else:
		JavaScriptBridge.eval("console.error('[OnlineLeaderboard] " + message.replace("'", "\\'") + "');")

