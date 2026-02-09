extends Control
class_name HUD

"""Displays live score and health values from the Events autoload."""

@export var score_label: Label
@export var health_label: Label

var _score: int = 0
var _health: int = 0


func _ready() -> void:
	Events.score_updated.connect(_on_score_changed)
	Events.health_updated.connect(_on_health_changed)
	# Initialize UI immediately so it reflects current state on load.
	_refresh_labels()


func _on_score_changed(new_score: int) -> void:
	_score = new_score
	_refresh_labels()


func _on_health_changed(new_health: int) -> void:
	_health = new_health
	_refresh_labels()


func _refresh_labels() -> void:
	if is_instance_valid(score_label):
		score_label.text = str(_score)
	if is_instance_valid(health_label):
		health_label.text = str(_health)
