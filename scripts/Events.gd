extends Node

signal request_add_score(amount: int)
signal request_take_damage(amount: int)
signal score_updated(new_total: int)
signal health_updated(new_total: int)
signal game_over()
signal high_score_updated(amount: int)


func _ready() -> void:
	pass


func emit_request_add_score(amount: int) -> void:
	request_add_score.emit(amount)


func emit_request_take_damage(amount: int) -> void:
	request_take_damage.emit(amount)


func emit_score_updated(new_total: int) -> void:
	score_updated.emit(new_total)


func emit_health_updated(new_total: int) -> void:
	health_updated.emit(new_total)


func emit_game_over() -> void:
	game_over.emit()
