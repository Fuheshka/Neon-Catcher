extends Node
class_name GameManager

var score: int = 0
var health: int = 3
var is_over: bool = false


func _ready() -> void:
	Events.request_add_score.connect(_on_request_add_score)
	Events.request_take_damage.connect(_on_request_take_damage)
	Events.score_updated.emit(score)
	Events.health_updated.emit(health)


func _on_request_add_score(amount: int) -> void:
	if is_over:
		return
	score += amount
	Events.score_updated.emit(score)


func _on_request_take_damage(amount: int) -> void:
	if is_over:
		return
	health = max(0, health - amount)
	Events.health_updated.emit(health)
	if health <= 0:
		is_over = true
		Events.game_over.emit()
