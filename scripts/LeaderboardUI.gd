extends Control
## LeaderboardUI - Display the top 10 scores

@onready var leaderboard_container: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/LeaderboardContainer
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel

const LEADERBOARD_ROW = preload("res://scenes/LeaderboardRow.tscn")

signal closed()


func _ready() -> void:
	hide()
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	# Listen for leaderboard updates
	if LeaderboardManager:
		LeaderboardManager.leaderboard_updated.connect(_on_leaderboard_updated)


func show_leaderboard() -> void:
	refresh_leaderboard()
	show()


func refresh_leaderboard() -> void:
	# Clear existing rows
	if leaderboard_container:
		for child in leaderboard_container.get_children():
			child.queue_free()
		
		# Get leaderboard data
		var leaderboard = LeaderboardManager.get_leaderboard()
		
		# Create rows for each entry
		for i in range(leaderboard.size()):
			var entry = leaderboard[i]
			var row = LEADERBOARD_ROW.instantiate()
			leaderboard_container.add_child(row)
			
			# Set row data
			var rank_label = row.get_node("RankLabel")
			var name_label = row.get_node("NameLabel")
			var score_label = row.get_node("ScoreLabel")
			
			if rank_label:
				rank_label.text = str(i + 1) + "."
			if name_label:
				name_label.text = entry.get("name", "Unknown")
			if score_label:
				score_label.text = str(entry.get("score", 0))
		
		# If no entries, show a message
		if leaderboard.is_empty():
			var empty_label = Label.new()
			empty_label.text = "No scores yet! Be the first!"
			empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			leaderboard_container.add_child(empty_label)


func _on_leaderboard_updated() -> void:
	if visible:
		refresh_leaderboard()


func _on_close_pressed() -> void:
	closed.emit()
	hide()
