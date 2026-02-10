extends Control
## RegistrationScreen - UI for entering nickname after achieving a high score

@onready var nickname_input: LineEdit = $Panel/VBoxContainer/NicknameInput
@onready var confirm_button: Button = $Panel/VBoxContainer/ConfirmButton
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var score_label: Label = $Panel/VBoxContainer/ScoreLabel

var current_score: int = 0

signal nickname_submitted()


func _ready() -> void:
	hide()
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_pressed)
	
	if nickname_input:
		nickname_input.text_submitted.connect(_on_text_submitted)
		nickname_input.max_length = 12


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
	
	var nickname = nickname_input.text.strip_edges()
	
	# Validate nickname
	if nickname.is_empty():
		nickname = "Anonymous"
	
	# Add to leaderboard
	LeaderboardManager.add_score(nickname, current_score)
	
	# Emit signal to notify parent
	nickname_submitted.emit()
	
	# Hide this screen
	hide()
