@warning_ignore("incompatible_ternary")
extends Area2D
class_name FallingObject

@export_enum("Bonus", "Enemy", "GOLDEN") var object_type: String = "Bonus"

"""Downward speed in pixels per second."""
@export var falling_speed: float = 260.0

"""Rotation speed in degrees per second (positive = clockwise)."""
@export var rotation_speed: float = 45.0

"""How many points this object grants when caught."""
@export var score_value: int = 10

"""How much damage this object deals when hit (positive value)."""
@export var damage_value: int = 0

@onready var _screen_notifier: VisibleOnScreenNotifier2D = get_node_or_null("VisibleOnScreenNotifier2D") as VisibleOnScreenNotifier2D
@onready var _game_manager: Node = get_node_or_null("/root/GameManager")
@onready var _sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
@onready var _label: Label = get_node_or_null("Label") as Label
var _base_sprite_scale: Vector2 = Vector2.ONE
var _base_label_scale: Vector2 = Vector2.ONE
var _sprite_base_position: Vector2 = Vector2.ZERO
var _label_base_position: Vector2 = Vector2.ZERO

var _pulse_tween: Tween
var _glitch_tween: Tween

var _active: bool = true


func _ready() -> void:
	if _sprite != null:
		_base_sprite_scale = _sprite.scale
		_sprite_base_position = _sprite.position
		_maybe_infer_object_type()
	if _label != null:
		_base_label_scale = _label.scale
		_label_base_position = _label.position
	_maybe_infer_object_type()
	_apply_visual_style()
	_start_pulse()
	_start_glitch_flicker()
	if _screen_notifier != null:
		# Free the object when it leaves the screen; avoids buildup.
		_screen_notifier.screen_exited.connect(_on_screen_exited)


func _physics_process(delta: float) -> void:
	if not _active:
		return

	var speed_multiplier: float = _get_difficulty_multiplier()
	global_position.y += falling_speed * speed_multiplier * delta
	rotation_degrees += rotation_speed * delta

	# Fallback cleanup if notifier is missing.
	if _screen_notifier == null:
		var viewport_height: float = get_viewport_rect().size.y
		if global_position.y > viewport_height + 200.0:
			queue_free()


func _on_screen_exited() -> void:
	if object_type == "Bonus" or object_type == "GOLDEN":
		Events.bonus_missed.emit()
	queue_free()


func _get_difficulty_multiplier() -> float:
	if is_instance_valid(_game_manager):
		return max(0.1, _game_manager.current_difficulty_factor)
	return 1.0


func _apply_visual_style() -> void:
	var style: Dictionary = _get_style_for_type(object_type)
	if _sprite != null:
		_sprite.scale = _base_sprite_scale * (style.get("scale", Vector2.ONE))
		var current_color: Color = _sprite.modulate
		var target_color: Color = style.get("color", current_color)
		# Preserve custom-tinted bonuses (e.g., golden bonus) by only overriding
		# color when the current modulate is effectively white.
		if object_type != "Bonus" or current_color.is_equal_approx(Color.WHITE):
			_sprite.modulate = target_color
	if _label != null:
		_label.text = style.get("glyph", _label.text)
		_label.modulate = style.get("color", _label.modulate)
		_label.scale = _base_label_scale * (style.get("scale", Vector2.ONE))


func _get_style_for_type(type_name: String) -> Dictionary:
	match type_name:
		"Enemy":
			var glyphs: Array[String] = ["X", "@", "#", "%", "&"]
			return {"scale": Vector2(1.0, 1.0), "color": Color(2.0, 0.1, 0.1, 1.0), "glyph": glyphs[randi() % glyphs.size()]}
		"GOLDEN":
			return {"scale": Vector2(1.05, 1.05), "color": Color(1.4, 1.2, 0.3, 1.0), "glyph": "++"}
		_:
			var glyphs_bonus: Array[String] = ["0", "1"]
			return {"scale": Vector2(0.9, 0.9), "color": Color(0.0, 2.0, 0.25, 1.0), "glyph": glyphs_bonus[randi() % glyphs_bonus.size()]}


@warning_ignore("incompatible_ternary")
func _maybe_infer_object_type() -> void:
	# If the instance already set a non-default type, respect it.
	if object_type != "Bonus":
		return
	var path: String = get_scene_file_path().to_lower()
	if path == "":
		return
	if path.find("enemy") != -1:
		object_type = "Enemy"
	elif path.find("golden") != -1:
		object_type = "GOLDEN"
	elif path.find("bonus") != -1:
		object_type = "Bonus"


@warning_ignore("incompatible_ternary")
func _start_pulse() -> void:
	var target: CanvasItem = _label
	if target == null:
		target = _sprite
	if target == null:
		return
	if _pulse_tween and _pulse_tween.is_running():
		_pulse_tween.kill()
	_pulse_tween = create_tween()
	_pulse_tween.set_parallel(true)
	var base_scale: Vector2 = _base_label_scale
	if _label == null:
		base_scale = _base_sprite_scale
	_pulse_tween.tween_property(target, "scale", base_scale * 1.08, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(target, "modulate", target.modulate * Color(1.1, 1.1, 1.1, 1.0), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(target, "scale", base_scale, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(target, "modulate", target.modulate, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.set_loops()


@warning_ignore("incompatible_ternary")
func _start_glitch_flicker() -> void:
	var target: CanvasItem = _label
	if target == null:
		target = _sprite
	if target == null:
		return
	if _glitch_tween and _glitch_tween.is_running():
		_glitch_tween.kill()
	_glitch_tween = create_tween()
	_glitch_tween.set_loops()
	_glitch_tween.tween_property(target, "modulate:a", 0.55, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_glitch_tween.tween_property(target, "modulate:a", 1.0, 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_glitch_tween.tween_callback(Callable(self, "_random_jitter"))


func _random_jitter() -> void:
	if _label:
		_label.rotation = randf_range(-0.04, 0.04)
		_label.position = _label_base_position + Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))
	if _sprite:
		_sprite.rotation = randf_range(-0.02, 0.02)
		_sprite.position = _sprite_base_position + Vector2(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5))
