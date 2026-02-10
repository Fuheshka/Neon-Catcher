extends Node
## OnlineLeaderboard - Consolidated SilentWolf leaderboard manager with timeout protection
## Handles initialization, API calls with timeouts, and robust error handling

# Signals
signal leaderboard_received(scores: Array[Dictionary])
signal leaderboard_error(error_message: String)
signal score_posted(success: bool, error_message: String)
signal request_timeout()

# Constants
const REQUEST_TIMEOUT_SEC: float = 10.0
const DEFAULT_LEADERBOARD_NAME: String = "main"
const MAX_SCORES: int = 10

# State
var _is_initialized: bool = false
var _is_busy: bool = false
var _sw_api_key: String = ""
var _sw_game_id: String = ""


func _ready() -> void:
	_log_to_console("OnlineLeaderboard initializing...")
	await get_tree().process_frame  # Wait one frame for other autoloads
	_initialize_silentwolf()


## Initialize SilentWolf with Config credentials
func _initialize_silentwolf() -> void:
	_log_to_console("Step 1: Checking Config autoload...")
	
	# Verify Config exists
	var config_node = get_node_or_null("/root/Config")
	if not config_node:
		_log_error("Config autoload not found!")
		return
	
	_log_to_console("Step 2: Reading credentials from Config...")
	
	# Get credentials from Config
	_sw_api_key = config_node.SW_API_KEY if "SW_API_KEY" in config_node else ""
	_sw_game_id = config_node.SW_GAME_ID if "SW_GAME_ID" in config_node else ""
	
	# Validate credentials
	if _sw_api_key.is_empty() or _sw_game_id.is_empty():
		_log_error("SilentWolf credentials are empty!")
		return
	
	if _sw_api_key == "SW_API_KEY_PLACEHOLDER" or _sw_game_id == "SW_GAME_ID_PLACEHOLDER":
		_log_warning("⚠️ Running with PLACEHOLDER keys! This will fail in production.")
	
	_log_to_console("Step 3: Configuring SilentWolf...")
	
	# Verify SilentWolf plugin is loaded
	if not SilentWolf:
		_log_error("SilentWolf plugin not loaded! Check addons/silent_wolf is enabled.")
		return
	
	# Configure SilentWolf
	SilentWolf.configure({
		"api_key": _sw_api_key,
		"game_id": _sw_game_id,
		"log_level": 1  # Info level
	})
	
	# Extra logging for web builds
	if OS.has_feature("web"):
		SilentWolf.log_level = 1
		_log_to_console("Running in WEB mode - verbose logging enabled")
	
	_is_initialized = true
	_log_to_console("✓ SilentWolf initialized successfully!")
	_log_to_console("  Game ID: " + _sw_game_id)
	_log_to_console("  API Key: " + _sw_api_key.substr(0, 8) + "...")


## Fetch top scores with timeout protection
func get_high_scores(limit: int = MAX_SCORES) -> void:
	if _is_busy:
		_log_warning("Request already in progress, please wait...")
		return
	
	if not _is_initialized:
		_log_error("SilentWolf not initialized!")
		leaderboard_error.emit("Not initialized")
		return
	
	_is_busy = true
	_log_to_console("=== REQUEST STARTED: get_scores (limit=" + str(limit) + ") ===")
	
	# Create timeout timer
	var timeout_timer = get_tree().create_timer(REQUEST_TIMEOUT_SEC)
	var timeout_state = {"occurred": false}  # Use dict to allow modification in lambda
	
	# Connect timeout signal
	var on_timeout = func():
		if _is_busy:
			timeout_state["occurred"] = true
			_is_busy = false
			_log_error("⏱️ REQUEST TIMED OUT after " + str(REQUEST_TIMEOUT_SEC) + " seconds")
			request_timeout.emit()
			leaderboard_error.emit("Request timed out")
	
	timeout_timer.timeout.connect(on_timeout)
	
	# Start SilentWolf request
	_log_to_console("Sending request to SilentWolf API...")
	var sw_result: Dictionary = await SilentWolf.Scores.get_scores(limit).sw_get_scores_complete
	
	# If timeout already occurred, ignore the late response
	if timeout_state["occurred"]:
		_log_warning("Ignoring late response (timeout already fired)")
		return
	
	# Cancel timeout timer
	if timeout_timer:
		timeout_timer.timeout.disconnect(on_timeout)
	
	_is_busy = false
	
	# Process result
	_log_to_console("Signal received: sw_get_scores_complete")
	_log_to_console("Result: " + str(sw_result))
	
	if sw_result.get("success", false):
		var scores: Array = sw_result.get("scores", [])
		_log_to_console("✓ SUCCESS: Received " + str(scores.size()) + " scores")
		
		# Convert to typed array
		var typed_scores: Array[Dictionary] = []
		for score_entry in scores:
			if score_entry is Dictionary:
				typed_scores.append(score_entry)
		
		leaderboard_received.emit(typed_scores)
	else:
		var error_msg: String = sw_result.get("error", "Unknown error")
		_log_error("✗ FAILED: " + error_msg)
		leaderboard_error.emit(error_msg)
	
	_log_to_console("=== REQUEST COMPLETED ===")


