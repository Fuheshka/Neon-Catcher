extends Area2D
class_name FallingObject

@export_enum("Bonus", "Enemy", "Powerup") var object_type: String = "Bonus"

"""Downward speed in pixels per second."""
@export var falling_speed: float = 260.0

"""Rotation speed in degrees per second (positive = clockwise)."""
@export var rotation_speed: float = 45.0

"""How many points this object grants when caught."""
@export var score_value: int = 10

"""How much damage this object deals when hit (positive value)."""
@export var damage_value: int = 0

@onready var _screen_notifier: VisibleOnScreenNotifier2D = get_node_or_null("VisibleOnScreenNotifier2D") as VisibleOnScreenNotifier2D
@onready var _game_manager: GameManager = get_node_or_null("/root/GameManager") as GameManager
@onready var _sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
var _base_sprite_scale: Vector2 = Vector2.ONE

var _active: bool = true


func _ready() -> void:
	if _sprite != null:
		_base_sprite_scale = _sprite.scale
		_maybe_infer_object_type()
		_apply_visual_style()
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
	queue_free()


func _get_difficulty_multiplier() -> float:
	if is_instance_valid(_game_manager):
		return max(0.1, _game_manager.current_difficulty_factor)
	return 1.0


func _apply_visual_style() -> void:
	if _sprite == null:
		return
	var style: Dictionary = _get_style_for_type(object_type)
	_sprite.scale = _base_sprite_scale * (style.get("scale", Vector2.ONE))
	var current_color: Color = _sprite.modulate
	var target_color: Color = style.get("color", current_color)
	# Preserve custom-tinted bonuses (e.g., golden bonus) by only overriding
	# color when the current modulate is effectively white.
	if object_type != "Bonus" or current_color.is_equal_approx(Color.WHITE):
		_sprite.modulate = target_color


func _get_style_for_type(type_name: String) -> Dictionary:
	match type_name:
		"Enemy":
			return {"scale": Vector2(1.0, 1.0), "color": Color(1.0, 0.35, 0.35)}
		"Powerup":
			return {"scale": Vector2(1.05, 1.05), "color": Color(1.0, 0.9, 0.2)}
		_:
			return {"scale": Vector2(0.9, 0.9), "color": Color(0.8, 1.0, 0.35)}


func _maybe_infer_object_type() -> void:
	# If the instance already set a non-default type, respect it.
	if object_type != "Bonus":
		return
	var path: String = get_scene_file_path().to_lower()
	if path == "":
		return
	if path.find("enemy") != -1:
		object_type = "Enemy"
	elif path.find("power") != -1:
		object_type = "Powerup"
	elif path.find("bonus") != -1:
		object_type = "Bonus"
