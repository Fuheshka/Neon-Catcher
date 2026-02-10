extends Node

## Web Diagnostic Script
## Logs when the game is running on Web platform and prints project settings

func _ready() -> void:
	# Check if running on Web platform
	if OS.has_feature("web"):
		print("=== BOOTING FROM WEB ===")
		print("Platform: Web")
		print("User Agent: ", JavaScriptBridge.eval("navigator.userAgent"))
		
		# Log important project settings
		print("\n=== PROJECT SETTINGS ===")
		print("Project Name: ", ProjectSettings.get_setting("application/config/name"))
		print("Project Version: ", ProjectSettings.get_setting("application/config/version", "N/A"))
		
		# Log display settings
		print("\n=== DISPLAY SETTINGS ===")
		print("Window Width: ", ProjectSettings.get_setting("display/window/size/viewport_width"))
		print("Window Height: ", ProjectSettings.get_setting("display/window/size/viewport_height"))
		print("Window Mode: ", ProjectSettings.get_setting("display/window/size/mode"))
		print("Stretch Mode: ", ProjectSettings.get_setting("display/window/stretch/mode"))
		
		# Log audio settings
		print("\n=== AUDIO SETTINGS ===")
		print("Audio Enabled: ", ProjectSettings.get_setting("audio/driver/enable_input"))
		
		# Log resource paths
		print("\n=== RESOURCE PATHS ===")
		print("User Data Dir: ", OS.get_user_data_dir())
		print("Executable Path: ", OS.get_executable_path())
		print("Resource Path: ", ProjectSettings.globalize_path("res://"))
		
		# Log autoload singletons
		print("\n=== AUTOLOAD SINGLETONS ===")
		var autoload_count = 0
		for property in ProjectSettings.get_property_list():
			if property.name.begins_with("autoload/"):
				var autoload_name = property.name.replace("autoload/", "")
				var autoload_path = ProjectSettings.get_setting(property.name)
				print("  - %s: %s" % [autoload_name, autoload_path])
				autoload_count += 1
		print("Total Autoloads: ", autoload_count)
		
		# Log Web-specific settings
		print("\n=== WEB EXPORT SETTINGS ===")
		print("Cross-origin isolation headers: ", ProjectSettings.get_setting("progressive_web_app/ensure_cross_origin_isolation_headers", "N/A"))
		
		print("\n=== WEB BOOT COMPLETE ===\n")
	else:
		print("Not running on Web platform (OS: %s)" % OS.get_name())
