extends ColorRect
class_name Background

@export var start_color: Color = Color(0.05, 0.08, 0.16, 1.0)
@export var end_color: Color = Color(0.4, 0.05, 0.07, 1.0)
@export var max_difficulty_steps: int = 10
@export var transition_duration: float = 1.4

var _tween: Tween


func _ready() -> void:
	color = start_color
	Events.difficulty_increased.connect(_on_difficulty_increased)
	Events.game_over.connect(_on_game_over)


func _on_difficulty_increased(level: int) -> void:
	var t: float = clamp(float(level) / float(max_difficulty_steps), 0.0, 1.0)
	var target: Color = start_color.lerp(end_color, t)

	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "color", target, transition_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _on_game_over() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "color", start_color, transition_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