## Delete old scores for the same player (by player_id)
func _delete_old_player_scores(player_name: String, player_id: String) -> void:
	_log_to_console("Fetching existing scores for player: " + player_name)
	
	# Get all scores for this player
	var scores_result: Dictionary = await SilentWolf.Scores.get_scores_by_player(
		player_name,
		100,  # Get up to 100 scores to check
		DEFAULT_LEADERBOARD_NAME
	).sw_get_player_scores_complete
	
	if not scores_result.get("success", false):
		_log_warning("Could not fetch player scores for cleanup: " + scores_result.get("error", "Unknown"))
		return
	
	var player_scores: Array = scores_result.get("scores", [])
	_log_to_console("Found " + str(player_scores.size()) + " existing scores")
	
	# Find and delete scores with matching player_id
	var deleted_count: int = 0
	for score_entry in player_scores:
		if score_entry is Dictionary:
			var metadata = score_entry.get("metadata", {})
			if metadata is Dictionary and metadata.get("player_id", "") == player_id:
				var old_score_id: String = score_entry.get("score_id", "")
				if not old_score_id.is_empty():
					_log_to_console("Deleting old score: " + old_score_id)
					# Delete the old score (no need to await, fire and forget)
					var delete_result = await SilentWolf.Scores.delete_score(
						old_score_id,
						DEFAULT_LEADERBOARD_NAME
					).sw_delete_score_complete
					
					if delete_result.get("success", false):
						deleted_count += 1
						_log_to_console("  ✓ Deleted successfully")
					else:
						_log_warning("  ✗ Delete failed: " + delete_result.get("error", "Unknown"))
	
	if deleted_count > 0:
		_log_to_console("✓ Deleted " + str(deleted_count) + " old score(s)")
	else:
		_log_to_console("No old scores to delete")


## Post score with timeout protection
func post_score(player_name: String, score: int, player_id: String = "") -> void:
	if _is_busy:
		_log_warning("Request already in progress, please wait...")
		score_posted.emit(false, "Busy")
		return
	
	if not _is_initialized:
		_log_error("SilentWolf not initialized!")
		score_posted.emit(false, "Not initialized")
		return
	
	if player_name.strip_edges().is_empty():
		_log_error("Player name cannot be empty!")
		score_posted.emit(false, "Empty name")
		return
	
	_is_busy = true
	var sanitized_name: String = player_name.strip_edges().substr(0, 12)
	
	_log_to_console("=== REQUEST STARTED: save_score ===")
	_log_to_console("  Player: " + sanitized_name)
	_log_to_console("  Score: " + str(score))
	if not player_id.is_empty():
		_log_to_console("  Player ID: " + player_id.substr(0, 16) + "...")
	
	# STEP 1: Delete old scores for this player (if player_id provided)
	if not player_id.is_empty():
		_log_to_console("Checking for old scores to delete...")
		await _delete_old_player_scores(sanitized_name, player_id)
	
	# STEP 2: Create timeout timer for saving new score
	var timeout_timer = get_tree().create_timer(REQUEST_TIMEOUT_SEC)
	var timeout_state = {"occurred": false}  # Use dict to allow modification in lambda
	
	# Connect timeout signal
	var on_timeout = func():
		if _is_busy:
			timeout_state["occurred"] = true
			_is_busy = false
			_log_error("⏱️ REQUEST TIMED OUT after " + str(REQUEST_TIMEOUT_SEC) + " seconds")
			request_timeout.emit()
			score_posted.emit(false, "Request timed out")
	
	timeout_timer.timeout.connect(on_timeout)
	
	# Prepare metadata with player_id for unique identification
	var metadata: Dictionary = {
		"timestamp": Time.get_unix_time_from_system(),
		"platform": OS.get_name()
	}
	
	if not player_id.is_empty():
		metadata["player_id"] = player_id
	
	# STEP 3: Start SilentWolf request to save new score
	_log_to_console("Sending request to SilentWolf API...")
	var sw_result: Dictionary = await SilentWolf.Scores.save_score(
		sanitized_name,
		score,
		DEFAULT_LEADERBOARD_NAME,
		metadata
	).sw_save_score_complete
	
	# If timeout already occurred, ignore the late response
	if timeout_state["occurred"]:
		_log_warning("Ignoring late response (timeout already fired)")
		return
	
	# Cancel timeout timer
	if timeout_timer:
		timeout_timer.timeout.disconnect(on_timeout)
	
	_is_busy = false
	
	# Process result
	_log_to_console("Signal received: sw_save_score_complete")
	_log_to_console("Result: " + str(sw_result))
	
	if sw_result.get("success", false):
		var score_id: String = sw_result.get("score_id", "unknown")
		_log_to_console("✓ SUCCESS: Score posted (ID: " + score_id + ")")
		score_posted.emit(true, "")
	else:
		var error_msg: String = sw_result.get("error", "Unknown error")
		_log_error("✗ FAILED: " + error_msg)
		score_posted.emit(false, error_msg)
	
	_log_to_console("=== REQUEST COMPLETED ===")


## Check if the system is ready
func is_ready() -> bool:
	return _is_initialized


## Check if a request is in progress
func is_busy() -> bool:
	return _is_busy


## Log to browser console (web builds)
func _log_to_console(message: String) -> void:
	print("[OnlineLeaderboard] " + message)
	
	if OS.has_feature("web"):
		var escaped_msg: String = message.replace("'", "\\'").replace("\n", "\\n")
		JavaScriptBridge.eval("console.log('[OnlineLeaderboard] " + escaped_msg + "');")


## Log warning to browser console
func _log_warning(message: String) -> void:
	push_warning("[OnlineLeaderboard] " + message)
	
	if OS.has_feature("web"):
		var escaped_msg: String = message.replace("'", "\\'").replace("\n", "\\n")
		JavaScriptBridge.eval("console.warn('[OnlineLeaderboard] " + escaped_msg + "');")


## Log error to browser console
func _log_error(message: String) -> void:
	push_error("[OnlineLeaderboard] " + message)
	
	if OS.has_feature("web"):
		var escaped_msg: String = message.replace("'", "\\'").replace("\n", "\\n")
		JavaScriptBridge.eval("console.error('[OnlineLeaderboard] " + escaped_msg + "');")
