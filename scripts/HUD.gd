extends Control
class_name HUD

"""Displays live score and health values from the Events autoload."""

@export var score_label: Label
@export var health_label: Label
@export var high_score_label: Label

var _score: int = 0
var _health: int = 0
var _high_score: int = 0
var _score_pop_tween: Tween


func _ready() -> void:
	Events.score_updated.connect(_on_score_updated)
	Events.health_updated.connect(_on_health_updated)
	Events.high_score_updated.connect(_on_high_score_updated)
	var gm: GameManager = get_node_or_null("/root/GameManager") as GameManager
	if gm:
		_high_score = gm.high_score
	if is_instance_valid(score_label):
		score_label.pivot_offset = score_label.size * 0.5
		score_label.scale = Vector2.ONE
	# Initialize UI immediately so it reflects current state on load.
	_refresh_labels()


func _on_score_updated(new_score: int) -> void:
	_score = new_score
	_refresh_labels()
	_pop_score_label()


func _on_health_updated(new_health: int) -> void:
	_health = new_health
	_refresh_labels()


func _on_high_score_updated(new_high_score: int) -> void:
	_high_score = new_high_score
	_refresh_labels()


func _refresh_labels() -> void:
	if is_instance_valid(score_label):
		score_label.text = "Score: %d" % _score
	if is_instance_valid(health_label):
		health_label.text = "Health: %d" % _health
	if is_instance_valid(high_score_label):
		high_score_label.text = "Best: %d" % _high_score


func _pop_score_label() -> void:
	if not is_instance_valid(score_label):
		return
	if is_instance_valid(_score_pop_tween):
		_score_pop_tween.kill()
	score_label.scale = Vector2.ONE
	_score_pop_tween = create_tween()
	_score_pop_tween.set_trans(Tween.TRANS_CUBIC)
	_score_pop_tween.set_ease(Tween.EASE_OUT)
	_score_pop_tween.tween_property(score_label, "scale", Vector2(1.5, 1.5), 0.1)
	_score_pop_tween.set_ease(Tween.EASE_IN)
	_score_pop_tween.tween_property(score_label, "scale", Vector2.ONE, 0.1)
