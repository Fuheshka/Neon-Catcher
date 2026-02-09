extends Area2D
class_name Player

"""Maximum horizontal speed (pixels/sec)."""
@export var speed: float = 550.0

"""How quickly the player accelerates toward the target speed."""
@export var acceleration: float = 1800.0

"""How quickly the player slows down when there is no input."""
@export var friction: float = 2200.0

"""Maximum tilt in radians applied while moving."""
@export var max_tilt_radians: float = 0.15

"""Horizontal padding to keep the paddle on-screen."""
@export var screen_padding: float = 64.0

"""Number of points retained in the neon trail."""
@export var trail_point_limit: int = 22

"""Minimum distance between trail points (pixels)."""
@export var trail_spacing: float = 10.0

"""Minimum horizontal speed before the trail begins."""
@export var trail_min_speed: float = 80.0

"""Width of the neon trail line."""
@export var trail_width: float = 8.0

"""Color of the neon trail (HDR for extra glow)."""
@export var trail_color: Color = Color(0.0, 1.8, 1.5, 0.9)

"""How quickly the trail erodes when idle (points per second)."""
@export var trail_decay_rate: float = 18.0

var _enabled: bool = true
var _velocity_x: float = 0.0
var _tilt_tween: Tween
var _squash_tween: Tween
var _last_move_sign: int = 0
var _base_scale: Vector2
var _pointer_active: bool = false
var _pointer_position_x: float = 0.0
var _pointer_dead_zone: float = 8.0
@onready var _events: Node = get_node("/root/Events")
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _trail_line: Line2D = $TrailLine

@onready var confetti: CPUParticles2D = $Confetti

var _trail_points_world: PackedVector2Array = PackedVector2Array()


func _ready() -> void:
	# Listen for game over to stop player control.
	_events.connect("game_over", _on_game_over)
	# Use area_entered to detect collisions with falling objects.
	area_entered.connect(_on_area_entered)
	_base_scale = _sprite.scale
	_setup_trail_line()


func _physics_process(delta: float) -> void:
	if not _enabled:
		return

	var viewport_width: float = get_viewport_rect().size.x
	var axis: float = Input.get_axis("move_left", "move_right")
	if _pointer_active:
		var dx: float = _pointer_position_x - global_position.x
		if abs(dx) > _pointer_dead_zone:
			var normalized: float = dx / max(1.0, viewport_width * 0.35)
			axis = clamp(normalized, -1.0, 1.0)
		else:
			axis = 0.0
	var target_speed: float = axis * speed
	var accel: float = acceleration if abs(axis) > 0.01 else friction
	_velocity_x = move_toward(_velocity_x, target_speed, accel * delta)
	global_position.x += _velocity_x * delta

	var move_sign: int = int(sign(_velocity_x))
	if move_sign != 0 and move_sign != _last_move_sign and abs(_velocity_x) > speed * 0.3:
		_play_squash_stretch(move_sign)
	_last_move_sign = move_sign

	var margin: float = _get_horizontal_margin()
	# clamp() keeps X within [min, max] to prevent leaving the visible play area.
	global_position.x = clamp(global_position.x, margin, viewport_width - margin)

	_update_tilt()
	_update_trail(delta)


## Exists to forward collision results into the shared event bus.
func handle_collision(falling_object: FallingObject) -> void:
	if falling_object.damage_value > 0:
		Events.request_take_damage.emit(falling_object.damage_value)
	if falling_object.score_value > 0:
		Events.request_add_score.emit(falling_object.score_value)
		confetti.restart()


func _on_area_entered(area: Area2D) -> void:
	if area is FallingObject:
		handle_collision(area as FallingObject)
		area.queue_free()


func _on_game_over() -> void:
	_enabled = false
	_velocity_x = 0.0
	_pointer_active = false
	_reset_tilt()
	_reset_squash()


func _unhandled_input(event: InputEvent) -> void:
	if not _enabled:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		_pointer_active = touch.pressed
		_pointer_position_x = touch.position.x
	elif event is InputEventScreenDrag:
		_pointer_active = true
		_pointer_position_x = (event as InputEventScreenDrag).position.x
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mouse_button := event as InputEventMouseButton
		_pointer_active = mouse_button.pressed
		_pointer_position_x = mouse_button.position.x
	elif event is InputEventMouseMotion and _pointer_active:
		_pointer_position_x = (event as InputEventMouseMotion).position.x


func _update_tilt() -> void:
	var tilt_ratio: float = clamp(_velocity_x / speed, -1.0, 1.0)
	var target_rotation: float = max_tilt_radians * tilt_ratio

	if _tilt_tween and _tilt_tween.is_running():
		_tilt_tween.kill()
	_tilt_tween = create_tween()
	_tilt_tween.tween_property(_sprite, "rotation", target_rotation, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _reset_tilt() -> void:
	if _tilt_tween and _tilt_tween.is_running():
		_tilt_tween.kill()
	_sprite.rotation = 0.0


func _reset_squash() -> void:
	if _squash_tween and _squash_tween.is_running():
		_squash_tween.kill()
	_sprite.scale = _base_scale


func _update_trail(delta: float) -> void:
	if _trail_line == null:
		return
	if _trail_points_world.is_empty():
		_trail_points_world.append(global_position)

	if abs(_velocity_x) < trail_min_speed:
		if _trail_points_world.size() > 1:
			var remove_count: int = clampi(int(ceil(trail_decay_rate * delta)), 1, _trail_points_world.size() - 1)
			for i in range(remove_count):
				_trail_points_world.remove_at(0)
		_update_trail_line_points()
		return

	var last_point: Vector2 = _trail_points_world[_trail_points_world.size() - 1]
	var distance: float = global_position.distance_to(last_point)
	if distance >= trail_spacing:
		_trail_points_world.append(global_position)
	else:
		_trail_points_world[_trail_points_world.size() - 1] = global_position

	while _trail_points_world.size() > trail_point_limit:
		_trail_points_world.remove_at(0)

	_update_trail_line_points()


func _setup_trail_line() -> void:
	if _trail_line == null:
		return
	_trail_line.width = trail_width
	_trail_line.default_color = trail_color
	_trail_line.clear_points()
	_trail_points_world.clear()
	_trail_points_world.append(global_position)
	_update_trail_line_points()


func _update_trail_line_points() -> void:
	if _trail_line == null:
		return
	var local_points: PackedVector2Array = PackedVector2Array()
	for world_point in _trail_points_world:
		local_points.append(to_local(world_point))
	_trail_line.points = local_points


func _play_squash_stretch(_direction_sign: int) -> void:
	if _squash_tween and _squash_tween.is_running():
		_squash_tween.kill()
	var squash_scale: Vector2 = Vector2(_base_scale.x * 1.2, _base_scale.y * 0.8)
	_squash_tween = create_tween()
	_squash_tween.tween_property(_sprite, "scale", squash_scale, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_squash_tween.tween_property(_sprite, "scale", _base_scale, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _get_horizontal_margin() -> float:
	if _sprite == null or _sprite.texture == null:
		return screen_padding
	var sprite_width: float = _sprite.texture.get_size().x * abs(_sprite.global_scale.x)
	return max(screen_padding, sprite_width * 0.5)
