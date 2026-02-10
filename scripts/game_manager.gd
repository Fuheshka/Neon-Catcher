extends Node
class_name GameManager

const SAVE_PATH: String = "user://savegame.tres"

var score: int = 0
var health: int = 3
var high_score: int = 0
var is_over: bool = false
var current_difficulty_factor: float = 1.0
var _start_overlay: Control
var _world_environment: WorldEnvironment
var _low_fps_timer: Timer
var _low_fps_trigger_count: int = 0
var _start_gate_open: bool = false

@export var difficulty_step_score: int = 100
@export var difficulty_step_increment: float = 0.1
@export var difficulty_max_factor: float = 2.0
@export var low_fps_threshold: float = 45.0
@export var low_fps_check_interval: float = 3.0
@export var low_fps_required_hits: int = 2

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
	_cache_world_environment()
	_setup_flash_overlay()
	_setup_start_overlay()
	_connect_viewport_resize()
	_start_low_fps_monitor()


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
	_hit_stop_timer = get_tree().create_timer(hit_stop_duration, false, true, true)
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


func _connect_viewport_resize() -> void:
	var viewport: Viewport = get_viewport()
	if viewport and not viewport.size_changed.is_connected(_on_viewport_resized):
		viewport.size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()


func _on_viewport_resized() -> void:
	_recenter_ui()


func _recenter_ui() -> void:
	var ui_layer: CanvasLayer = get_node_or_null("UI") as CanvasLayer
	if ui_layer == null:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_center_control(ui_layer.get_node_or_null("GameOver/VBoxContainer") as Control, viewport_size)
	_center_control(ui_layer.get_node_or_null("StartOverlay/VBoxContainer") as Control, viewport_size)


func _center_control(control: Control, viewport_size: Vector2) -> void:
	if control == null:
		return
	var size: Vector2 = control.size
	if size == Vector2.ZERO:
		size = control.get_combined_minimum_size()
	control.position = (viewport_size * 0.5) - ((size * control.scale) * 0.5)


func _setup_start_overlay() -> void:
	var ui_layer: CanvasLayer = get_node_or_null("UI") as CanvasLayer
	if ui_layer == null:
		return
	_start_overlay = ui_layer.get_node_or_null("StartOverlay") as Control
	if _start_overlay == null:
		return
	if not OS.has_feature("web"):
		_start_overlay.visible = false
		_start_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
	Engine.time_scale = 0.0
	_start_overlay.visible = true
	_start_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	if not _start_overlay.gui_input.is_connected(_on_start_overlay_gui_input):
		_start_overlay.gui_input.connect(_on_start_overlay_gui_input)
	var start_button: Button = _start_overlay.get_node_or_null("VBoxContainer/StartButton") as Button
	if start_button and not start_button.pressed.is_connected(_on_start_overlay_confirmed):
		start_button.pressed.connect(_on_start_overlay_confirmed)
	_recenter_ui()


func _on_start_overlay_gui_input(event: InputEvent) -> void:
	if _start_gate_open:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_on_start_overlay_confirmed()
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		_on_start_overlay_confirmed()


func _on_start_overlay_confirmed() -> void:
	if _start_gate_open:
		return
	_start_gate_open = true
	Engine.time_scale = 1.0
	if is_instance_valid(_start_overlay):
		_start_overlay.visible = false
		_start_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Events.web_ready.emit()


func _update_difficulty_factor() -> void:
	var step_points: int = max(1, difficulty_step_score)
	var steps: int = int(score / step_points)
	var target: float = 1.0 + (difficulty_step_increment * float(steps))
	target = clamp(target, 1.0, difficulty_max_factor)
	if is_equal_approx(target, current_difficulty_factor):
		return
	current_difficulty_factor = target


func _cache_world_environment() -> void:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return
	_world_environment = parent_node.get_node_or_null("WorldEnvironment") as WorldEnvironment


func _start_low_fps_monitor() -> void:
	if low_fps_threshold <= 0.0:
		return
	_low_fps_timer = Timer.new()
	_low_fps_timer.wait_time = max(0.5, low_fps_check_interval)
	_low_fps_timer.one_shot = false
	_low_fps_timer.autostart = true
	add_child(_low_fps_timer)
	_low_fps_timer.timeout.connect(_check_low_fps)


func _check_low_fps() -> void:
	if _world_environment == null or _world_environment.environment == null:
		return
	var fps: float = float(Engine.get_frames_per_second())
	if fps <= low_fps_threshold:
		_low_fps_trigger_count += 1
		if _low_fps_trigger_count >= max(1, low_fps_required_hits):
			_disable_heavy_environment_effects()
	else:
		_low_fps_trigger_count = 0


func _disable_heavy_environment_effects() -> void:
	if _world_environment == null:
		return
	var env: Environment = _world_environment.environment
	if env == null or not env.glow_enabled:
		return
	env.glow_enabled = false
	push_warning("Disabled glow due to sustained low FPS on web build.")
