extends Area2D
class_name Player

"""How fast the paddle moves horizontally (pixels/sec)."""
@export var speed: float = 550.0

"""Horizontal padding to keep the paddle on-screen."""
@export var screen_padding: float = 64.0

var _enabled: bool = true
@onready var _events: Node = get_node("/root/Events")


func _ready() -> void:
	# Listen for game over to stop player control.
	_events.connect("game_over", _on_game_over)
	# Use area_entered to detect collisions with falling objects.
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if not _enabled:
		return

	var axis: float = Input.get_axis("move_left", "move_right")
	global_position.x += axis * speed * delta

	var viewport_width: float = get_viewport_rect().size.x
	# clamp() keeps X within [min, max] to prevent leaving the visible play area.
	global_position.x = clamp(global_position.x, screen_padding, viewport_width - screen_padding)


## Exists to forward collision results into the shared event bus.
func handle_collision(falling_object: FallingObject) -> void:
	if falling_object.damage_value > 0:
		Events.request_take_damage.emit(falling_object.damage_value)
	if falling_object.score_value > 0:
		Events.request_add_score.emit(falling_object.score_value)


func _on_area_entered(area: Area2D) -> void:
	if area is FallingObject:
		handle_collision(area as FallingObject)
		area.queue_free()


func _on_game_over() -> void:
	_enabled = false
