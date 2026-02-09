extends Node2D
class_name Spawner

"""Scenes that can be spawned; each should use FallingObject with configured exports."""
@export var spawnable_scenes: Array[PackedScene] = []

"""Seconds between spawns."""
@export var spawn_interval: float = 1.0

"""Horizontal padding from viewport edges for spawn positions."""
@export var spawn_padding: float = 32.0

var _spawn_timer: Timer
var _difficulty_timer: Timer
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _active: bool = true
@onready var _events: Node = get_node("/root/Events")


func _ready() -> void:
	_rng.randomize()

	_spawn_timer = Timer.new()
	_spawn_timer.one_shot = false
	_spawn_timer.wait_time = spawn_interval
	add_child(_spawn_timer)
	_spawn_timer.timeout.connect(_on_spawn_timeout)
	_spawn_timer.start()

	_difficulty_timer = Timer.new()
	_difficulty_timer.one_shot = false
	_difficulty_timer.wait_time = 10.0
	_difficulty_timer.autostart = true
	add_child(_difficulty_timer)
	_difficulty_timer.timeout.connect(_on_difficulty_timeout)
	_difficulty_timer.start()

	_events.connect("game_over", _on_game_over)


func _on_spawn_timeout() -> void:
	if not _active:
		return
	if spawnable_scenes.is_empty():
		return

	var pick: PackedScene = spawnable_scenes[_rng.randi_range(0, spawnable_scenes.size() - 1)]
	if pick == null:
		return

	var instance: Node2D = pick.instantiate() as Node2D
	if instance == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var min_x: float = spawn_padding
	var max_x: float = viewport_size.x - spawn_padding
	instance.global_position = Vector2(_rng.randf_range(min_x, max_x), global_position.y)

	(get_parent() as Node).add_child(instance)


func _on_difficulty_timeout() -> void:
	if not _active:
		return
	if not is_instance_valid(_spawn_timer):
		return
	_spawn_timer.wait_time = max(0.3, _spawn_timer.wait_time - 0.1)
	print("Difficulty Increased!")


func _on_game_over() -> void:
	_active = false
	if is_instance_valid(_spawn_timer):
		_spawn_timer.stop()
	if is_instance_valid(_difficulty_timer):
		_difficulty_timer.stop()
