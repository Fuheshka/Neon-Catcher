extends Control
class_name HUD

"""Displays live score and health values from the Events autoload."""

@export var score_label: Label
@export var health_label: Label
@export var high_score_label: Label
@export var combo_label: Label

@export var impact_shake_distance: float = 8.0
@export var impact_duration: float = 0.2

@export var combo_color_low: Color = Color(0.5, 0.8, 1.0, 1.0)
@export var combo_color_mid: Color = Color(1.0, 0.8, 0.2, 1.0)
@export var combo_color_high: Color = Color(1.0, 0.2, 0.2, 1.0)
@export var combo_color_veryhigh: Color = Color(0.819, 0.393, 0.832, 1.0)
@export var combo_color_max: Color = Color(0.536, 0.0, 0.98, 1.0)

var _score: int = 0
var _health: int = 0
var _high_score: int = 0
var _combo: float = 1.0
var _score_pop_tween: Tween
var _combo_pop_tween: Tween
var _impact_tween: Tween
var _base_position: Vector2


func _ready() -> void:
	_base_position = position
	Events.score_updated.connect(_on_score_updated)
	Events.health_updated.connect(_on_health_updated)
	Events.high_score_updated.connect(_on_high_score_updated)
	Events.combo_changed.connect(_on_combo_changed)
	Events.impact_occurred.connect(_on_impact_occurred)
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


func _on_combo_changed(new_combo: float) -> void:
	_combo = max(1.0, new_combo)
	_refresh_labels()
	_pop_combo_label()


func _on_impact_occurred() -> void:
	_play_ui_glitch()


func _refresh_labels() -> void:
	if is_instance_valid(score_label):
		score_label.text = "Score: %d" % _score
	if is_instance_valid(health_label):
		health_label.text = "Health: %d" % _health
	if is_instance_valid(high_score_label):
		high_score_label.text = "Best: %d" % _high_score
	if is_instance_valid(combo_label):
		if _combo == floor(_combo):
			combo_label.text = "Combo: x%.0f" % _combo
		else:
			combo_label.text = "Combo: x%.2f" % _combo
		# Меняем цвет комбо в зависимости от значения
		if _combo >=10:
			combo_label.modulate = combo_color_max
		elif _combo >=5:
			combo_label.modulate = combo_color_veryhigh
		elif _combo >= 2.5:
			combo_label.modulate = combo_color_high
		elif _combo >= 1.75:
			combo_label.modulate = combo_color_mid
		else:
			combo_label.modulate = combo_color_low


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


func _pop_combo_label() -> void:
	if not is_instance_valid(combo_label):
		return
	if is_instance_valid(_combo_pop_tween):
		_combo_pop_tween.kill()
	combo_label.scale = Vector2.ONE
	_combo_pop_tween = create_tween()
	_combo_pop_tween.set_trans(Tween.TRANS_SINE)
	_combo_pop_tween.set_ease(Tween.EASE_OUT)
	_combo_pop_tween.tween_property(combo_label, "scale", Vector2(1.25, 1.25), 0.1)
	_combo_pop_tween.tween_property(combo_label, "scale", Vector2.ONE, 0.08)


func _play_ui_glitch() -> void:
	if is_instance_valid(_impact_tween):
		_impact_tween.kill()
	position = _base_position
	var offset: Vector2 = Vector2(randf_range(-impact_shake_distance, impact_shake_distance), randf_range(-impact_shake_distance, impact_shake_distance))
	_impact_tween = create_tween()
	_impact_tween.set_ignore_time_scale(true)
	_impact_tween.tween_property(self, "position", _base_position + offset, impact_duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_impact_tween.tween_property(self, "position", _base_position, impact_duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
