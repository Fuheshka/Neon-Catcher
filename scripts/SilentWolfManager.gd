extends Node
## SilentWolfManager - Robust initialization and validation for SilentWolf API
## Ensures SilentWolf is properly configured before any API calls are made

signal sw_initialized(success: bool)
signal sw_error(error_message: String)

var _is_ready: bool = false
var _initialization_attempted: bool = false


func _ready() -> void:
	print("[SilentWolfManager] Initializing...")
	_initialize_silentwolf()


## Initialize and configure SilentWolf with credentials from Config
func _initialize_silentwolf() -> void:
	if _initialization_attempted:
		push_warning("[SilentWolfManager] Initialization already attempted")
		return
	
	_initialization_attempted = true
	
	# Validate Config autoload exists
	var config_node = get_node_or_null("/root/Config")
	if not config_node:
		var error: String = "Config autoload not found! Make sure config.gd is loaded."
		push_error("[SilentWolfManager] " + error)
		sw_error.emit(error)
		sw_initialized.emit(false)
		return
	
	# Validate SilentWolf plugin is loaded
	if not SilentWolf:
		var error: String = "SilentWolf autoload not found! Make sure the plugin is enabled."
		push_error("[SilentWolfManager] " + error)
		sw_error.emit(error)
		sw_initialized.emit(false)
		return
	
	# Get credentials from Config
	var api_key: String = config_node.get("SW_API_KEY") if config_node.has_method("get") else ""
	var game_id: String = config_node.get("SW_GAME_ID") if config_node.has_method("get") else ""
	var log_level: int = config_node.get("SW_LOG_LEVEL") if config_node.has_method("get") else 1
	
	# Fallback: try direct property access
	if api_key.is_empty() or game_id.is_empty():
		api_key = config_node.SW_API_KEY if "SW_API_KEY" in config_node else ""
		game_id = config_node.SW_GAME_ID if "SW_GAME_ID" in config_node else ""
		log_level = config_node.SW_LOG_LEVEL if "SW_LOG_LEVEL" in config_node else 1
	
	# Check for placeholder keys (security warning)
	if api_key == "SW_API_KEY_PLACEHOLDER" or game_id == "SW_GAME_ID_PLACEHOLDER":
		push_warning("[SilentWolfManager] ⚠️ Running with DUMMY/PLACEHOLDER keys!")
		push_warning("[SilentWolfManager]   → Local dev: Replace placeholders in config.gd")
		push_warning("[SilentWolfManager]   → Production: Ensure GitHub secrets are configured")
		_log_to_browser_console("WARNING: Running with placeholder API keys!", true)
	
	# Validate credentials
	if not _validate_credentials(api_key, game_id):
		sw_initialized.emit(false)
		return
	
	# Configure SilentWolf
	SilentWolf.configure({
		"api_key": api_key,
		"game_id": game_id,
		"log_level": log_level
	})
	
	# Enable detailed logging for web builds (critical for debugging)
	if OS.has_feature("web"):
		SilentWolf.log_level = 1  # Enable info logs
		print("[SilentWolfManager] Web build detected - verbose logging enabled")
		_log_to_browser_console("SilentWolf initialized for game: " + game_id)
	
	_is_ready = true
	print("[SilentWolfManager] ✓ Successfully configured!")
	print("[SilentWolfManager]   Game ID: ", game_id)
	print("[SilentWolfManager]   API Key: ", api_key.substr(0, 8), "...")
	print("[SilentWolfManager]   Log Level: ", log_level)
	
	sw_initialized.emit(true)


## Check if SilentWolf is ready for API calls
func is_ready() -> bool:
	return _is_ready


## Validate that credentials are properly configured
func _validate_credentials(api_key: String, game_id: String) -> bool:
	# Check for empty credentials
	if api_key.is_empty() or game_id.is_empty():
		var error: String = "SilentWolf credentials are empty! Check config.gd"
		push_error("[SilentWolfManager] " + error)
		sw_error.emit(error)
		return false
	
	# Check for placeholder values
	var invalid_keys: Array[String] = [
		"YOUR_API_KEY_HERE",
		"YOURAPIKEY",
		"SW_API_KEY_PLACEHOLDER",
		"FmKF4gtm0Z2RbUAEU62kZ2OZoYLj4PYOURAPIKEY"
	]
	
	var invalid_ids: Array[String] = [
		"YOUR_GAME_ID_HERE",
		"YOURGAMEID",
		"SW_GAME_ID_PLACEHOLDER"
	]
	
	if api_key in invalid_keys:
		var error: String = "SilentWolf API Key is not configured! Update config.gd with your real API key."
		push_error("[SilentWolfManager] " + error)
		sw_error.emit(error)
		return false
	
	if game_id in invalid_ids:
		var error: String = "SilentWolf Game ID is not configured! Update config.gd with your real Game ID."
		push_error("[SilentWolfManager] " + error)
		sw_error.emit(error)
		return false
	
	return true


## Log message to browser console (web builds only)
func _log_to_browser_console(message: String, is_error: bool = false) -> void:
	if not OS.has_feature("web"):
		return
	
	var js_command: String = ""
	if is_error:
		js_command = "console.error('[SilentWolf] " + message.replace("'", "\\'") + "');"
	else:
		js_command = "console.log('[SilentWolf] " + message.replace("'", "\\'") + "');"
	
	JavaScriptBridge.eval(js_command)


## Log error to browser console (web builds only)
func log_error_to_console(message: String) -> void:
	_log_to_browser_console(message, true)


## Log info to browser console (web builds only)
func log_to_console(message: String) -> void:
	_log_to_browser_console(message, false)


## Get current configuration status for debugging
func get_status() -> Dictionary:
	return {
		"is_ready": _is_ready,
		"initialization_attempted": _initialization_attempted,
		"silentwolf_loaded": SilentWolf != null,
		"config_loaded": get_node_or_null("/root/Config") != null,
		"platform": OS.get_name(),
		"is_web": OS.has_feature("web")
	}
