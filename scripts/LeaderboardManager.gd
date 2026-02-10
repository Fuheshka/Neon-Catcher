extends Node
## LeaderboardManager - AutoLoad singleton for managing top 10 scores

const LEADERBOARD_FILE = "user://leaderboard.json"
const MAX_ENTRIES = 10

## Array of dictionaries: {"name": String, "score": int}
var leaderboard: Array[Dictionary] = []

signal leaderboard_updated()


func _ready() -> void:
	load_leaderboard()


## Check if a score qualifies for the Top 10
func is_high_score(score: int) -> bool:
	# If we have less than MAX_ENTRIES, it's automatically a high score
	if leaderboard.size() < MAX_ENTRIES:
		return true
	
	# Check if the score is higher than the lowest score in the leaderboard
	return score > leaderboard[leaderboard.size() - 1]["score"]


## Add a new score entry to the leaderboard
func add_score(nickname: String, score: int) -> void:
	# Create new entry
	var entry: Dictionary = {
		"name": nickname.strip_edges().substr(0, 12),  # Limit to 12 characters
		"score": score
	}
	
	# Add to leaderboard
	leaderboard.append(entry)
	
	# Sort by score (descending)
	leaderboard.sort_custom(func(a, b): return a["score"] > b["score"])
	
	# Keep only top 10
	if leaderboard.size() > MAX_ENTRIES:
		leaderboard.resize(MAX_ENTRIES)
	
	# Save and notify
	save_leaderboard()
	leaderboard_updated.emit()


## Add or update player score (prevents duplicate entries for same player)
func add_or_update_score(nickname: String, score: int, player_id: String = "") -> void:
	var sanitized_name: String = nickname.strip_edges().substr(0, 12)
	
	# Check if player already exists (by player_id if provided, otherwise by name)
	var player_index: int = -1
	for i in range(leaderboard.size()):
		var entry = leaderboard[i]
		# Match by player_id if both have it
		if not player_id.is_empty() and entry.has("player_id") and entry["player_id"] == player_id:
			player_index = i
			break
		# Fallback to name matching (for backward compatibility)
		elif player_id.is_empty() and entry["name"] == sanitized_name:
			player_index = i
			break
	
	if player_index >= 0:
		# Player exists - update only if new score is higher
		var old_score: int = leaderboard[player_index]["score"]
		if score > old_score:
			print("🔄 Updating ", sanitized_name, "'s score: ", old_score, " → ", score)
			leaderboard[player_index]["score"] = score
			leaderboard[player_index]["name"] = sanitized_name  # Update name if changed
			if not player_id.is_empty():
				leaderboard[player_index]["player_id"] = player_id
			
			# Re-sort after update
			leaderboard.sort_custom(func(a, b): return a["score"] > b["score"])
			
			save_leaderboard()
			leaderboard_updated.emit()
		else:
			print("❌ Score ", score, " is not higher than existing ", old_score, " for ", sanitized_name)
	else:
		# New player - add entry
		print("✨ New player: ", sanitized_name, " with score: ", score)
		var entry: Dictionary = {
			"name": sanitized_name,
			"score": score
		}
		
		# Add player_id if provided
		if not player_id.is_empty():
			entry["player_id"] = player_id
		
		leaderboard.append(entry)
		leaderboard.sort_custom(func(a, b): return a["score"] > b["score"])
		
		# Keep only top 10
		if leaderboard.size() > MAX_ENTRIES:
			leaderboard.resize(MAX_ENTRIES)
		
		save_leaderboard()
		leaderboard_updated.emit()


## Get the full leaderboard
func get_leaderboard() -> Array[Dictionary]:
	return leaderboard.duplicate()


## Get a specific rank (1-based index)
func get_rank(index: int) -> Dictionary:
	if index > 0 and index <= leaderboard.size():
		return leaderboard[index - 1]
	return {}


## Save leaderboard to disk
func save_leaderboard() -> void:
	var file = FileAccess.open(LEADERBOARD_FILE, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open leaderboard file for writing: " + str(FileAccess.get_open_error()))
		return
	
	var json_string = JSON.stringify(leaderboard, "\t")
	file.store_string(json_string)
	file.close()


## Load leaderboard from disk
func load_leaderboard() -> void:
	if not FileAccess.file_exists(LEADERBOARD_FILE):
		# Initialize with empty leaderboard
		leaderboard = []
		return
	
	var file = FileAccess.open(LEADERBOARD_FILE, FileAccess.READ)
	if file == null:
		push_error("Failed to open leaderboard file for reading: " + str(FileAccess.get_open_error()))
		leaderboard = []
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error == OK:
		var data = json.data
		if data is Array:
			leaderboard = []
			for entry in data:
				if entry is Dictionary and entry.has("name") and entry.has("score"):
					leaderboard.append(entry)
		else:
			push_error("Leaderboard data is not an array")
			leaderboard = []
	else:
		push_error("Failed to parse leaderboard JSON: " + json.get_error_message())
		leaderboard = []


## Clear all leaderboard entries
func clear_leaderboard() -> void:
	leaderboard.clear()
	save_leaderboard()
	leaderboard_updated.emit()
