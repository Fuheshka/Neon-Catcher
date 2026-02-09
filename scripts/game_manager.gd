extends Node
class_name GameManager

const SAVE_PATH: String = "user://savegame.tres"

var score: int = 0
var health: int = 3
var high_score: int = 0
var is_over: bool = false


func _ready() -> void:
	load_game()
	Events.request_add_score.connect(_on_request_add_score)
	Events.request_take_damage.connect(_on_request_take_damage)
	Events.game_over.connect(_on_game_over)
	Events.score_updated.emit(score)
	Events.health_updated.emit(health)
	call_deferred("_emit_high_score")


func _on_request_add_score(amount: int) -> void:
	if is_over:
		return
	score += amount
	Events.score_updated.emit(score)
	if score > high_score:
		high_score = score
		Events.high_score_updated.emit(high_score)


func _on_request_take_damage(amount: int) -> void:
	if is_over:
		return
	health = max(0, health - amount)
	Events.health_updated.emit(health)
	if health <= 0:
		is_over = true
		Events.game_over.emit()


func _on_game_over() -> void:
	save_game()


func save_game() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Failed to save game: %s" % [FileAccess.get_open_error()])
		return
	var data: Dictionary = {
		"high_score": high_score,
	}
	file.store_string(JSON.stringify(data))
	file.flush()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Failed to load game: %s" % [FileAccess.get_open_error()])
		return
	var content: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(content)
	if typeof(parsed) == TYPE_DICTIONARY and parsed.has("high_score"):
		high_score = max(0, int(parsed["high_score"]))


func _emit_high_score() -> void:
	Events.high_score_updated.emit(high_score)
