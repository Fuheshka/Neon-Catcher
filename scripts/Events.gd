@warning_ignore("unused_signal")
extends Node

signal request_add_score(amount: int)
signal request_take_damage(amount: int)
signal score_updated(new_total: int)
signal health_updated(new_total: int)
signal game_over()
@warning_ignore("unused_signal")
signal high_score_updated(amount: int)
signal difficulty_increased(level: int)
signal web_ready()
signal combo_changed(multiplier: float)
signal impact_occurred()
signal bonus_missed()


func _ready() -> void:
	# No-op hooks to satisfy static analyzer for signals emitted externally.
	high_score_updated.connect(func(_v): pass)
	if Engine.is_editor_hint():
		high_score_updated.emit(0)


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


func emit_difficulty_increased(level: int) -> void:
	difficulty_increased.emit(level)


func emit_web_ready() -> void:
	web_ready.emit()


func emit_combo_changed(multiplier: int) -> void:
	combo_changed.emit(multiplier)


func emit_impact_occurred() -> void:
	impact_occurred.emit()
