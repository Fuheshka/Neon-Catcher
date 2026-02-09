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

"""Seconds between spawning trail ghosts when moving."""
@export var trail_spawn_interval: float = 0.06

"""Minimum speed before ghosts start spawning."""
@export var trail_min_speed: float = 120.0

"""Horizontal padding to keep the paddle on-screen."""
@export var screen_padding: float = 64.0

var _enabled: bool = true
var _velocity_x: float = 0.0
var _trail_timer: float = 0.0
var _tilt_tween: Tween
var _squash_tween: Tween
var _last_move_sign: int = 0
var _base_scale: Vector2
@onready var _events: Node = get_node("/root/Events")
@onready var _sprite: Sprite2D = $Sprite2D

@onready var confetti: CPUParticles2D = $Confetti


func _ready() -> void:
	# Listen for game over to stop player control.
	_events.connect("game_over", _on_game_over)
	# Use area_entered to detect collisions with falling objects.
	area_entered.connect(_on_area_entered)
	_base_scale = _sprite.scale


func _physics_process(delta: float) -> void:
	if not _enabled:
		return

	var axis: float = Input.get_axis("move_left", "move_right")
	var target_speed: float = axis * speed
	var accel: float = acceleration if abs(axis) > 0.01 else friction
	_velocity_x = move_toward(_velocity_x, target_speed, accel * delta)
	global_position.x += _velocity_x * delta

	var move_sign: int = int(sign(_velocity_x))
	if move_sign != 0 and move_sign != _last_move_sign and abs(_velocity_x) > speed * 0.3:
		_play_squash_stretch(move_sign)
	_last_move_sign = move_sign

	var viewport_width: float = get_viewport_rect().size.x
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
	_reset_tilt()
	_reset_squash()


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
	if abs(_velocity_x) < trail_min_speed:
		_trail_timer = 0.0
		return

	_trail_timer -= delta
	if _trail_timer <= 0.0:
		_spawn_ghost()
		_trail_timer = trail_spawn_interval


func _spawn_ghost() -> void:
	var ghost: Sprite2D = Sprite2D.new()
	ghost.texture = _sprite.texture
	ghost.global_position = _sprite.global_position
	ghost.global_rotation = _sprite.global_rotation
	ghost.global_scale = _sprite.global_scale
	var color: Color = _sprite.modulate
	color.a = 0.6
	ghost.modulate = color
	ghost.z_index = _sprite.z_index - 1

	var parent_node: Node = get_parent()
	parent_node.add_child(ghost)
	var tween: Tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tween.tween_property(ghost, "scale", ghost.scale * 1.1, 0.25)
	tween.tween_callback(ghost.queue_free)


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
