extends Node
class_name GameManager

const SAVE_PATH: String = "user://savegame.tres"

var score: int = 0
var health: int = 3
var high_score: int = 0
var is_over: bool = false
var current_difficulty_factor: float = 1.0

@export var difficulty_step_score: int = 100
@export var difficulty_step_increment: float = 0.1
@export var difficulty_max_factor: float = 2.0

@export var hit_stop_duration: float = 0.08
@export var flash_opacity: float = 0.75
@export var flash_fade_time: float = 0.12

var _hit_stop_timer: SceneTreeTimer
var _flash_rect: ColorRect
var _flash_tween: Tween


func _ready() -> void:
	load_game()
	Events.request_add_score.connect(_on_request_add_score)
	Events.request_take_damage.connect(_on_request_take_damage)
	Events.game_over.connect(_on_game_over)
	Events.score_updated.emit(score)
	Events.health_updated.emit(health)
	call_deferred("_emit_high_score")
	_update_difficulty_factor()
	_setup_flash_overlay()


func _on_request_add_score(amount: int) -> void:
	if is_over:
		return
	score += amount
	Events.score_updated.emit(score)
	if score > high_score:
		high_score = score
		Events.high_score_updated.emit(high_score)
	_update_difficulty_factor()


func _on_request_take_damage(amount: int) -> void:
	if is_over:
		return
	health = max(0, health - amount)
	Events.health_updated.emit(health)
	_apply_hit_stop()
	_flash_damage()
	if health <= 0:
		is_over = true
		Events.game_over.emit()


func _on_game_over() -> void:
	Engine.time_scale = 1.0
	_clear_flash_overlay()
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


func _setup_flash_overlay() -> void:
	var ui_layer: CanvasLayer = get_node_or_null("UI") as CanvasLayer
	if ui_layer == null:
		return

	_flash_rect = ColorRect.new()
	_flash_rect.name = "DamageFlash"
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_flash_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_flash_rect.anchor_left = 0.0
	_flash_rect.anchor_top = 0.0
	_flash_rect.anchor_right = 1.0
	_flash_rect.anchor_bottom = 1.0
	_flash_rect.offset_left = 0.0
	_flash_rect.offset_top = 0.0
	_flash_rect.offset_right = 0.0
	_flash_rect.offset_bottom = 0.0
	ui_layer.add_child(_flash_rect)


func _apply_hit_stop() -> void:
	Engine.time_scale = 0.0
	if _hit_stop_timer and _hit_stop_timer.timeout.is_connected(_end_hit_stop):
		_hit_stop_timer.timeout.disconnect(_end_hit_stop)
	_hit_stop_timer = get_tree().create_timer(hit_stop_duration, true, false, true)
	_hit_stop_timer.timeout.connect(_end_hit_stop)


func _end_hit_stop() -> void:
	Engine.time_scale = 1.0


func _flash_damage() -> void:
	if _flash_rect == null:
		return

	if _flash_tween and _flash_tween.is_running():
		_flash_tween.kill()
	_flash_rect.color = Color(1, 1, 1, flash_opacity)
	_flash_tween = get_tree().create_tween()
	_flash_tween.set_ignore_time_scale(true)
	_flash_tween.tween_property(_flash_rect, "color:a", 0.0, flash_fade_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)


func _clear_flash_overlay() -> void:
	if _flash_tween:
		_flash_tween.kill()
	if _flash_rect:
		_flash_rect.color = Color(1, 1, 1, 0)


func _update_difficulty_factor() -> void:
	var step_points: int = max(1, difficulty_step_score)
	var steps: int = int(score / step_points)
	var target: float = 1.0 + (difficulty_step_increment * float(steps))
	target = clamp(target, 1.0, difficulty_max_factor)
	if is_equal_approx(target, current_difficulty_factor):
		return
	current_difficulty_factor = target
