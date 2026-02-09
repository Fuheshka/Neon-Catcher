extends Area2D
class_name FallingObject

"""Downward speed in pixels per second."""
@export var falling_speed: float = 260.0

"""Rotation speed in degrees per second (positive = clockwise)."""
@export var rotation_speed: float = 45.0

"""How many points this object grants when caught."""
@export var score_value: int = 10

"""How much damage this object deals when hit (positive value)."""
@export var damage_value: int = 0

@onready var _screen_notifier: VisibleOnScreenNotifier2D = get_node_or_null("VisibleOnScreenNotifier2D") as VisibleOnScreenNotifier2D

var _active: bool = true


func _ready() -> void:
	if _screen_notifier != null:
		# Free the object when it leaves the screen; avoids buildup.
		_screen_notifier.screen_exited.connect(_on_screen_exited)


func _physics_process(delta: float) -> void:
	if not _active:
		return

	global_position.y += falling_speed * delta
	rotation_degrees += rotation_speed * delta

	# Fallback cleanup if notifier is missing.
	if _screen_notifier == null:
		var viewport_height: float = get_viewport_rect().size.y
		if global_position.y > viewport_height + 200.0:
			queue_free()


func _on_screen_exited() -> void:
	queue_free()
