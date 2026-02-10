extends Node
## Secure Configuration for API keys and secrets
## 
## SECURITY MODEL:
## - This file is committed with PLACEHOLDERS only
## - For LOCAL development: Replace placeholders with your real keys (DON'T commit changes!)
## - For PRODUCTION: GitHub Actions replaces placeholders with secrets before build
## 
## LOCAL SETUP:
## 1. Replace SW_API_KEY_PLACEHOLDER with your actual API key
## 2. Replace SW_GAME_ID_PLACEHOLDER with your actual Game ID
## 3. NEVER commit the real keys (use git checkout to reset before commit)
## 
## Get your credentials from: https://silentwolf.com/

# SilentWolf API Configuration
# These placeholders are replaced by GitHub Actions during deployment
const SW_API_KEY: String = "SW_API_KEY_PLACEHOLDER"
const SW_GAME_ID: String = "SW_GAME_ID_PLACEHOLDER"

# Log level: 0 = errors only, 1 = info, 2 = debug
const SW_LOG_LEVEL: int = 1


func _ready() -> void:
	# Configuration is now handled by SilentWolfManager singleton
	# This script just holds the credentials
	if SW_API_KEY == "SW_API_KEY_PLACEHOLDER" or SW_GAME_ID == "SW_GAME_ID_PLACEHOLDER":
		push_warning("⚠️ Running with PLACEHOLDER keys! Replace them in config.gd for local dev.")
		push_warning("   For production, GitHub Actions will auto-replace these.")
	else:
		print("[Config] ✓ Credentials loaded (configuration handled by SilentWolfManager)")

