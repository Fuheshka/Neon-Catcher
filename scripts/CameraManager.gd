extends Camera2D
class_name CameraManager

@export var shake_intensity: float = 18.0
@export var shake_duration: float = 0.2
@export var shake_decay: float = 48.0

var _previous_health: int = -1
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _shake_strength: float = 0.0
var _shake_time_left: float = 0.0


func _ready() -> void:
	_rng.randomize()
	Events.health_updated.connect(_on_health_updated)
	Events.game_over.connect(_on_game_over)
	set_process(false)


func _on_health_updated(new_total: int) -> void:
	if _previous_health < 0:
		_previous_health = new_total
		return

	if new_total < _previous_health:
		_trigger_shake()

	_previous_health = new_total


func _trigger_shake() -> void:
	# Additive shake: stack strength and extend duration instead of resetting.
	_shake_strength += shake_intensity
	_shake_time_left = max(_shake_time_left, shake_duration)
	set_process(true)


func _process(delta: float) -> void:
	if _shake_time_left <= 0.0 and _shake_strength <= 0.0:
		_reset_offset()
		set_process(false)
		return

	_shake_time_left = max(0.0, _shake_time_left - delta)
	_shake_strength = move_toward(_shake_strength, 0.0, shake_decay * delta)

	var offset_range: float = _shake_strength
	var offset_x: float = _rng.randf_range(-offset_range, offset_range)
	var offset_y: float = _rng.randf_range(-offset_range, offset_range)
	offset = Vector2(offset_x, offset_y)

	if _shake_time_left <= 0.0 and _shake_strength <= 0.1:
		_reset_offset()
		set_process(false)


func _reset_offset() -> void:
	_shake_strength = 0.0
	_shake_time_left = 0.0
	offset = Vector2.ZERO


func _on_game_over() -> void:
	_previous_health = -1
	_reset_offset()
